[CmdletBinding()]
param(
    [string] $OfficialScreenshot,
    [string] $TrackBScreenshot,
    [string] $OutputPath = (Join-Path (Get-Location) ('benchmarks/raw/track-b-visual-checkpoint-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json'))
)

$conditions = @(
    @{ id = 'same-account'; label = 'Same Discord account' }
    @{ id = 'same-route'; label = 'Same exact route, DM, or channel' }
    @{ id = 'same-call-state'; label = 'Same call, video, and screen-share state' }
    @{ id = 'same-window'; label = 'Same window dimensions and display scaling' }
    @{ id = 'same-display'; label = 'Same 1920x1080 / 60 Hz display' }
    @{ id = 'settled'; label = 'Both applications settled before capture' }
)

$confirmed = foreach ($condition in $conditions) {
    $answer = (Read-Host "$($condition.label) [Y/N]").Trim().ToUpperInvariant()
    if ($answer -notin @('Y', 'N')) {
        throw "Invalid answer '$answer'. Use Y or N."
    }
    [pscustomobject]@{ id = $condition.id; confirmed = ($answer -eq 'Y') }
}

$comparison = $null
if ($OfficialScreenshot -or $TrackBScreenshot) {
    if (-not $OfficialScreenshot -or -not $TrackBScreenshot) {
        throw 'Provide both -OfficialScreenshot and -TrackBScreenshot, or neither.'
    }
    foreach ($path in @($OfficialScreenshot, $TrackBScreenshot)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Screenshot was not found: $path"
        }
    }
    $comparisonTool = Join-Path $PSScriptRoot 'Compare-DiscordScreenshots.py'
    $comparisonJson = & python $comparisonTool $OfficialScreenshot $TrackBScreenshot
    if ($LASTEXITCODE -ne 0) {
        throw 'Screenshot comparison failed.'
    }
    $comparison = $comparisonJson | ConvertFrom-Json
}

$parityReady = @($confirmed | Where-Object { -not $_.confirmed }).Count -eq 0
$report = [pscustomobject]@{
    schemaVersion = 1
    capturedAt = (Get-Date).ToUniversalTime().ToString('o')
    policy = 'Manual visual checkpoint. Screenshots remain local and are not copied into the report.'
    conditions = @($confirmed)
    screenshotComparison = $comparison
    parityReady = $parityReady
    result = if (-not $parityReady) { 'WAITING_FOR_MANUAL_CHECKPOINT' } elseif (-not $comparison) { 'READY_FOR_LOCAL_SCREENSHOT_COMPARISON' } else { 'RECORDED_FOR_REVIEW' }
}

$parent = Split-Path -Parent $OutputPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$report | Select-Object capturedAt, parityReady, result, @{Name='outputPath'; Expression={ $OutputPath }}
