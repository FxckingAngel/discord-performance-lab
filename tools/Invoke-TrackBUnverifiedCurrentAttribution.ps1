[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [switch] $AllowNormalShellRestart,

    [ValidateRange(5, 600)]
    [int] $DurationSeconds = 30,

    [ValidateRange(0, 600)]
    [int] $SettleSeconds = 60,

    [switch] $CollectGarbage,

    [ValidateRange(1, 60)]
    [int] $IntervalSeconds = 5,

    [ValidateNotNullOrEmpty()]
    [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-b-cdp-current-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))),

    [ValidateNotNullOrEmpty()]
    [string] $Scenario = 'current-authenticated-unverified',

    [switch] $CaptureHeapSnapshot
)

if (-not $AllowNormalShellRestart) {
    throw 'This diagnostic closes and restores the normal shell. Pass -AllowNormalShellRestart explicitly.'
}

$resolvedExecutable = (Resolve-Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe') -ErrorAction Stop).Path
$node = Get-Command node.exe -ErrorAction Stop
$powershell = Get-Command pwsh.exe -ErrorAction Stop
$measureScript = Join-Path $PSScriptRoot 'Measure-DiscordPhase2Attribution.ps1'
$cdpScript = Join-Path $PSScriptRoot 'Invoke-DiscordPhase2CdpDiagnostics.mjs'
$heapScript = Join-Path $PSScriptRoot 'Capture-TrackBCdpHeapSnapshot.mjs'
foreach ($path in @($measureScript, $cdpScript)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required diagnostic tool was not found: $path"
    }
}
if ($CaptureHeapSnapshot -and -not (Test-Path -LiteralPath $heapScript -PathType Leaf)) {
    throw "Heap snapshot tool was not found: $heapScript"
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$processTreePath = Join-Path $OutputDirectory 'process-tree.json'
$cdpPath = Join-Path $OutputDirectory 'cdp.json'
$heapRawPath = Join-Path $OutputDirectory 'private.heapsnapshot'
$heapSummaryPath = Join-Path $OutputDirectory 'heap-summary.json'
$diagnosticProcess = $null
$measureProcess = $null

function Close-ProcessNormally {
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
        Close-ProcessNormally -Process $process
    }
    if (Get-Process -Name KoroneDiscordShell -ErrorAction SilentlyContinue) {
        throw 'A normal Track B shell root remains after the requested close.'
    }

    $diagnosticProcess = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-authenticated-no-bridges' -PassThru
    $ready = $false
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    do {
        try {
            $targets = @(Invoke-RestMethod -Uri 'http://127.0.0.1:9230/json/list' -TimeoutSec 1)
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

    $measureProcess = Start-Process -FilePath $powershell.Source -WindowStyle Hidden -PassThru -ArgumentList @(
        '-NoProfile', '-File', $measureScript,
        '-RootPid', "$($diagnosticProcess.Id)",
        '-DurationSeconds', "$DurationSeconds",
        '-IntervalSeconds', "$IntervalSeconds",
        '-Scenario', $Scenario,
        '-OutputPath', $processTreePath,
        '-ProcessName', 'KoroneDiscordShell'
    )
    $cdpArguments = @($cdpScript, '9230', "$DurationSeconds", $cdpPath)
    if ($CollectGarbage) { $cdpArguments += '--collect-garbage' }
    & $node.Source @cdpArguments
    if ($LASTEXITCODE -ne 0) { throw "CDP diagnostics failed with exit code $LASTEXITCODE." }
    if ($CaptureHeapSnapshot) {
        & $node.Source $heapScript 9230 $heapRawPath $heapSummaryPath
        if ($LASTEXITCODE -ne 0) { throw "Heap snapshot capture failed with exit code $LASTEXITCODE." }
    }
    $measureProcess.WaitForExit()
    if ($measureProcess.ExitCode -ne 0) { throw "Process attribution failed with exit code $($measureProcess.ExitCode)." }

    [pscustomobject]@{
        result = 'CAPTURED'
        verification = 'unverified-route-and-workload'
        durationSeconds = $DurationSeconds
        settleSeconds = $SettleSeconds
        collectGarbage = [bool] $CollectGarbage
        processTreePath = (Resolve-Path $processTreePath).Path
        cdpPath = (Resolve-Path $cdpPath).Path
        heapSummaryPath = if ($CaptureHeapSnapshot) { (Resolve-Path $heapSummaryPath).Path } else { $null }
        privateHeapSnapshotPath = if ($CaptureHeapSnapshot) { (Resolve-Path $heapRawPath).Path } else { $null }
    } | ConvertTo-Json -Depth 4
}
finally {
    if ($measureProcess) {
        $measureProcess.Refresh()
        if (-not $measureProcess.HasExited) { $measureProcess.WaitForExit(5000) }
    }
    Close-ProcessNormally -Process $diagnosticProcess
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
        throw "Normal Track B shell did not become responsive after diagnostic restore. PID $($restored.Id)."
    }
}
