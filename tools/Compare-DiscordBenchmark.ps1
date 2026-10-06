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

    [ValidateRange(1, [double]::MaxValue)]
    [double] $TargetPrivateWorkingSetMiB = 250,

    [ValidateRange(1, [double]::MaxValue)]
    [double] $TargetPrivateBytesMiB = 250,

    [ValidateRange(0, [double]::MaxValue)]
    [double] $TargetCpuPercent = 0.2,

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
    [pscustomobject] @{ name = 'shareableWorkingSetMedianMiB'; baseline = [double] $baseline.shareableWorkingSetMiB.median; candidate = [double] $candidate.shareableWorkingSetMiB.median },
    [pscustomobject] @{ name = 'shareableWorkingSetP95MiB'; baseline = [double] $baseline.shareableWorkingSetMiB.p95; candidate = [double] $candidate.shareableWorkingSetMiB.p95 },
    [pscustomobject] @{ name = 'privateWorkingSetMedianMiB'; baseline = [double] $baseline.privateWorkingSetMiB.median; candidate = [double] $candidate.privateWorkingSetMiB.median },
    [pscustomobject] @{ name = 'privateWorkingSetP95MiB'; baseline = [double] $baseline.privateWorkingSetMiB.p95; candidate = [double] $candidate.privateWorkingSetMiB.p95 },
    [pscustomobject] @{ name = 'privateMemoryMedianMiB'; baseline = [double] $baseline.privateMemoryMiB.median; candidate = [double] $candidate.privateMemoryMiB.median },
    [pscustomobject] @{ name = 'privateMemoryP95MiB'; baseline = [double] $baseline.privateMemoryMiB.p95; candidate = [double] $candidate.privateMemoryMiB.p95 },
    [pscustomobject] @{ name = 'commitMedianMiB'; baseline = [double] $baseline.commitMiB.median; candidate = [double] $candidate.commitMiB.median },
    [pscustomobject] @{ name = 'cpuMedianPercentOfTotal'; baseline = [double] $baseline.cpuPercentOfTotal.medianRun; candidate = [double] $candidate.cpuPercentOfTotal.medianRun },
    [pscustomobject] @{ name = 'cpuP95PercentOfTotal'; baseline = [double] $baseline.cpuPercentOfTotal.p95Run; candidate = [double] $candidate.cpuPercentOfTotal.p95Run },
    [pscustomobject] @{ name = 'processCountMedian'; baseline = [double] $baseline.processCount.median; candidate = [double] $candidate.processCount.median },
    [pscustomobject] @{ name = 'processCountMaximum'; baseline = [double] $baseline.processCount.maximum; candidate = [double] $candidate.processCount.maximum },
    [pscustomobject] @{ name = 'handlesMedian'; baseline = [double] $baseline.handles.median; candidate = [double] $candidate.handles.median },
    [pscustomobject] @{ name = 'handlesP95'; baseline = [double] $baseline.handles.p95; candidate = [double] $candidate.handles.p95 },
    [pscustomobject] @{ name = 'threadsMedian'; baseline = [double] $baseline.threads.median; candidate = [double] $candidate.threads.median },
    [pscustomobject] @{ name = 'threadsP95'; baseline = [double] $baseline.threads.p95; candidate = [double] $candidate.threads.p95 }
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
    schemaVersion = 2
    baselineSummary = (Resolve-Path -LiteralPath $BaselineSummary).Path
    candidateSummary = (Resolve-Path -LiteralPath $CandidateSummary).Path
    maxRegressionPercent = $MaxRegressionPercent
    passed = -not @($results | Where-Object regressionBeyondThreshold)
    target = [pscustomobject] @{
        privateWorkingSetMedianMiB = [math]::Round([double] $candidate.privateWorkingSetMiB.median, 3)
        privateWorkingSetLimitMiB = $TargetPrivateWorkingSetMiB
        privateBytesMedianMiB = [math]::Round([double] $candidate.privateMemoryMiB.median, 3)
        privateBytesLimitMiB = $TargetPrivateBytesMiB
        cpuMedianPercentOfTotal = [math]::Round([double] $candidate.cpuPercentOfTotal.medianRun, 3)
        cpuLimitPercentOfTotal = $TargetCpuPercent
        physicalResidentPassed = ([double] $candidate.privateWorkingSetMiB.median -le $TargetPrivateWorkingSetMiB)
        privateBytesPassed = ([double] $candidate.privateMemoryMiB.median -le $TargetPrivateBytesMiB)
        passed = ([double] $candidate.privateWorkingSetMiB.median -le $TargetPrivateWorkingSetMiB) -and ([double] $candidate.privateMemoryMiB.median -le $TargetPrivateBytesMiB) -and ([double] $candidate.cpuPercentOfTotal.medianRun -le $TargetCpuPercent)
    }
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
