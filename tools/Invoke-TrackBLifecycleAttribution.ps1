[CmdletBinding()]
param(
    [string] $ExecutablePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe'),
    [ValidateRange(1, 65535)]
    [int] $Port = 9228,
    [ValidateRange(5, 60)]
    [int] $CheckpointSeconds = 5,
    [ValidateNotNullOrEmpty()]
    [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-b-lifecycle-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))),

    [switch] $Automatic
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$node = (Get-Command node.exe -ErrorAction Stop).Source
$measureScript = Join-Path $PSScriptRoot 'Measure-DiscordPhase2Attribution.ps1'
$summaryScript = Join-Path $PSScriptRoot 'Summarize-DiscordPhase2Attribution.ps1'
$cdpScript = Join-Path $PSScriptRoot 'Invoke-DiscordPhase2CdpDiagnostics.mjs'
$regionScript = Join-Path $PSScriptRoot 'Measure-TrackBResidentMemoryTypes.ps1'
foreach ($path in @($measureScript, $summaryScript, $cdpScript, $regionScript)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required lifecycle tool was not found: $path" }
}

$existing = @(Get-Process -Name 'KoroneDiscordShell' -ErrorAction SilentlyContinue)
if ($existing.Count -gt 0) {
    throw "A Track B shell is already running (PID $($existing.Id -join ', ')). Close it manually before starting lifecycle attribution."
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$process = $null
$checkpointResults = [System.Collections.Generic.List[object]]::new()

function Wait-Endpoint {
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    do {
        try {
            $targets = @(Invoke-RestMethod -Uri "http://127.0.0.1:$Port/json/list" -TimeoutSec 1)
            if (@($targets | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl }).Count -gt 0) { return $true }
        }
        catch { }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $deadline)
    return $false
}

function Get-DescendantProcesses {
    $all = @(Get-CimInstance Win32_Process)
    $seen = [System.Collections.Generic.HashSet[int]]::new()
    $pending = [System.Collections.Generic.Queue[int]]::new()
    $pending.Enqueue([int]$process.Id)
    while ($pending.Count -gt 0) {
        $parentPid = $pending.Dequeue()
        foreach ($candidate in @($all | Where-Object { [int]$_.ParentProcessId -eq $parentPid })) {
            $candidatePid = [int]$candidate.ProcessId
            if ($seen.Add($candidatePid)) { $pending.Enqueue($candidatePid) }
        }
    }
    return @($all | Where-Object { $seen.Contains([int]$_.ProcessId) })
}

function Capture-Checkpoint {
    param([string] $Label, [string] $Instruction, [switch] $SkipReady)

    Write-Host $Instruction
    if (-not $SkipReady) {
        $confirmation = Read-Host 'Type READY when this checkpoint is visible and settled'
        if ($confirmation -cne 'READY') { throw "Checkpoint '$Label' was not confirmed. No capture was started." }
    }

    $safeLabel = ($Label -replace '[^A-Za-z0-9_-]', '-')
    $checkpointDir = Join-Path $OutputDirectory $safeLabel
    New-Item -ItemType Directory -Path $checkpointDir -Force | Out-Null
    $processPath = Join-Path $checkpointDir 'process-tree-attribution.json'
    $summaryPath = Join-Path $checkpointDir 'process-tree-attribution-summary.json'
    $cdpPath = Join-Path $checkpointDir 'cdp-diagnostics.json'
    $regionPath = Join-Path $checkpointDir 'renderer-memory-types.json'
    $measure = Start-Process -FilePath (Get-Command powershell.exe).Source -ArgumentList @(
        '-NoProfile', '-File', $measureScript,
        '-RootPid', "$($process.Id)",
        '-DurationSeconds', "$CheckpointSeconds",
        '-IntervalSeconds', "$CheckpointSeconds",
        '-Scenario', "track-b-lifecycle-$safeLabel",
        '-OutputPath', $processPath
    ) -WindowStyle Hidden -PassThru
    try {
        & $node $cdpScript $Port $CheckpointSeconds $cdpPath
        if ($LASTEXITCODE -ne 0) { throw "CDP diagnostics failed for '$Label' with exit code $LASTEXITCODE." }
        $measure.WaitForExit(($CheckpointSeconds + 30) * 1000)
        if (-not $measure.HasExited) { throw "Process capture did not finish for '$Label'." }
        if ($measure.ExitCode -ne 0) { throw "Process capture failed for '$Label' with exit code $($measure.ExitCode)." }
        $summaryProcess = Start-Process -FilePath (Get-Command powershell.exe).Source -ArgumentList @(
            '-NoProfile', '-File', $summaryScript,
            '-InputPath', $processPath,
            '-OutputPath', $summaryPath
        ) -WindowStyle Hidden -Wait -PassThru
        if ($summaryProcess.ExitCode -ne 0) { throw "Process summary failed for '$Label' with exit code $($summaryProcess.ExitCode)." }
        $renderer = @(Get-DescendantProcesses | Where-Object {
            $_.Name -eq 'msedgewebview2.exe' -and $_.CommandLine -match '--type=renderer(?:\s|$)'
        }) | Select-Object -First 1
        if (-not $renderer) { throw "Renderer process was not found for '$Label'." }
        $regionProcess = Start-Process -FilePath (Get-Command powershell.exe).Source -ArgumentList @(
            '-NoProfile', '-File', $regionScript,
            '-ProcessId', "$([int]$renderer.ProcessId)",
            '-Role', 'renderer',
            '-OutputPath', $regionPath
        ) -WindowStyle Hidden -Wait -PassThru
        if ($regionProcess.ExitCode -ne 0) { throw "Renderer virtual-memory capture failed for '$Label' with exit code $($regionProcess.ExitCode)." }
        $checkpointResults.Add([pscustomobject]@{
            label = $Label
            processPath = (Resolve-Path -LiteralPath $processPath).Path
            processSummaryPath = (Resolve-Path -LiteralPath $summaryPath).Path
            cdpPath = (Resolve-Path -LiteralPath $cdpPath).Path
            rendererMemoryTypesPath = (Resolve-Path -LiteralPath $regionPath).Path
            rendererPid = [int]$renderer.ProcessId
        })
    }
    finally {
        if ($measure -and -not $measure.HasExited) { $measure.WaitForExit(5000) }
    }
}

try {
    $process = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-authenticated' -PassThru
    if (-not (Wait-Endpoint)) { throw "Track B lifecycle CDP endpoint did not become ready on port $Port." }

    if ($Automatic) {
        $automaticCheckpoints = @(
            [pscustomobject]@{ label = 'endpoint-ready'; delaySeconds = 0; instruction = 'Automatic unverified endpoint-ready checkpoint.' },
            [pscustomobject]@{ label = 'startup-5-seconds'; delaySeconds = 5; instruction = 'Automatic unverified five-second startup checkpoint.' },
            [pscustomobject]@{ label = 'startup-15-seconds'; delaySeconds = 10; instruction = 'Automatic unverified fifteen-second startup checkpoint.' },
            [pscustomobject]@{ label = 'startup-30-seconds'; delaySeconds = 15; instruction = 'Automatic unverified thirty-second startup checkpoint.' },
            [pscustomobject]@{ label = 'startup-60-seconds'; delaySeconds = 30; instruction = 'Automatic unverified one-minute startup checkpoint.' },
            [pscustomobject]@{ label = 'settled-3-minutes'; delaySeconds = 120; instruction = 'Automatic unverified three-minute checkpoint.' },
            [pscustomobject]@{ label = 'settled-5-minutes'; delaySeconds = 120; instruction = 'Automatic unverified five-minute checkpoint.' }
        )
        foreach ($checkpoint in $automaticCheckpoints) {
            if ($checkpoint.delaySeconds -gt 0) { Start-Sleep -Seconds $checkpoint.delaySeconds }
            Capture-Checkpoint $checkpoint.label $checkpoint.instruction -SkipReady
        }
    }
    else {
        Capture-Checkpoint 'webview-created-endpoint-ready' 'The diagnostic WebView is running. Leave it untouched for the runtime-floor checkpoint.'
        Capture-Checkpoint 'discord-url-loading' 'Begin loading Discord or reload it now, then wait until the loading transition is visible.'
        Capture-Checkpoint 'login-session-restored' 'Allow normal session restoration or log in manually if needed. Do not automate credentials.'
        Capture-Checkpoint 'application-shell-visible' 'Leave the Discord application shell visible without navigating further.'
        Capture-Checkpoint 'target-route-loaded' 'Navigate manually to the exact static test DM or channel and leave it visible.'
        Capture-Checkpoint 'settled-30-seconds' 'Leave the confirmed route untouched for at least 30 seconds.'
        Capture-Checkpoint 'settled-60-seconds' 'Continue leaving the confirmed route untouched for at least 60 seconds.'
        Capture-Checkpoint 'settled-5-minutes' 'Continue leaving the confirmed route untouched for five minutes.'
    }

    [pscustomobject]@{
        result = 'PASS'
        schemaVersion = 1
        policy = 'Lifecycle attribution only. Raw process, CDP, and virtual-memory artifacts remain local/private; no account content or heap objects are exported.'
        outputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).Path
        checkpoints = @($checkpointResults)
        interpretation = 'The first checkpoint is endpoint-ready, not a guaranteed about:blank state. Use the separate diagnostic-blank mode for the blank runtime floor.'
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'lifecycle-manifest.json') -Encoding utf8
}
finally {
    if ($process) {
        $current = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
        if ($current) { [void]$current.CloseMainWindow(); $current.WaitForExit(8000) }
        if (Get-Process -Id $process.Id -ErrorAction SilentlyContinue) {
            throw "Lifecycle diagnostic process $($process.Id) did not exit through its normal close action."
        }
    }
}
