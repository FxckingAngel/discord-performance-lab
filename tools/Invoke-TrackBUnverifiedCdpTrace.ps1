[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [switch] $AllowNormalShellRestart,

    [ValidateSet('--diagnostic-authenticated-no-bridges', '--diagnostic-blank')]
    [string] $DiagnosticArgument = '--diagnostic-authenticated-no-bridges',

    [ValidateSet(9223, 9230)]
    [int] $CdpPort = 9230,

    [ValidateNotNullOrEmpty()]
    [string] $ExecutablePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe'),

    [ValidateRange(1, 60)]
    [int] $DurationSeconds = 20,

    [ValidateRange(0, 600)]
    [int] $SettleSeconds = 60,

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = (Join-Path (Get-Location) ('artifacts/track-b-cdp-trace-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json'))
)

if (-not $AllowNormalShellRestart) {
    throw 'This diagnostic closes and restores the normal shell. Pass -AllowNormalShellRestart explicitly.'
}

$expectedCdpPort = if ($DiagnosticArgument -eq '--diagnostic-blank') { 9223 } else { 9230 }
if ($CdpPort -ne $expectedCdpPort) {
    throw "$DiagnosticArgument exposes loopback CDP on port $expectedCdpPort. Pass -CdpPort $expectedCdpPort."
}

$resolvedExecutable = (Resolve-Path $ExecutablePath -ErrorAction Stop).Path
$node = Get-Command node.exe -ErrorAction Stop
$traceScript = Join-Path $PSScriptRoot 'Capture-TrackBCdpTrace.mjs'
if (-not (Test-Path -LiteralPath $traceScript -PathType Leaf)) {
    throw "Trace script was not found: $traceScript"
}

$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$diagnosticProcess = $null

function Close-Normally {
    param([System.Diagnostics.Process] $Process)
    if (-not $Process) { return }
    $current = Get-Process -Id $Process.Id -ErrorAction SilentlyContinue
    if (-not $current) { return }
    [void] $current.CloseMainWindow()
    if (-not $current.WaitForExit(10000)) {
        throw "Process $($Process.Id) did not close through its normal window-close path."
    }
}

try {
    foreach ($process in @(Get-Process -Name KoroneDiscordShell -ErrorAction SilentlyContinue)) {
        Close-Normally -Process $process
    }
    if (Get-Process -Name KoroneDiscordShell -ErrorAction SilentlyContinue) {
        throw 'A normal Track B shell root remains after the requested close.'
    }

    $diagnosticProcess = Start-Process -FilePath $resolvedExecutable -ArgumentList $DiagnosticArgument -PassThru
    $ready = $false
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    do {
        try {
            $targets = @(Invoke-RestMethod -Uri "http://127.0.0.1:$CdpPort/json/list" -TimeoutSec 1)
            if (@($targets | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl }).Count -gt 0) {
                $ready = $true
                break
            }
        }
        catch {
            # The diagnostic endpoint may take a few seconds to open.
        }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $deadline)
    if (-not $ready) { throw 'The authenticated diagnostic CDP endpoint did not open.' }

    if ($SettleSeconds -gt 0) {
        Start-Sleep -Seconds $SettleSeconds
    }

    & $node.Source $traceScript $CdpPort $DurationSeconds $OutputPath
    if ($LASTEXITCODE -ne 0) { throw "CDP trace failed with exit code $LASTEXITCODE." }
    [pscustomobject]@{
        result = 'CAPTURED'
        verification = 'unverified-route-and-workload'
        diagnosticArgument = $DiagnosticArgument
        cdpPort = $CdpPort
        durationSeconds = $DurationSeconds
        settleSeconds = $SettleSeconds
        outputPath = (Resolve-Path -LiteralPath $OutputPath).Path
    } | ConvertTo-Json -Depth 4
}
finally {
    Close-Normally -Process $diagnosticProcess
    Start-Sleep -Seconds 2
    $restored = Start-Process -FilePath $resolvedExecutable -PassThru
    $restoreDeadline = [DateTime]::UtcNow.AddSeconds(20)
    $restoredObserved = $null
    do {
        Start-Sleep -Milliseconds 250
        $restoredObserved = Get-Process -Id $restored.Id -ErrorAction SilentlyContinue
        if ($restoredObserved -and $restoredObserved.Responding) { break }
    } while ([DateTime]::UtcNow -lt $restoreDeadline)
    if (-not $restoredObserved -or -not $restoredObserved.Responding) {
        throw "Normal Track B shell did not become responsive after trace restore. PID $($restored.Id)."
    }
}
