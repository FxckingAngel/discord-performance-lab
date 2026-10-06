[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $RootPid,

    [ValidateRange(5, 3600)]
    [int] $DurationSeconds = 600,

    [ValidateRange(1, 60)]
    [int] $IntervalSeconds = 5,

    [ValidateNotNullOrEmpty()]
    [string] $Scenario = 'phase2-windows-counters',

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath,

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'DiscordPTB'
)

$processNamePattern = "$ProcessName.exe"
$counterPaths = @{
    cpuPercentOfTotal = '\Process(*)\% Processor Time'
    processId = '\Process(*)\ID Process'
    workingSetPrivateBytes = '\Process(*)\Working Set - Private'
    privateBytes = '\Process(*)\Private Bytes'
    pageFaultsPerSecond = '\Process(*)\Page Faults/sec'
    ioReadBytesPerSecond = '\Process(*)\IO Read Bytes/sec'
    ioWriteBytesPerSecond = '\Process(*)\IO Write Bytes/sec'
    threads = '\Process(*)\Thread Count'
}

function Get-RootedPids {
    $current = @(Get-CimInstance Win32_Process -Filter "Name='$processNamePattern'")
    if (-not @($current | Where-Object { [int] $_.ProcessId -eq $RootPid })) {
        return @()
    }
    $rooted = [System.Collections.Generic.HashSet[int]]::new()
    $pending = [System.Collections.Generic.Queue[int]]::new()
    [void] $rooted.Add($RootPid)
    $pending.Enqueue($RootPid)
    while ($pending.Count -gt 0) {
        $parentPid = $pending.Dequeue()
        foreach ($child in @($current | Where-Object { [int] $_.ParentProcessId -eq $parentPid })) {
            $childPid = [int] $child.ProcessId
            if ($rooted.Add($childPid)) {
                $pending.Enqueue($childPid)
            }
        }
    }
    return @($rooted)
}

function Get-CounterMap {
    param([string] $Path)

    $map = @{}
    try {
        $result = Get-Counter -Counter $Path -MaxSamples 1 -ErrorAction Stop
        foreach ($sample in @($result.CounterSamples)) {
            $key = $sample.InstanceName.ToLowerInvariant()
            if ($sample.Path -match '\\Process\(([^)]+)\)\\') {
                $key = $Matches[1].ToLowerInvariant()
            }
            $map[$key] = [double] $sample.CookedValue
        }
    }
    catch {
        # Counter availability varies by Windows edition and performance policy.
    }
    return $map
}

function Get-ProcessCounterRows {
    param([int[]] $RootedPids)

    $idMap = Get-CounterMap -Path $counterPaths.processId
    $maps = @{}
    foreach ($name in @($counterPaths.Keys | Where-Object { $_ -ne 'processId' })) {
        $maps[$name] = Get-CounterMap -Path $counterPaths[$name]
    }
    $rows = [System.Collections.Generic.List[object]]::new()
    foreach ($pair in $idMap.GetEnumerator()) {
        $processId = [int] $pair.Value
        if ($RootedPids -notcontains $processId) { continue }
        $instance = $pair.Key
        $rows.Add([pscustomobject]@{
            pid = $processId
            instance = $instance
            cpuPercentOfTotal = if ($maps.cpuPercentOfTotal.ContainsKey($instance)) { [math]::Round($maps.cpuPercentOfTotal[$instance] / [Environment]::ProcessorCount, 3) } else { $null }
            workingSetPrivateBytes = if ($maps.workingSetPrivateBytes.ContainsKey($instance)) { [math]::Round($maps.workingSetPrivateBytes[$instance], 0) } else { $null }
            privateBytes = if ($maps.privateBytes.ContainsKey($instance)) { [math]::Round($maps.privateBytes[$instance], 0) } else { $null }
            pageFaultsPerSecond = if ($maps.pageFaultsPerSecond.ContainsKey($instance)) { [math]::Round($maps.pageFaultsPerSecond[$instance], 2) } else { $null }
            ioReadBytesPerSecond = if ($maps.ioReadBytesPerSecond.ContainsKey($instance)) { [math]::Round($maps.ioReadBytesPerSecond[$instance], 2) } else { $null }
            ioWriteBytesPerSecond = if ($maps.ioWriteBytesPerSecond.ContainsKey($instance)) { [math]::Round($maps.ioWriteBytesPerSecond[$instance], 2) } else { $null }
            threads = if ($maps.threads.ContainsKey($instance)) { [math]::Round($maps.threads[$instance], 0) } else { $null }
        })
    }
    return @($rows)
}

function Get-GpuRows {
    param([int[]] $RootedPids)

    $engineByPid = @{}
    try {
        $engines = Get-Counter -Counter '\GPU Engine(*)\Utilization Percentage' -MaxSamples 1 -ErrorAction Stop
        foreach ($sample in @($engines.CounterSamples)) {
            if ($sample.InstanceName -match '(?i)^pid_(\d+)_') {
                $processId = [int] $Matches[1]
                if ($RootedPids -contains $processId) {
                    if (-not $engineByPid.ContainsKey($processId)) { $engineByPid[$processId] = 0.0 }
                    $engineByPid[$processId] += [double] $sample.CookedValue
                }
            }
        }
    }
    catch {
        # GPU engine counters can be unavailable on older drivers or remote sessions.
    }
    $memoryByPid = @{}
    try {
        $memory = Get-Counter -Counter '\GPU Process Memory(*)\Dedicated Usage' -MaxSamples 1 -ErrorAction Stop
        foreach ($sample in @($memory.CounterSamples)) {
            if ($sample.InstanceName -match '(?i)^pid_(\d+)_') {
                $processId = [int] $Matches[1]
                if ($RootedPids -contains $processId) {
                    $memoryByPid[$processId] = [double] $sample.CookedValue
                }
            }
        }
    }
    catch {
        # GPU memory counters are supplementary.
    }
    foreach ($processId in $RootedPids) {
        [pscustomobject]@{
            pid = $processId
            gpuEngineUtilizationPercent = if ($engineByPid.ContainsKey($processId)) { [math]::Round($engineByPid[$processId], 3) } else { $null }
            gpuDedicatedBytes = if ($memoryByPid.ContainsKey($processId)) { [math]::Round($memoryByPid[$processId], 0) } else { $null }
        }
    }
}

$initialPids = @(Get-RootedPids)
if ($initialPids.Count -eq 0) {
    throw "Root PID $RootPid was not found among $ProcessName processes."
}

$samples = [System.Collections.Generic.List[object]]::new()
$startedAt = [DateTime]::UtcNow
$sampleCount = [math]::Max(1, [math]::Floor($DurationSeconds / $IntervalSeconds))
for ($index = 0; $index -le $sampleCount; $index++) {
    $timestamp = [DateTime]::UtcNow
    $rootedPids = @(Get-RootedPids)
    if ($rootedPids.Count -eq 0) { break }
    $samples.Add([pscustomobject]@{
        timestamp = $timestamp
        processCount = $rootedPids.Count
        processes = @(Get-ProcessCounterRows -RootedPids $rootedPids)
        gpu = @(Get-GpuRows -RootedPids $rootedPids)
    })
    if ($index -lt $sampleCount) {
        Start-Sleep -Seconds $IntervalSeconds
    }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    build = $ProcessName
    scenario = $Scenario
    rootPid = $RootPid
    logicalProcessorCount = [Environment]::ProcessorCount
    startedAt = $startedAt
    endedAt = [DateTime]::UtcNow
    durationSeconds = ([DateTime]::UtcNow - $startedAt).TotalSeconds
    sampleIntervalSeconds = $IntervalSeconds
    counterPaths = $counterPaths
    samples = @($samples)
}
$parent = Split-Path -Parent $OutputPath
if ($parent) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
[pscustomobject]@{
    scenario = $Scenario
    rootPid = $RootPid
    sampleCount = @($samples).Count
    durationSeconds = [math]::Round($result.durationSeconds, 3)
    outputPath = $OutputPath
}
