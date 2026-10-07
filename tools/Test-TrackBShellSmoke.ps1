[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string] $ExecutablePath,

    [ValidateRange(1, 60)]
    [int] $StartupTimeoutSeconds = 15,

    [switch] $SkipNormalSingleInstance
)

$toolRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
    $ExecutablePath = Join-Path (Split-Path -Parent $toolRoot) 'track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe'
}

$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class TrackBShellSmokeWindow {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);
}
'@
$allProcesses = @()
function Get-DescendantProcesses {
    param([int] $RootPid)

    $script:allProcesses = @(Get-CimInstance Win32_Process)
    $descendants = [System.Collections.Generic.HashSet[int]]::new()
    $pending = [System.Collections.Generic.Queue[int]]::new()
    $pending.Enqueue($RootPid)
    while ($pending.Count -gt 0) {
        $parentPid = $pending.Dequeue()
        foreach ($child in @($script:allProcesses | Where-Object { [int] $_.ParentProcessId -eq $parentPid })) {
            $childPid = [int] $child.ProcessId
            if ($descendants.Add($childPid)) {
                $pending.Enqueue($childPid)
            }
        }
    }
    return @($script:allProcesses | Where-Object { $descendants.Contains([int] $_.ProcessId) })
}

$scenarios = @(
    [pscustomobject]@{ argument = '--diagnostic-blank'; expectedTitle = 'Runtime Baseline' },
    [pscustomobject]@{ argument = '--diagnostic-capability-events'; expectedTitle = 'Capability Events Probe' }
)
$processInfoPath = Join-Path $env:LOCALAPPDATA 'KoroneDiscordShell/Diagnostics/webview-process-info.json'
$results = foreach ($scenario in $scenarios) {
    $process = Start-Process -FilePath $resolvedExecutable -ArgumentList $scenario.argument -PassThru
    try {
        $deadline = [DateTime]::UtcNow.AddSeconds($StartupTimeoutSeconds)
        $observed = $null
        do {
            Start-Sleep -Milliseconds 250
            $observed = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
            if ($observed -and $observed.MainWindowHandle -ne [IntPtr]::Zero -and $observed.Responding) {
                break
            }
        } while ([DateTime]::UtcNow -lt $deadline)

        if (-not $observed) { throw "Process exited before the smoke check for $($scenario.argument)." }
        if (-not $observed.Responding) { throw "Process was not responding for $($scenario.argument)." }
        if ($observed.MainWindowTitle -notmatch [regex]::Escape($scenario.expectedTitle)) {
            throw "Unexpected window title '$($observed.MainWindowTitle)' for $($scenario.argument)."
        }
        $processInfo = $null
        $processInfoDeadline = [DateTime]::UtcNow.AddSeconds(5)
        do {
            if (Test-Path -LiteralPath $processInfoPath -PathType Leaf) {
                try {
                    $candidate = Get-Content -LiteralPath $processInfoPath -Raw | ConvertFrom-Json
                    if (@($candidate.processes | Where-Object { $_.kind -and $null -ne $_.activeFrameCount }).Count -gt 0) {
                        $processInfo = $candidate
                        break
                    }
                }
                catch {
                    # The diagnostic snapshot may still be replacing the file.
                }
            }
            Start-Sleep -Milliseconds 100
        } while ([DateTime]::UtcNow -lt $processInfoDeadline)
        if (-not $processInfo) { throw "WebView2 process/frame diagnostic was not captured for $($scenario.argument)." }
        $descendantProcesses = @(Get-DescendantProcesses -RootPid $process.Id)

        [pscustomobject]@{
            argument = $scenario.argument
            pid = $observed.Id
            responding = $observed.Responding
            title = $observed.MainWindowTitle
            webViewProcessCount = @($processInfo.processes).Count
            webViewFrameCountFieldsPresent = $true
            descendantsBeforeClose = $descendantProcesses.Count
            passed = $true
        }
    }
    finally {
        if (Get-Process -Id $process.Id -ErrorAction SilentlyContinue) {
            [void] $process.CloseMainWindow()
            $process.WaitForExit(5000)
        }
        if (Get-Process -Id $process.Id -ErrorAction SilentlyContinue) {
            throw "Smoke process $($process.Id) did not exit after its normal close action."
        }
        $shutdownDeadline = [DateTime]::UtcNow.AddSeconds(30)
        do {
            $remainingDescendants = @(
                foreach ($child in $descendantProcesses) {
                    $running = Get-Process -Id ([int] $child.ProcessId) -ErrorAction SilentlyContinue
                    if (-not $running) { continue }
                    $current = Get-CimInstance Win32_Process -Filter "ProcessId=$([int] $child.ProcessId)" -ErrorAction SilentlyContinue
                    if ($current -and
                        [string] $current.Name -eq [string] $child.Name -and
                        [string] $current.CommandLine -eq [string] $child.CommandLine -and
                        [string] $current.CreationDate -eq [string] $child.CreationDate) {
                        $currentParent = Get-CimInstance Win32_Process -Filter "ProcessId=$([int] $current.ParentProcessId)" -ErrorAction SilentlyContinue
                        if ([int] $current.ParentProcessId -ne [int] $process.Id -and -not $currentParent) { continue }
                        $current
                    }
                }
            )
            if ($remainingDescendants.Count -eq 0) { break }
            Start-Sleep -Milliseconds 250
        } while ([DateTime]::UtcNow -lt $shutdownDeadline)
        if ($remainingDescendants.Count -gt 0) {
            throw "Smoke process $($process.Id) left $($remainingDescendants.Count) helper process(es) alive: $((@($remainingDescendants | Select-Object -ExpandProperty ProcessId) -join ', '))."
        }
    }
}

$normalRoots = @(Get-CimInstance Win32_Process | Where-Object {
    $_.Name -eq 'KoroneDiscordShell.exe' -and
    $_.ExecutablePath -eq $resolvedExecutable -and
    ([string]::IsNullOrWhiteSpace([string] $_.CommandLine) -or [string] $_.CommandLine -notmatch '--diagnostic-')
})
if (-not $SkipNormalSingleInstance -and $normalRoots.Count -gt 0) {
    $paths = @($normalRoots | ForEach-Object { if ($_.ExecutablePath) { $_.ExecutablePath } else { '<path unavailable>' } } | Select-Object -Unique)
    throw "Normal single-instance smoke test requires no existing ordinary shell roots. Existing PIDs: $($normalRoots.ProcessId -join ', '). Paths: $($paths -join '; ')."
}

$otherNormalRoots = @(Get-CimInstance Win32_Process | Where-Object {
    $_.Name -eq 'KoroneDiscordShell.exe' -and
    $_.ExecutablePath -and
    $_.ExecutablePath -ne $resolvedExecutable -and
    ([string]::IsNullOrWhiteSpace([string] $_.CommandLine) -or [string] $_.CommandLine -notmatch '--diagnostic-')
})
$skipNormal = $SkipNormalSingleInstance -or $otherNormalRoots.Count -gt 0
if ($skipNormal) {
    $normalResult = [pscustomobject]@{
        argument = '<normal>'
        skipped = $true
        reason = if ($SkipNormalSingleInstance) { 'explicitly requested' } else { 'another ordinary Track B build is already running' }
        passed = $true
    }
}
else {
    $firstNormal = Start-Process -FilePath $resolvedExecutable -PassThru
    $secondNormal = $null
    try {
    $deadline = [DateTime]::UtcNow.AddSeconds($StartupTimeoutSeconds)
    do {
        Start-Sleep -Milliseconds 250
        $firstObserved = Get-Process -Id $firstNormal.Id -ErrorAction SilentlyContinue
        if ($firstObserved -and $firstObserved.MainWindowHandle -ne [IntPtr]::Zero -and $firstObserved.Responding) {
            break
        }
    } while ([DateTime]::UtcNow -lt $deadline)
    if (-not $firstObserved -or -not $firstObserved.Responding) {
        throw 'Normal shell did not become responsive for the single-instance smoke test.'
    }

    $firstWindowHandle = $firstObserved.MainWindowHandle
    [TrackBShellSmokeWindow]::ShowWindow($firstWindowHandle, 6) | Out-Null
    Start-Sleep -Milliseconds 250
    if (-not [TrackBShellSmokeWindow]::IsIconic($firstWindowHandle)) {
        throw 'Normal shell could not be minimized before the duplicate-launch restore check.'
    }

    $secondNormal = Start-Process -FilePath $resolvedExecutable -PassThru
    if (-not $secondNormal.WaitForExit(5000)) {
        throw "Second normal launch did not exit while the first instance was running. PID $($secondNormal.Id)."
    }
    $verifiedRoots = @(Get-CimInstance Win32_Process | Where-Object {
        $_.Name -eq 'KoroneDiscordShell.exe' -and $_.ExecutablePath -eq $resolvedExecutable
    })
    if ($verifiedRoots.Count -ne 1 -or [int] $verifiedRoots[0].ProcessId -ne $firstNormal.Id) {
        throw "Expected one normal shell root after duplicate launch, found $($verifiedRoots.Count)."
    }
    if ([TrackBShellSmokeWindow]::IsIconic($firstWindowHandle)) {
        throw 'Duplicate normal launch did not restore the existing minimized window.'
    }

    $normalResult = [pscustomobject]@{
        argument = '<normal>'
        pid = $firstNormal.Id
        duplicatePid = $secondNormal.Id
        rootCountAfterDuplicateLaunch = $verifiedRoots.Count
        duplicateExited = $true
        passed = $true
    }
    }
    finally {
        if ($secondNormal -and -not $secondNormal.HasExited) {
            Stop-Process -Id $secondNormal.Id -Force
        }
        if ($firstNormal -and -not $firstNormal.HasExited) {
            [void] $firstNormal.CloseMainWindow()
            $firstNormal.WaitForExit(5000)
        }
        if ($firstNormal -and -not $firstNormal.HasExited) {
            Stop-Process -Id $firstNormal.Id -Force
        }
    }
}

$results
$normalResult
