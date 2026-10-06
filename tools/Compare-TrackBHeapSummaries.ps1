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

function Get-TypeMap {
    param([object] $Summary)

    $map = @{}
    foreach ($row in @($Summary.byType)) {
        if ($null -ne $row.type) {
            $map[[string] $row.type] = $row
        }
    }
    return $map
}

function Get-DeltaPercent {
    param([double] $Baseline, [double] $Comparison)

    if ($Baseline -eq 0) {
        if ($Comparison -eq 0) { return 0 }
        return $null
    }
    return [math]::Round((($Comparison - $Baseline) / $Baseline) * 100, 2)
}

$baseline = Get-Content -LiteralPath $BaselinePath -Raw | ConvertFrom-Json
$comparison = Get-Content -LiteralPath $ComparisonPath -Raw | ConvertFrom-Json
$baselineTypes = Get-TypeMap $baseline
$comparisonTypes = Get-TypeMap $comparison
$typeNames = @($baselineTypes.Keys + $comparisonTypes.Keys | Sort-Object -Unique)

$types = foreach ($type in $typeNames) {
    $before = $baselineTypes[$type]
    $after = $comparisonTypes[$type]
    $beforeBytes = if ($before) { [double] $before.selfBytes } else { 0 }
    $afterBytes = if ($after) { [double] $after.selfBytes } else { 0 }
    $beforeCount = if ($before) { [int64] $before.count } else { 0 }
    $afterCount = if ($after) { [int64] $after.count } else { 0 }
    [pscustomobject]@{
        type = $type
        baselineCount = $beforeCount
        comparisonCount = $afterCount
        countDelta = $afterCount - $beforeCount
        countDeltaPercent = Get-DeltaPercent $beforeCount $afterCount
        baselineMiB = [math]::Round(($beforeBytes / 1MB), 3)
        comparisonMiB = [math]::Round(($afterBytes / 1MB), 3)
        sizeDeltaMiB = [math]::Round((($afterBytes - $beforeBytes) / 1MB), 3)
        sizeDeltaPercent = Get-DeltaPercent $beforeBytes $afterBytes
    }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    policy = 'Aggregate heap-type comparison only. Raw snapshots, names, strings, URLs, page text, cookies, tokens, and heap objects are not copied.'
    baselineSource = (Resolve-Path -LiteralPath $BaselinePath).Path
    comparisonSource = (Resolve-Path -LiteralPath $ComparisonPath).Path
    baseline = [pscustomobject]@{
        nodeCount = $baseline.nodeCount
        totalSelfMiB = $baseline.totalSelfMiB
        detachedNodeCount = $baseline.detachedNodeCount
    }
    comparison = [pscustomobject]@{
        nodeCount = $comparison.nodeCount
        totalSelfMiB = $comparison.totalSelfMiB
        detachedNodeCount = $comparison.detachedNodeCount
    }
    totalDelta = [pscustomobject]@{
        nodeCount = [int64] $comparison.nodeCount - [int64] $baseline.nodeCount
        totalSelfMiB = [math]::Round(([double] $comparison.totalSelfMiB - [double] $baseline.totalSelfMiB), 3)
        detachedNodeCount = [int64] $comparison.detachedNodeCount - [int64] $baseline.detachedNodeCount
    }
    byType = @($types | Sort-Object sizeDeltaMiB -Descending)
}

$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result.byType | Format-Table type,baselineMiB,comparisonMiB,sizeDeltaMiB,sizeDeltaPercent,baselineCount,comparisonCount,countDelta -AutoSize
