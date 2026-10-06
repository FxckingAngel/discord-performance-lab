[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $CandidateSummary,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $FunctionalReport,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $VisualReport,

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath
)

$candidate = Get-Content -LiteralPath $CandidateSummary -Raw | ConvertFrom-Json
$functional = Get-Content -LiteralPath $FunctionalReport -Raw | ConvertFrom-Json
$visual = Get-Content -LiteralPath $VisualReport -Raw | ConvertFrom-Json

$requiredSummaryGroups = @('privateWorkingSetMiB', 'privateMemoryMiB', 'cpuPercentOfTotal')
$missingGroups = @($requiredSummaryGroups | Where-Object { -not $candidate.psobject.Properties.Name.Contains($_) })
if ($missingGroups.Count -gt 0) {
    throw "Candidate summary is missing required metric groups: $($missingGroups -join ', ')."
}

$requiredMetricValues = @(
    [pscustomobject] @{ name = 'privateWorkingSetMiB.median'; value = $candidate.privateWorkingSetMiB.median }
    [pscustomobject] @{ name = 'privateWorkingSetMiB.p95'; value = $candidate.privateWorkingSetMiB.p95 }
    [pscustomobject] @{ name = 'privateMemoryMiB.median'; value = $candidate.privateMemoryMiB.median }
    [pscustomobject] @{ name = 'privateMemoryMiB.p95'; value = $candidate.privateMemoryMiB.p95 }
    [pscustomobject] @{ name = 'cpuPercentOfTotal.medianRun'; value = $candidate.cpuPercentOfTotal.medianRun }
    [pscustomobject] @{ name = 'cpuPercentOfTotal.p95Run'; value = $candidate.cpuPercentOfTotal.p95Run }
)
$missingValues = @($requiredMetricValues | Where-Object { $null -eq $_.value })
if ($missingValues.Count -gt 0) {
    throw "Candidate summary is missing required metric values: $(($missingValues | ForEach-Object name) -join ', ')."
}

$resourceFields = @(
    [pscustomobject] @{ name = 'privateWorkingSetMedianMiB'; value = [double] $candidate.privateWorkingSetMiB.median; limit = 250 }
    [pscustomobject] @{ name = 'privateWorkingSetP95MiB'; value = [double] $candidate.privateWorkingSetMiB.p95; limit = 250 }
    [pscustomobject] @{ name = 'privateBytesMedianMiB'; value = [double] $candidate.privateMemoryMiB.median; limit = 250 }
    [pscustomobject] @{ name = 'privateBytesP95MiB'; value = [double] $candidate.privateMemoryMiB.p95; limit = 250 }
    [pscustomobject] @{ name = 'cpuMedianPercentOfTotal'; value = [double] $candidate.cpuPercentOfTotal.medianRun; limit = 0.2 }
    [pscustomobject] @{ name = 'cpuP95PercentOfTotal'; value = [double] $candidate.cpuPercentOfTotal.p95Run; limit = 0.2 }
)
$resourcePassed = @($resourceFields | Where-Object { $_.value -gt $_.limit }).Count -eq 0

$functionalResults = @($functional.results)
$functionalPassed = ($functional.passed -eq $true) -and $functionalResults.Count -gt 0 -and @($functionalResults | Where-Object { $_.status -ne 'PASS' }).Count -eq 0
$visualPassed = ($visual.parityReady -eq $true) -and ($visual.visualReviewPassed -eq $true) -and $null -ne $visual.screenshotComparison

$report = [pscustomobject] @{
    schemaVersion = 1
    capturedAt = (Get-Date).ToUniversalTime().ToString('o')
    candidateSummary = (Resolve-Path -LiteralPath $CandidateSummary).Path
    functionalReport = (Resolve-Path -LiteralPath $FunctionalReport).Path
    visualReport = (Resolve-Path -LiteralPath $VisualReport).Path
    resourcePassed = $resourcePassed
    functionalPassed = $functionalPassed
    visualPassed = $visualPassed
    resourceMetrics = @($resourceFields | ForEach-Object {
        [pscustomobject] @{ name = $_.name; value = [math]::Round($_.value, 5); limit = $_.limit; passed = ($_.value -le $_.limit) }
    })
    passed = $resourcePassed -and $functionalPassed -and $visualPassed
}

if ($OutputPath) {
    $parent = Split-Path -Parent $OutputPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
}

$report | ConvertTo-Json -Depth 8
if (-not $report.passed) { exit 2 }
