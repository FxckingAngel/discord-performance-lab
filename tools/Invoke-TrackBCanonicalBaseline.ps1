[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [int] $RootPid,
    [ValidateRange(5, 3600)] [int] $SettleSeconds = 30,
    [ValidateRange(30, 3600)] [int] $DurationSeconds = 600,
    [ValidateRange(1, 60)] [int] $IntervalSeconds = 5,
    [ValidateRange(5, 10)] [int] $Repetitions = 5,
    [switch] $SkipManualCheckpoint,
    [ValidateNotNullOrEmpty()] [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-b-canonical-baseline-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# PowerShell script invocations do not initialize LASTEXITCODE. Keep the
# existing child-tool checks valid under strict mode.
$global:LASTEXITCODE = 0
$measure = Join-Path $PSScriptRoot 'Measure-DiscordPhase2Attribution.ps1'
$summary = Join-Path $PSScriptRoot 'Summarize-DiscordPhase2Attribution.ps1'
$roleMap = Join-Path $PSScriptRoot 'Get-DiscordPhase2RoleMap.ps1'
$resident = Join-Path $PSScriptRoot 'Measure-TrackBResidentMemoryTypes.ps1'
$webViewJoin = Join-Path $PSScriptRoot 'Join-TrackBWebViewProcessInfo.ps1'
$webViewInfoDirectory = Join-Path $env:LOCALAPPDATA 'KoroneDiscordShell/Diagnostics'
foreach ($path in @($measure, $summary, $roleMap, $resident, $webViewJoin)) { if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required baseline tool was not found: $path" } }
$root = Get-Process -Id $RootPid -ErrorAction Stop
if (-not $root.Responding) { throw "Track B root PID $RootPid is not responding." }
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

$verification = 'manual-canonical-route'
if ($SkipManualCheckpoint) {
    $verification = 'automated-unverified-route'
    Write-Host 'Manual route checkpoint skipped. Results are diagnostic only and cannot serve as final same-route acceptance evidence.'
}
else {
    Write-Host 'Prepare the exact canonical state manually:'
    Write-Host '- same authenticated account and exact static DM or text channel'
    Write-Host '- no voice, video, screen share, GIF, video, or visible media activity'
    Write-Host '- same foreground window size and 1920x1080 60 Hz display'
    Write-Host '- leave the route untouched for every repetition'
    $confirmation = Read-Host 'Type READY after the canonical state is visible'
    if ($confirmation -cne 'READY') { throw 'Canonical baseline was not manually confirmed. No repetitions were measured.' }
}

$repetitionsData = [System.Collections.Generic.List[object]]::new()
for ($index = 1; $index -le $Repetitions; $index++) {
    $repeat = Join-Path $OutputDirectory ("repeat-{0:D2}" -f $index)
    New-Item -ItemType Directory -Force -Path $repeat | Out-Null
    Start-Sleep -Seconds $SettleSeconds
    $current = Get-Process -Id $RootPid -ErrorAction Stop
    if (-not $current.Responding) { throw "Track B root stopped responding before repetition $index." }
    $treePath = Join-Path $repeat 'process-tree.json'
    $summaryPath = Join-Path $repeat 'process-tree-summary.json'
    $roleMapPath = Join-Path $repeat 'role-map-local.json'
    $webViewInfoPath = Join-Path $repeat 'webview-process-info.json'
    $webViewJoinPath = Join-Path $repeat 'webview-process-join.json'
    & $roleMap -RootPid $RootPid -ProcessName 'KoroneDiscordShell' -OutputPath $roleMapPath | Out-Null
    & $measure -RootPid $RootPid -ProcessName 'KoroneDiscordShell' -DurationSeconds $DurationSeconds -IntervalSeconds $IntervalSeconds -Scenario 'track-b-canonical-authenticated-static' -OutputPath $treePath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Canonical process capture failed for repetition $index." }
    & $summary -InputPath $treePath -OutputPath $summaryPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Canonical summary failed for repetition $index." }
    $treeForInventory = Get-Content -Raw -LiteralPath $treePath | ConvertFrom-Json
    $treePids = @($treeForInventory.samples[-1].processes | ForEach-Object { [int]$_.pid })
    $inventoryCandidate = $null
    $inventoryOverlap = -1
    foreach ($candidate in @(Get-ChildItem -LiteralPath $webViewInfoDirectory -Filter 'webview-process-info*.json' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)) {
        try {
            $candidateData = Get-Content -Raw -LiteralPath $candidate.FullName | ConvertFrom-Json
            $candidatePids = @($candidateData.processes | ForEach-Object { [int]$_.processId })
            $overlap = @($candidatePids | Where-Object { $treePids -contains $_ }).Count
            if ($overlap -gt $inventoryOverlap) {
                $inventoryCandidate = $candidate
                $inventoryOverlap = $overlap
            }
        } catch {
            # Ignore a partially written inventory and continue with other profiles.
        }
    }
    if ($inventoryCandidate -and $inventoryOverlap -gt 0) {
        Copy-Item -LiteralPath $inventoryCandidate.FullName -Destination $webViewInfoPath -Force
        & $webViewJoin -ProcessTreePath $treePath -WebViewProcessInfoPath $webViewInfoPath -OutputPath $webViewJoinPath | Out-Null
    }
    $summaryData = Get-Content -Raw -LiteralPath $summaryPath | ConvertFrom-Json
    $renderer = $summaryData.processes | Where-Object role -eq 'renderer' | Select-Object -First 1
    $residentPath = Join-Path $repeat 'renderer-resident-types.json'
    $rendererPid = if ($renderer) { [int]$renderer.pid } else { 0 }
    $residentCaptured = $false
    if ($rendererPid -gt 0) {
        try {
            & $resident -ProcessId $rendererPid -Role renderer -OutputPath $residentPath | Out-Null
            $residentCaptured = ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $residentPath -PathType Leaf))
            if (-not $residentCaptured) {
                Write-Warning "Renderer resident-memory classification was unavailable for repetition $index (PID $rendererPid). The process may have changed during the read-only map walk."
            }
        } catch {
            Write-Warning "Renderer resident-memory classification failed for repetition $index (PID $rendererPid): $($_.Exception.Message)"
        }
    }
    $repetitionsData.Add([pscustomobject]@{
        repetition = $index
        settleSeconds = $SettleSeconds
        durationSeconds = $DurationSeconds
        processSummaryPath = (Resolve-Path -LiteralPath $summaryPath).Path
        roleMapPath = (Resolve-Path -LiteralPath $roleMapPath).Path
        webViewProcessInfoPath = if (Test-Path -LiteralPath $webViewInfoPath) { (Resolve-Path -LiteralPath $webViewInfoPath).Path } else { $null }
        webViewProcessJoinPath = if (Test-Path -LiteralPath $webViewJoinPath) { (Resolve-Path -LiteralPath $webViewJoinPath).Path } else { $null }
        rendererResidentPath = if ($residentCaptured) { (Resolve-Path -LiteralPath $residentPath).Path } else { $null }
        rendererPid = $rendererPid
    })
}
$summaryRows = @($repetitionsData | ForEach-Object { Get-Content -Raw -LiteralPath $_.processSummaryPath | ConvertFrom-Json })
$rendererPids = @($repetitionsData | Where-Object { [int]$_.rendererPid -gt 0 } | ForEach-Object { [int]$_.rendererPid } | Sort-Object -Unique)
$processCountStable = (@($summaryRows | Where-Object { [int]$_.processTree.processCountMedian -ne [int]$_.processTree.processCountP95 }).Count -eq 0)
$webViewInventorySynchronized = (@($repetitionsData | Where-Object {
    if ([string]::IsNullOrWhiteSpace([string]$_.webViewProcessJoinPath)) { return $true }
    $join = Get-Content -Raw -LiteralPath $_.webViewProcessJoinPath | ConvertFrom-Json
    return [bool]$join.rendererPidMatch
}).Count -eq $Repetitions)
$initializedGate = [pscustomobject]@{
    manualRouteConfirmed = -not $SkipManualCheckpoint
    rendererPidStable = ($rendererPids.Count -eq 1)
    rendererPid = if ($rendererPids.Count -eq 1) { $rendererPids[0] } else { $null }
    processCountStable = $processCountStable
    webViewInventorySynchronized = $webViewInventorySynchronized
    frontendAndRouteVisiblyConfirmed = -not $SkipManualCheckpoint
    routeUnchangedDuringCapture = -not $SkipManualCheckpoint
    passed = (-not $SkipManualCheckpoint) -and ($rendererPids.Count -eq 1) -and $processCountStable -and $webViewInventorySynchronized
}
if (-not $SkipManualCheckpoint -and -not $initializedGate.passed) {
    throw 'Fully initialized benchmark gate failed: renderer PID, process count, or WebView2 inventory was not stable and synchronized.'
}
[pscustomobject]@{
    schemaVersion = 1
    result = 'CAPTURED'
    scenario = 'track-b-canonical-authenticated-static'
    rootPid = $RootPid
    repetitions = @($repetitionsData)
    settleSeconds = $SettleSeconds
    durationSeconds = $DurationSeconds
    intervalSeconds = $IntervalSeconds
    verification = $verification
    initializedGate = $initializedGate
    policy = 'Fixed-state repetitions. Manual route confirmation is required for acceptance; automated mode is diagnostic only. No account content, command lines, or heap objects are published.'
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'manifest.json') -Encoding utf8
