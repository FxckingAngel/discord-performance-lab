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
    [string] $ProcessName = 'DiscordPTB',

    [switch] $IncludeThreadCounters
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
    $current = if ($RootPid -gt 0) {
        @(Get-CimInstance Win32_Process)
    }
    else {
        @(Get-CimInstance Win32_Process -Filter "Name='$processNamePattern'")
    }
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

function Get-ProcessCounterMaps {
    $maps = @{}
    foreach ($name in $counterPaths.Keys) {
        $maps[$name] = @{}
    }

    $metricToName = @{
        '% Processor Time' = 'cpuPercentOfTotal'
        'ID Process' = 'processId'
        'Working Set - Private' = 'workingSetPrivateBytes'
        'Private Bytes' = 'privateBytes'
        'Page Faults/sec' = 'pageFaultsPerSecond'
        'IO Read Bytes/sec' = 'ioReadBytesPerSecond'
        'IO Write Bytes/sec' = 'ioWriteBytesPerSecond'
        'Thread Count' = 'threads'
    }
    try {
        $result = Get-Counter -Counter @($counterPaths.Values) -MaxSamples 1 -ErrorAction Stop
        foreach ($sample in @($result.CounterSamples)) {
            if ($sample.Path -notmatch '\\Process\(([^)]+)\)\\(.+)$') { continue }
            $instance = $Matches[1].ToLowerInvariant()
            $metricName = $Matches[2]
            $mapName = $metricToName[$metricName]
            if ($mapName) {
                $maps[$mapName][$instance] = [double] $sample.CookedValue
            }
        }
    }
    catch {
        # Counter availability varies by Windows edition and performance policy.
    }
    return $maps
}

function Get-ProcessCounterRows {
    param([int[]] $RootedPids)

    $maps = Get-ProcessCounterMaps
    $idMap = $maps.processId
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
    $memoryByPid = @{}
    try {
        $counters = Get-Counter -Counter @(
            '\GPU Engine(*)\Utilization Percentage',
            '\GPU Process Memory(*)\Dedicated Usage'
        ) -MaxSamples 1 -ErrorAction Stop
        foreach ($sample in @($counters.CounterSamples)) {
            if ($sample.InstanceName -match '(?i)^pid_(\d+)_') {
                $processId = [int] $Matches[1]
                if ($RootedPids -contains $processId -and $sample.Path -match '\\GPU Engine\(') {
                    if (-not $engineByPid.ContainsKey($processId)) { $engineByPid[$processId] = 0.0 }
                    $engineByPid[$processId] += [double] $sample.CookedValue
                }
                elseif ($RootedPids -contains $processId -and $sample.Path -match '\\GPU Process Memory\(') {
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

function Get-ThreadCounterRows {
    param([int[]] $RootedPids)

    $idByInstance = @{}
    $switchesByInstance = @{}
    try {
        $counters = Get-Counter -Counter @(
            '\Thread(*)\ID Process',
            '\Thread(*)\Context Switches/sec'
        ) -MaxSamples 1 -ErrorAction Stop
        foreach ($sample in @($counters.CounterSamples)) {
            $instance = $sample.InstanceName
            if ($sample.Path -match '\\Thread\(' -and $sample.Path -match '\\ID Process$') {
                $idByInstance[$instance] = [int] $sample.CookedValue
            }
            elseif ($sample.Path -match '\\Thread\(' -and $sample.Path -match '\\Context Switches/sec$') {
                $switchesByInstance[$instance] = [double] $sample.CookedValue
            }
        }
    }
    catch {
        # Thread counters are supplementary and vary by Windows policy.
    }

    $byPid = @{}
    foreach ($pair in $idByInstance.GetEnumerator()) {
        $processId = $pair.Value
        if ($RootedPids -notcontains $processId) { continue }
        if (-not $byPid.ContainsKey($processId)) {
            $byPid[$processId] = [pscustomobject]@{ contextSwitchesPerSecond = 0.0; threadCounterInstances = 0 }
        }
        $byPid[$processId].threadCounterInstances++
        if ($switchesByInstance.ContainsKey($pair.Key)) {
            $byPid[$processId].contextSwitchesPerSecond += $switchesByInstance[$pair.Key]
        }
    }

    foreach ($processId in $RootedPids) {
        $value = $byPid[$processId]
        [pscustomobject]@{
            pid = $processId
            contextSwitchesPerSecond = if ($null -ne $value) { [math]::Round($value.contextSwitchesPerSecond, 2) } else { $null }
            threadCounterInstances = if ($null -ne $value) { $value.threadCounterInstances } else { $null }
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
        threads = if ($IncludeThreadCounters) { @(Get-ThreadCounterRows -RootedPids $rootedPids) } else { @() }
        gpu = @(Get-GpuRows -RootedPids $rootedPids)
    })
    if ($index -lt $sampleCount) {
        $nextSampleAt = $startedAt.AddSeconds(($index + 1) * $IntervalSeconds)
        $remainingMilliseconds = [math]::Floor(($nextSampleAt - [DateTime]::UtcNow).TotalMilliseconds)
        if ($remainingMilliseconds -gt 0) {
            Start-Sleep -Milliseconds $remainingMilliseconds
        }
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
    threadCountersEnabled = [bool] $IncludeThreadCounters
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
