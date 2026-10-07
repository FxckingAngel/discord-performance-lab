[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ManifestPath,

    [string] $OutputPath = (Join-Path (Get-Location) ('artifacts/track-b-allocation-family-decay-summary-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json'))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-FamilyId([string] $AllocationBase) {
    $bytes = [Text.Encoding]::UTF8.GetBytes($AllocationBase)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $hash = $sha.ComputeHash($bytes) } finally { $sha.Dispose() }
    return 'family-' + ([BitConverter]::ToString($hash).Replace('-', '').Substring(0, 12).ToLowerInvariant())
}

function Read-Groups([string] $Path) {
    $memory = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
    foreach ($group in @($memory.allocationBaseGroups | Where-Object { [double]$_.residentBytes -gt 1MB })) {
        [pscustomobject]@{
            familyId = Get-FamilyId ([string]$group.allocationBase)
            residentMiB = [math]::Round(([double]$group.residentBytes / 1MB), 3)
            committedMiB = [math]::Round(([double]$group.committedBytes / 1MB), 3)
            regionCount = [int]$group.regionCount
        }
    }
}

$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
$records = @($manifest.checkpoints)
$states = [ordered]@{}
foreach ($record in $records) { $states[[string]$record.label] = @(Read-Groups ([string]$record.rendererMemoryPath)) }
$labels = @('static-before', 'media-visible', 'static-after-30s', 'static-after-120s', 'static-after-300s')
$families = @($states.Values | ForEach-Object { $_.familyId } | Sort-Object -Unique)
$rows = foreach ($familyId in $families) {
    $values = [ordered]@{}
    foreach ($label in $labels) {
        $match = @($states[$label] | Where-Object familyId -eq $familyId | Select-Object -First 1)
        $values[$label] = if ($match) { [double]$match.residentMiB } else { 0 }
    }
    $baseline = [double]$values['static-before']
    $media = [double]$values['media-visible']
    $peakDelta = $media - $baseline
    $final = [double]$values['static-after-300s']
    $returnDelta = $final - $baseline
    $classification = if ($peakDelta -ge 8 -and $returnDelta -le [math]::Max(4, $peakDelta * 0.25)) { 'media/compositor-dependent candidate' }
    elseif ($baseline -ge 8 -and [math]::Abs($returnDelta) -le [math]::Max(4, $baseline * 0.25)) { 'persistent settled candidate' }
    elseif ($peakDelta -ge 8) { 'media-associated residual candidate' }
    else { 'small-or-unresolved' }
    [pscustomobject]@{
        familyId = $familyId
        staticBeforeMiB = $baseline
        mediaVisibleMiB = $media
        after30sMiB = [double]$values['static-after-30s']
        after120sMiB = [double]$values['static-after-120s']
        after300sMiB = $final
        mediaPeakDeltaMiB = [math]::Round($peakDelta, 3)
        finalReturnDeltaMiB = [math]::Round($returnDelta, 3)
        classification = $classification
    }
}
$result = [ordered]@{
    schemaVersion = 1
    summarizedAt = (Get-Date).ToUniversalTime().ToString('o')
    sourceManifest = (Resolve-Path -LiteralPath $ManifestPath).Path
    policy = 'Sanitized same-renderer family classification. Addresses, page contents, account data, URLs, and raw maps are omitted. Classification is a diagnostic heuristic, not ownership proof.'
    thresholds = [ordered]@{ minimumMediaDeltaMiB = 8; returnFraction = 0.25; returnAllowanceMiB = 4 }
    families = @($rows | Sort-Object mediaPeakDeltaMiB -Descending)
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result.families | Format-Table -AutoSize
