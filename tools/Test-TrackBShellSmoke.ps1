[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string] $ExecutablePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe'),

    [ValidateRange(1, 60)]
    [int] $StartupTimeoutSeconds = 15
)

$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
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

        [pscustomobject]@{
            argument = $scenario.argument
            pid = $observed.Id
            responding = $observed.Responding
            title = $observed.MainWindowTitle
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
    }
}

$results
