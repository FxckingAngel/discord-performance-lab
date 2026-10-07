[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ManifestPath,

    [string] $OutputPath = (Join-Path (Get-Location) ('artifacts/track-b-renderer-family-summary-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json') )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-CheckpointRecords($Manifest) {
    foreach ($entry in @($Manifest.checkpoints)) {
        if ($entry -is [array] -and $entry.Count -eq 2 -and $null -ne $entry[1].name) { $entry[1] }
        else { $entry }
    }
}

function Get-FamilyId([string] $AllocationBase) {
    $bytes = [Text.Encoding]::UTF8.GetBytes($AllocationBase)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $hash = $sha.ComputeHash($bytes) } finally { $sha.Dispose() }
    return 'family-' + ([BitConverter]::ToString($hash).Replace('-', '').Substring(0, 12).ToLowerInvariant())
}

$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
$families = [System.Collections.Generic.List[object]]::new()
$checkpointRows = [System.Collections.Generic.List[object]]::new()
foreach ($checkpoint in @(Get-CheckpointRecords $manifest)) {
    $rendererPath = @($checkpoint.memoryTypePaths | Where-Object { [string]$_.role -eq 'renderer' } | Select-Object -First 1 | ForEach-Object { $_.path })[0]
    if ([string]::IsNullOrWhiteSpace($rendererPath) -or -not (Test-Path -LiteralPath $rendererPath -PathType Leaf)) { continue }
    $memory = Get-Content -Raw -LiteralPath $rendererPath | ConvertFrom-Json
    $groups = @($memory.allocationBaseGroups | Sort-Object -Property residentBytes -Descending)
    $rank = 0
    foreach ($group in $groups) {
        $rank++
        $families.Add([pscustomobject]@{
            checkpoint = [string]$checkpoint.name
            familyId = Get-FamilyId ([string]$group.allocationBase)
            rank = $rank
            regionCount = [int]$group.regionCount
            residentMiB = [math]::Round(([double]$group.residentBytes / 1MB), 3)
            committedMiB = [math]::Round(([double]$group.committedBytes / 1MB), 3)
        })
        if ($rank -ge 10) { break }
    }
    $checkpointRows.Add([pscustomobject]@{
        checkpoint = [string]$checkpoint.name
        rendererPid = @($checkpoint.rendererPids)[0]
        familyCount = $groups.Count
        topFamilyResidentMiB = if ($groups.Count -gt 0) { [math]::Round(([double]$groups[0].residentBytes / 1MB), 3) } else { 0 }
        topThreeResidentMiB = [math]::Round((@($groups | Select-Object -First 3 | Measure-Object -Property residentBytes -Sum).Sum / 1MB), 3)
    })
}

$result = [ordered]@{
    schemaVersion = 1
    summarizedAt = (Get-Date).ToUniversalTime().ToString('o')
    sourceManifest = (Resolve-Path -LiteralPath $ManifestPath).Path
    policy = 'Sanitized allocation-family summary. Raw addresses, process maps, and private artifacts remain local. Family IDs are one-way hashes used only to correlate the same allocation base within this run.'
    checkpointRows = @($checkpointRows)
    families = @($families)
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result
