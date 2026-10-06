[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ProcessName,

    [ValidateRange(0, [int]::MaxValue)]
    [int] $RootPid = 0,

    [ValidateRange(5, 86400)]
    [int] $DurationSeconds = 30,

    [ValidateRange(1, 60)]
    [int] $IntervalSeconds = 5,

    [ValidateNotNullOrEmpty()]
    [string] $Scenario = 'idle-observation',

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = (Join-Path (Get-Location) 'benchmark.json')
)

function Get-DiscordProcessSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [int] $TreeRootPid
    )

    $processes = if ($TreeRootPid -gt 0) {
        @(Get-CimInstance Win32_Process)
    }
    else {
        @(Get-CimInstance Win32_Process -Filter "Name='$Name.exe'")
    }
    if ($TreeRootPid -gt 0) {
        $treePids = [System.Collections.Generic.HashSet[int]]::new()
        $pending = [System.Collections.Generic.Queue[int]]::new()
        [void] $treePids.Add($TreeRootPid)
        $pending.Enqueue($TreeRootPid)
        while ($pending.Count -gt 0) {
            $parentPid = $pending.Dequeue()
            foreach ($child in @($processes | Where-Object { [int] $_.ParentProcessId -eq $parentPid })) {
                $childPid = [int] $child.ProcessId
                if ($treePids.Add($childPid)) {
                    $pending.Enqueue($childPid)
                }
            }
        }
        $processes = @($processes | Where-Object { $treePids.Contains([int] $_.ProcessId) })
    }
    $perfByPid = @{}
    try {
        foreach ($perfRow in @(Get-CimInstance Win32_PerfFormattedData_PerfProc_Process)) {
            $perfPid = [int] $perfRow.IDProcess
            if ($perfPid -gt 0) {
                $perfByPid[$perfPid] = $perfRow
            }
        }
    }
    catch {
        # Performance counters are supplementary; process APIs remain available.
    }
    $rows = foreach ($process in $processes) {
        try {
            $current = Get-Process -Id $process.ProcessId -ErrorAction Stop
            $perf = $perfByPid[[int] $process.ProcessId]
            $workingSetBytes = [double] $current.WorkingSet64
            $workingSetPrivateBytes = if ($perf) { [double] $perf.WorkingSetPrivate } else { $null }
            $privateBytes = if ($perf) { [double] $perf.PrivateBytes } else { [double] $current.PrivateMemorySize64 }
            $role = if ($TreeRootPid -gt 0 -and [int] $process.ProcessId -eq $TreeRootPid) {
                'native-shell'
            }
            else {
                'browser'
            }
            if ($role -ne 'native-shell' -and $process.CommandLine -match '--type=([^\s]+)') {
                $role = $Matches[1]
            }
            if ($role -ne 'native-shell' -and $process.CommandLine -match '--utility-sub-type=([^\s]+)') {
                $role = "$role/$($Matches[1])"
            }
            [pscustomobject] @{
                pid             = $current.Id
                parentPid       = [int] $process.ParentProcessId
                creationTime    = $current.StartTime.ToUniversalTime().ToString('o')
                name            = $current.ProcessName
                role            = $role
                path            = $current.Path
                cpuSeconds      = $current.CPU
                workingSetBytes = $workingSetBytes
                workingSetPrivateBytes = $workingSetPrivateBytes
                workingSetShareableBytes = if ($null -ne $workingSetPrivateBytes) { [math]::Max(0, $workingSetBytes - $workingSetPrivateBytes) } else { $null }
                privateBytes    = $privateBytes
                commitBytes     = $privateBytes
                handles         = $current.HandleCount
                threads         = $current.Threads.Count
            }
        }
        catch [System.ArgumentException] {
            # A child can exit between the process query and the sample.
        }
    }

    [pscustomobject] @{
        processCount    = @($rows).Count
        workingSetBytes = [double] (($rows | Measure-Object workingSetBytes -Sum).Sum)
        workingSetPrivateBytes = [double] (($rows | Measure-Object workingSetPrivateBytes -Sum).Sum)
        workingSetShareableBytes = [double] (($rows | Measure-Object workingSetShareableBytes -Sum).Sum)
        workingSetShareableMethod = 'derived-total-minus-private; no native shared-working-set counter exposed'
        privateBytes    = [double] (($rows | Measure-Object privateBytes -Sum).Sum)
        commitBytes     = [double] (($rows | Measure-Object commitBytes -Sum).Sum)
        cpuSeconds      = [double] (($rows | Measure-Object cpuSeconds -Sum).Sum)
        processes       = @($rows)
    }
}

function Invoke-DiscordBenchmark {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string] $Name,
        [Parameter(Mandatory = $true)] [int] $Duration,
        [Parameter(Mandatory = $true)] [int] $Interval,
        [Parameter(Mandatory = $true)] [string] $ScenarioName,
        [int] $TreeRootPid
    )

    $samples = [System.Collections.Generic.List[object]]::new()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    do {
        $snapshot = Get-DiscordProcessSnapshot -Name $Name -TreeRootPid $TreeRootPid
        $samples.Add([pscustomobject] @{
            timestamp        = (Get-Date).ToUniversalTime().ToString('o')
            processCount     = $snapshot.processCount
            workingSetBytes  = $snapshot.workingSetBytes
            workingSetPrivateBytes = $snapshot.workingSetPrivateBytes
            workingSetShareableBytes = $snapshot.workingSetShareableBytes
            workingSetShareableMethod = $snapshot.workingSetShareableMethod
            privateBytes     = $snapshot.privateBytes
            commitBytes      = $snapshot.commitBytes
            cpuSeconds       = $snapshot.cpuSeconds
            processes        = $snapshot.processes
        })

        if ($stopwatch.Elapsed.TotalSeconds -lt $Duration) {
            Start-Sleep -Seconds $Interval
        }
    } while ($stopwatch.Elapsed.TotalSeconds -lt $Duration)

    # Convert cumulative process CPU time into interval CPU percentage after sampling.
    for ($index = 1; $index -lt $samples.Count; $index++) {
        $previous = $samples[$index - 1]
        $current = $samples[$index]
        $wallSeconds = ([datetime] $current.timestamp - [datetime] $previous.timestamp).TotalSeconds
        $cpuPercentOfTotal = if ($wallSeconds -gt 0) {
            (($current.cpuSeconds - $previous.cpuSeconds) / $wallSeconds) * 100 / [Environment]::ProcessorCount
        }
        else {
            $null
        }
        $current | Add-Member -NotePropertyName cpuPercentOfTotal -NotePropertyValue $cpuPercentOfTotal -Force
    }
    $samples[0] | Add-Member -NotePropertyName cpuPercentOfTotal -NotePropertyValue $null -Force

    [pscustomobject] @{
        schemaVersion          = 2
        build                  = $Name
        scenario               = $ScenarioName
        rootPid                = if ($TreeRootPid -gt 0) { $TreeRootPid } else { $null }
        durationSeconds        = [math]::Round($stopwatch.Elapsed.TotalSeconds, 3)
        sampleIntervalSeconds  = $Interval
        startedAt               = $samples[0].timestamp
        endedAt                 = $samples[$samples.Count - 1].timestamp
        samples                 = @($samples)
    }
}

$result = Invoke-DiscordBenchmark -Name $ProcessName -Duration $DurationSeconds -Interval $IntervalSeconds -ScenarioName $Scenario -TreeRootPid $RootPid
$parent = Split-Path -Parent $OutputPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8

$result | Select-Object build, scenario, durationSeconds, sampleIntervalSeconds, @{Name = 'sampleCount'; Expression = { $_.samples.Count }}, @{Name = 'firstWorkingSetMiB'; Expression = { [math]::Round($_.samples[0].workingSetBytes / 1MB, 1) }}, @{Name = 'lastWorkingSetMiB'; Expression = { [math]::Round($_.samples[-1].workingSetBytes / 1MB, 1) }}, @{Name = 'firstPrivateMiB'; Expression = { [math]::Round($_.samples[0].privateBytes / 1MB, 1) }}, @{Name = 'lastPrivateMiB'; Expression = { [math]::Round($_.samples[-1].privateBytes / 1MB, 1) }} | Format-List
Write-Output "raw=$OutputPath"
