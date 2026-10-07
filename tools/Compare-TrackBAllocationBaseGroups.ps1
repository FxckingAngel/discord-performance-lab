[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $BaselinePath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ComparisonPath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-Groups {
    param([string] $Path)
    $capture = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
    $groups = @($capture.allocationBaseGroups | Where-Object { [double]$_.residentBytes -gt 0 } | Sort-Object residentBytes -Descending)
    for ($index = 0; $index -lt $groups.Count; $index++) {
        [pscustomobject]@{
            rank = $index + 1
            residentMiB = [math]::Round(([double]$groups[$index].residentBytes / 1MB), 3)
            committedMiB = [math]::Round(([double]$groups[$index].committedBytes / 1MB), 3)
            regionCount = [int]$groups[$index].regionCount
        }
    }
}

$baseline = @(Read-Groups $BaselinePath)
$comparison = @(Read-Groups $ComparisonPath)
$maxRank = [math]::Max($baseline.Count, $comparison.Count)
$rows = for ($rank = 1; $rank -le $maxRank; $rank++) {
    $before = $baseline | Where-Object rank -eq $rank | Select-Object -First 1
    $after = $comparison | Where-Object rank -eq $rank | Select-Object -First 1
    $beforeResident = if ($before) { [double]$before.residentMiB } else { 0 }
    $afterResident = if ($after) { [double]$after.residentMiB } else { 0 }
    $beforeCommitted = if ($before) { [double]$before.committedMiB } else { 0 }
    $afterCommitted = if ($after) { [double]$after.committedMiB } else { 0 }
    [pscustomobject]@{
        rank = $rank
        baselineResidentMiB = $beforeResident
        comparisonResidentMiB = $afterResident
        deltaResidentMiB = [math]::Round(($afterResident - $beforeResident), 3)
        baselineCommittedMiB = $beforeCommitted
        comparisonCommittedMiB = $afterCommitted
        deltaCommittedMiB = [math]::Round(($afterCommitted - $beforeCommitted), 3)
        baselineRegionCount = if ($before) { $before.regionCount } else { 0 }
        comparisonRegionCount = if ($after) { $after.regionCount } else { 0 }
    }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    policy = 'Rank-based aggregate comparison. Allocation-base addresses are intentionally omitted because ASLR makes raw addresses unsuitable for cross-process identity.'
    baselineSource = (Resolve-Path -LiteralPath $BaselinePath).Path
    comparisonSource = (Resolve-Path -LiteralPath $ComparisonPath).Path
    rows = @($rows)
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result.rows | Format-Table -AutoSize
