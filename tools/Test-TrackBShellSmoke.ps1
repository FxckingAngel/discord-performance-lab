[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string] $ExecutablePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe'),

    [ValidateRange(1, 60)]
    [int] $StartupTimeoutSeconds = 15
)

$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
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
        $descendantProcesses = @(Get-DescendantProcesses -RootPid $process.Id)

        [pscustomobject]@{
            argument = $scenario.argument
            pid = $observed.Id
            responding = $observed.Responding
            title = $observed.MainWindowTitle
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
        Start-Sleep -Seconds 1
        $remainingDescendants = foreach ($child in $descendantProcesses) {
            $current = Get-CimInstance Win32_Process -Filter "ProcessId=$([int] $child.ProcessId)" -ErrorAction SilentlyContinue
            if ($current -and
                [string] $current.Name -eq [string] $child.Name -and
                [string] $current.CommandLine -eq [string] $child.CommandLine -and
                [string] $current.CreationDate -eq [string] $child.CreationDate) {
                $current
            }
        }
        if ($remainingDescendants.Count -gt 0) {
            throw "Smoke process $($process.Id) left $($remainingDescendants.Count) helper process(es) alive: $((@($remainingDescendants | Select-Object -ExpandProperty ProcessId) -join ', '))."
        }
    }
}

$results
