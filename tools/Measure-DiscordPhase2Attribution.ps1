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
    [string] $Scenario = 'phase2-attribution',

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath,

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'DiscordPTB'
)

Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class TrackBPhase2Window {
    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
}
'@

function Get-WindowState {
    param([int] $TreeRootPid)

    $process = Get-Process -Id $TreeRootPid -ErrorAction SilentlyContinue
    if (-not $process) {
        return [pscustomobject]@{ available = $false; reason = 'root-exited' }
    }
    $handle = [IntPtr] $process.MainWindowHandle
    [pscustomobject]@{
        available = $handle -ne [IntPtr]::Zero
        handle = if ($handle -ne [IntPtr]::Zero) { $handle.ToInt64() } else { $null }
        visible = if ($handle -ne [IntPtr]::Zero) { [TrackBPhase2Window]::IsWindowVisible($handle) } else { $false }
        minimized = if ($handle -ne [IntPtr]::Zero) { [TrackBPhase2Window]::IsIconic($handle) } else { $false }
        title = [string] $process.MainWindowTitle
        responding = [bool] $process.Responding
    }
}

function Get-DisplayState {
    $controllers = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | ForEach-Object {
        [pscustomobject]@{
            name = [string] $_.Name
            currentRefreshRate = if ($null -ne $_.CurrentRefreshRate) { [int] $_.CurrentRefreshRate } else { $null }
            currentHorizontalResolution = if ($null -ne $_.CurrentHorizontalResolution) { [int] $_.CurrentHorizontalResolution } else { $null }
            currentVerticalResolution = if ($null -ne $_.CurrentVerticalResolution) { [int] $_.CurrentVerticalResolution } else { $null }
        }
    })
    $active = @($controllers | Where-Object { $_.currentRefreshRate -gt 0 } | Select-Object -First 1)[0]
    [pscustomobject]@{
        displayRefreshRate = if ($active) { $active.currentRefreshRate } else { $null }
        displayWidth = if ($active) { $active.currentHorizontalResolution } else { $null }
        displayHeight = if ($active) { $active.currentVerticalResolution } else { $null }
        adapters = $controllers
    }
}

$logicalProcessorCount = [Environment]::ProcessorCount
$processes = @(Get-CimInstance Win32_Process)
if (-not @($processes | Where-Object { [int] $_.ProcessId -eq $RootPid })) {
    throw "Root PID $RootPid was not found among $ProcessName processes."
}

function Test-CurrentParentProcess {
    param([object] $Parent, [object] $Child)

    if ([int] $Child.ParentProcessId -ne [int] $Parent.ProcessId) { return $false }
    try {
        $parentStart = [System.Management.ManagementDateTimeConverter]::ToDateTime([string] $Parent.CreationDate).ToUniversalTime()
        $childStart = [System.Management.ManagementDateTimeConverter]::ToDateTime([string] $Child.CreationDate).ToUniversalTime()
        return $childStart -ge $parentStart
    }
    catch {
        return $true
    }
}

function Get-Role {
    param([object] $Process, [int] $TreeRootPid)

    if ([int] $Process.ProcessId -eq $TreeRootPid) { return 'native-shell' }
    $role = 'browser'
    if ($Process.CommandLine -match '--type=([^\s]+)') {
        $role = $Matches[1]
    }
    if ($Process.CommandLine -match '--utility-sub-type=([^\s]+)') {
        $role = "$role/$($Matches[1])"
    }
    return $role
}

function Get-RootedProcesses {
    $current = @(Get-CimInstance Win32_Process)
    $root = @($current | Where-Object { [int] $_.ProcessId -eq $RootPid })
    if ($root.Count -eq 0) {
        return @()
    }
    $treePids = [System.Collections.Generic.HashSet[int]]::new()
    $pending = [System.Collections.Generic.Queue[int]]::new()
    [void] $treePids.Add($RootPid)
    $pending.Enqueue($RootPid)
    while ($pending.Count -gt 0) {
        $parentPid = $pending.Dequeue()
        $parent = @($current | Where-Object { [int] $_.ProcessId -eq $parentPid } | Select-Object -First 1)
        foreach ($child in @($current | Where-Object { [int] $_.ParentProcessId -eq $parentPid })) {
            if ($parent.Count -gt 0 -and -not (Test-CurrentParentProcess -Parent $parent[0] -Child $child)) { continue }
            $childPid = [int] $child.ProcessId
            if ($treePids.Add($childPid)) {
                $pending.Enqueue($childPid)
            }
        }
    }
    return @($current | Where-Object { $treePids.Contains([int] $_.ProcessId) })
}

function Get-PerfByPid {
    $byPid = @{}
    try {
        foreach ($row in @(Get-CimInstance Win32_PerfFormattedData_PerfProc_Process)) {
            $perfPid = [int] $row.IDProcess
            if ($perfPid -gt 0) {
                $byPid[$perfPid] = $row
            }
        }
    }
    catch {
        # Process counters are supplementary; the .NET process counters remain available.
    }
    return $byPid
}

$previousCpu = @{}
$samples = [System.Collections.Generic.List[object]]::new()
$displayState = Get-DisplayState
$startedAt = [DateTime]::UtcNow
$sampleCount = [math]::Max(1, [math]::Floor($DurationSeconds / $IntervalSeconds))
for ($index = 0; $index -le $sampleCount; $index++) {
    $timestamp = [DateTime]::UtcNow
    $rooted = @(Get-RootedProcesses)
    if ($rooted.Count -eq 0) {
        break
    }
    $perfByPid = Get-PerfByPid
    $sampleProcesses = foreach ($cimProcess in $rooted) {
        $processId = [int] $cimProcess.ProcessId
        try {
            $process = Get-Process -Id $processId -ErrorAction Stop
            $process.Refresh()
            $cpuSeconds = $process.TotalProcessorTime.TotalSeconds
            $cpuPercent = $null
            if ($previousCpu.ContainsKey($processId)) {
                $elapsed = ($timestamp - $previousCpu[$processId].timestamp).TotalSeconds
                if ($elapsed -gt 0) {
                    $cpuPercent = [math]::Round((($cpuSeconds - $previousCpu[$processId].cpuSeconds) / $elapsed / $logicalProcessorCount) * 100, 3)
                }
            }
            $previousCpu[$processId] = [pscustomobject]@{ timestamp = $timestamp; cpuSeconds = $cpuSeconds }
            $perf = $perfByPid[$processId]
            $workingSetPrivateBytes = if ($perf) { [double] $perf.WorkingSetPrivate } else { $null }
            $workingSetBytes = [double] $process.WorkingSet64
            [pscustomobject]@{
                pid = $processId
                parentPid = [int] $cimProcess.ParentProcessId
                role = Get-Role -Process $cimProcess -TreeRootPid $RootPid
                lifetimeSeconds = [math]::Round(($timestamp - $process.StartTime.ToUniversalTime()).TotalSeconds, 3)
                workingSetMiB = [math]::Round($workingSetBytes / 1MB, 2)
                privateWorkingSetMiB = if ($null -ne $workingSetPrivateBytes) { [math]::Round($workingSetPrivateBytes / 1MB, 2) } else { $null }
                workingSetShareableMiB = if ($null -ne $workingSetPrivateBytes) { [math]::Round([math]::Max(0, $workingSetBytes - $workingSetPrivateBytes) / 1MB, 2) } else { $null }
                privateMemoryMiB = [math]::Round($process.PrivateMemorySize64 / 1MB, 2)
                pagedMemoryMiB = [math]::Round($process.PagedMemorySize64 / 1MB, 2)
                handles = $process.HandleCount
                threads = $process.Threads.Count
                cpuPercentOfTotal = $cpuPercent
                pageFaultsPerSecond = if ($perf) { [math]::Round([double] $perf.PageFaultsPerSec, 2) } else { $null }
                ioReadBytesPerSecond = if ($perf) { [math]::Round([double] $perf.IOReadBytesPerSec, 2) } else { $null }
                ioWriteBytesPerSecond = if ($perf) { [math]::Round([double] $perf.IOWriteBytesPerSec, 2) } else { $null }
            }
        }
        catch {
            [pscustomobject]@{
                pid = $processId
                parentPid = [int] $cimProcess.ParentProcessId
                role = Get-Role -Process $cimProcess -TreeRootPid $RootPid
                status = 'unavailable'
                errorCategory = $_.Exception.GetType().Name
            }
        }
    }
    $samples.Add([pscustomobject]@{
        timestamp = $timestamp
        processCount = @($sampleProcesses).Count
        windowState = Get-WindowState -TreeRootPid $RootPid
        processes = @($sampleProcesses)
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
    logicalProcessorCount = $logicalProcessorCount
    environment = [pscustomobject]@{
        displayRefreshRate = $displayState.displayRefreshRate
        displayWidth = $displayState.displayWidth
        displayHeight = $displayState.displayHeight
        adapters = $displayState.adapters
    }
    startedAt = $startedAt
    endedAt = [DateTime]::UtcNow
    durationSeconds = ([DateTime]::UtcNow - $startedAt).TotalSeconds
    sampleIntervalSeconds = $IntervalSeconds
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
