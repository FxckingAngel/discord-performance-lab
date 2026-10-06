[CmdletBinding()]
param(
    [string] $ExecutablePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe'),

    [ValidateRange(1, 65535)]
    [int] $Port = 9230,

    [ValidateRange(5, 3600)]
    [int] $DurationSeconds = 600,

    [ValidateRange(1, 60)]
    [int] $IntervalSeconds = 5,

    [ValidateNotNullOrEmpty()]
    [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-b-memory-checkpoint-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$node = Get-Command node.exe -ErrorAction Stop
$powershell = Get-Command pwsh.exe -ErrorAction Stop
$measureScript = Join-Path $PSScriptRoot 'Measure-DiscordPhase2Attribution.ps1'
$summaryScript = Join-Path $PSScriptRoot 'Summarize-DiscordPhase2Attribution.ps1'
$cdpScript = Join-Path $PSScriptRoot 'Invoke-DiscordPhase2CdpDiagnostics.mjs'
foreach ($requiredPath in @($measureScript, $summaryScript, $cdpScript)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required diagnostic tool was not found: $requiredPath"
    }
}

$existing = @(Get-Process -Name 'KoroneDiscordShell' -ErrorAction SilentlyContinue)
if ($existing.Count -gt 0) {
    throw "A Track B shell is already running (PID $($existing.Id -join ', ')). Close it manually before starting this checkpoint."
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$rawAttributionPath = Join-Path $OutputDirectory 'process-tree-attribution.json'
$summaryPath = Join-Path $OutputDirectory 'process-tree-attribution-summary.json'
$cdpPath = Join-Path $OutputDirectory 'cdp-diagnostics.json'
$measureProcess = $null
$diagnosticProcess = $null
$checkpointConfirmed = $false

try {
    $diagnosticProcess = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-authenticated-no-bridges' -PassThru
    $ready = $false
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    do {
        try {
            $targets = @(Invoke-RestMethod -Uri "http://127.0.0.1:$Port/json/list" -TimeoutSec 1)
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
    if (-not $ready) { throw "Track B diagnostic CDP endpoint did not become ready on port $Port." }

    Write-Host 'Complete these steps manually:'
    Write-Host '1. Log into Discord normally if needed.'
    Write-Host '2. Navigate to the exact route and workload being measured.'
    Write-Host '3. Leave the intended window size, display, and workload unchanged.'
    $confirmation = Read-Host 'Type READY to begin memory attribution'
    if ($confirmation -cne 'READY') { throw 'Manual checkpoint was not confirmed. No measurement was started.' }
    $checkpointConfirmed = $true

    $measureArguments = @(
        '-NoProfile', '-File', $measureScript,
        '-RootPid', "$($diagnosticProcess.Id)",
        '-DurationSeconds', "$DurationSeconds",
        '-IntervalSeconds', "$IntervalSeconds",
        '-Scenario', 'track-b-memory-attribution-checkpoint',
        '-OutputPath', $rawAttributionPath
    )
    $measureProcess = Start-Process -FilePath $powershell.Source -ArgumentList $measureArguments -PassThru -WindowStyle Hidden
    & $node.Source $cdpScript $Port $DurationSeconds $cdpPath
    if ($LASTEXITCODE -ne 0) { throw "CDP diagnostics failed with exit code $LASTEXITCODE." }
    $measureProcess.WaitForExit()
    if ($measureProcess.ExitCode -ne 0) { throw "Process attribution failed with exit code $($measureProcess.ExitCode)." }
    & $powershell.Source -NoProfile -File $summaryScript -InputPath $rawAttributionPath -OutputPath $summaryPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Process attribution summary failed with exit code $LASTEXITCODE." }

    [pscustomobject]@{
        result = 'PASS'
        checkpoint = 'READY'
        durationSeconds = $DurationSeconds
        processTreePath = (Resolve-Path -LiteralPath $rawAttributionPath).Path
        processTreeSummaryPath = (Resolve-Path -LiteralPath $summaryPath).Path
        cdpPath = (Resolve-Path -LiteralPath $cdpPath).Path
    } | ConvertTo-Json -Depth 4
}
finally {
    if ($measureProcess) {
        $measureProcess.Refresh()
        if (-not $measureProcess.HasExited) { $measureProcess.WaitForExit(5000) }
    }
    if ($diagnosticProcess) {
        $current = Get-Process -Id $diagnosticProcess.Id -ErrorAction SilentlyContinue
        if ($current) {
            [void] $current.CloseMainWindow()
            $current.WaitForExit(8000)
        }
        if (Get-Process -Id $diagnosticProcess.Id -ErrorAction SilentlyContinue) {
            throw "Diagnostic checkpoint process $($diagnosticProcess.Id) did not exit through its normal close action."
        }
        Start-Sleep -Seconds 2
        $restored = Start-Process -FilePath $resolvedExecutable -PassThru
        $restoreDeadline = [DateTime]::UtcNow.AddSeconds(15)
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
}
