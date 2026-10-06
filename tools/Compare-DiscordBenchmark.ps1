[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $BaselineSummary,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $CandidateSummary,

    [ValidateRange(0, 100)]
    [double] $MaxRegressionPercent = 5,

    [string] $OutputPath
)

function Get-ImprovementPercent {
    param([double] $Baseline, [double] $Candidate)
    if ($Baseline -eq 0) { return 0 }
    return (($Baseline - $Candidate) / $Baseline) * 100
}

$baseline = Get-Content -LiteralPath $BaselineSummary -Raw | ConvertFrom-Json
$candidate = Get-Content -LiteralPath $CandidateSummary -Raw | ConvertFrom-Json

$metrics = @(
    [pscustomobject] @{ name = 'workingSetMedianMiB'; baseline = [double] $baseline.workingSetMiB.median; candidate = [double] $candidate.workingSetMiB.median },
    [pscustomobject] @{ name = 'workingSetP95MiB'; baseline = [double] $baseline.workingSetMiB.p95; candidate = [double] $candidate.workingSetMiB.p95 },
    [pscustomobject] @{ name = 'privateWorkingSetMedianMiB'; baseline = [double] $baseline.privateWorkingSetMiB.median; candidate = [double] $candidate.privateWorkingSetMiB.median },
    [pscustomobject] @{ name = 'privateWorkingSetP95MiB'; baseline = [double] $baseline.privateWorkingSetMiB.p95; candidate = [double] $candidate.privateWorkingSetMiB.p95 },
    [pscustomobject] @{ name = 'privateMemoryMedianMiB'; baseline = [double] $baseline.privateMemoryMiB.median; candidate = [double] $candidate.privateMemoryMiB.median },
    [pscustomobject] @{ name = 'privateMemoryP95MiB'; baseline = [double] $baseline.privateMemoryMiB.p95; candidate = [double] $candidate.privateMemoryMiB.p95 },
    [pscustomobject] @{ name = 'cpuMedianPercentOfTotal'; baseline = [double] $baseline.cpuPercentOfTotal.medianRun; candidate = [double] $candidate.cpuPercentOfTotal.medianRun },
    [pscustomobject] @{ name = 'cpuP95PercentOfTotal'; baseline = [double] $baseline.cpuPercentOfTotal.p95Run; candidate = [double] $candidate.cpuPercentOfTotal.p95Run },
    [pscustomobject] @{ name = 'processCountMedian'; baseline = [double] $baseline.processCount.median; candidate = [double] $candidate.processCount.median },
    [pscustomobject] @{ name = 'processCountMaximum'; baseline = [double] $baseline.processCount.maximum; candidate = [double] $candidate.processCount.maximum }
)

$results = @($metrics | ForEach-Object {
    $improvement = Get-ImprovementPercent -Baseline $_.baseline -Candidate $_.candidate
    [pscustomobject] @{
        name = $_.name
        baseline = [math]::Round($_.baseline, 3)
        candidate = [math]::Round($_.candidate, 3)
        improvementPercent = [math]::Round($improvement, 3)
        regressionBeyondThreshold = ($improvement -lt (0 - $MaxRegressionPercent))
    }
})

$comparison = [pscustomobject] @{
    schemaVersion = 1
    baselineSummary = (Resolve-Path -LiteralPath $BaselineSummary).Path
    candidateSummary = (Resolve-Path -LiteralPath $CandidateSummary).Path
    maxRegressionPercent = $MaxRegressionPercent
    passed = -not @($results | Where-Object regressionBeyondThreshold)
    metrics = $results
}

if ($OutputPath) {
    $parent = Split-Path -Parent $OutputPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $comparison | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding utf8
}

$comparison | ConvertTo-Json -Depth 6
if (-not $comparison.passed) { exit 2 }
