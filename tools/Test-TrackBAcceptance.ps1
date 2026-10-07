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
$candidateBuildValid = @($candidate.builds | ForEach-Object { [string] $_ }) -contains 'KoroneDiscordShell'

$requiredSummaryGroups = @('workingSetMiB', 'privateWorkingSetMiB', 'privateMemoryMiB', 'processCount', 'cpuPercentOfTotal')
$missingGroups = @($requiredSummaryGroups | Where-Object { -not $candidate.psobject.Properties.Name.Contains($_) })
if ($missingGroups.Count -gt 0) {
    throw "Candidate summary is missing required metric groups: $($missingGroups -join ', ')."
}

$requiredMetricValues = @(
    [pscustomobject] @{ name = 'privateWorkingSetMiB.median'; value = $candidate.privateWorkingSetMiB.median }
    [pscustomobject] @{ name = 'privateWorkingSetMiB.p95'; value = $candidate.privateWorkingSetMiB.p95 }
    [pscustomobject] @{ name = 'workingSetMiB.median'; value = $candidate.workingSetMiB.median }
    [pscustomobject] @{ name = 'workingSetMiB.p95'; value = $candidate.workingSetMiB.p95 }
    [pscustomobject] @{ name = 'privateMemoryMiB.median'; value = $candidate.privateMemoryMiB.median }
    [pscustomobject] @{ name = 'privateMemoryMiB.p95'; value = $candidate.privateMemoryMiB.p95 }
    [pscustomobject] @{ name = 'processCount.median'; value = $candidate.processCount.median }
    [pscustomobject] @{ name = 'processCount.maximum'; value = $candidate.processCount.maximum }
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
    [pscustomobject] @{ name = 'cpuMedianPercentOfTotal'; value = [double] $candidate.cpuPercentOfTotal.medianRun; limit = 0.2 }
)
$resourcePassed = @($resourceFields | Where-Object { $_.value -gt $_.limit }).Count -eq 0

$functionalRequiredIds = @(
    'login-session', 'servers-channels', 'messaging', 'images-media',
    'notifications', 'voice', 'video', 'screen-share', 'file-dialogs',
    'clipboard-drag-drop', 'window-shell', 'accessibility'
)
$functionalResults = @($functional.results)
$functionalResultIds = @($functionalResults | ForEach-Object id)
$functionalMissingIds = @($functionalRequiredIds | Where-Object { $_ -notin $functionalResultIds })
$functionalUnexpectedFailures = @($functionalResults | Where-Object { $_.status -ne 'PASS' })
$functionalWindowResponsive = $functional.windowResponding -eq $true
$mediaEvidenceIds = @('images-media', 'voice', 'video', 'screen-share')
$mediaEvidenceMissing = @($functionalResults | Where-Object {
        $_.id -in $mediaEvidenceIds -and $_.status -eq 'PASS' -and [string]::IsNullOrWhiteSpace([string]$_.notes)
    } | ForEach-Object id)
$functionalCoverageComplete = $functionalMissingIds.Count -eq 0 -and $functionalResults.Count -eq $functionalRequiredIds.Count
$functionalProcessValid = $functional.processName -eq 'KoroneDiscordShell'
$functionalPassed = ($functional.passed -eq $true) -and $functionalProcessValid -and $functionalCoverageComplete -and $functionalUnexpectedFailures.Count -eq 0 -and $functionalWindowResponsive -and $mediaEvidenceMissing.Count -eq 0
$visualComparisonFields = @('width', 'height', 'differingPixelPercent', 'meanAbsoluteChannelError', 'p95PixelError')
$visualComparisonValid = $null -ne $visual.screenshotComparison -and @($visualComparisonFields | Where-Object { $null -eq $visual.screenshotComparison.$_ }).Count -eq 0 -and [double] $visual.screenshotComparison.width -gt 0 -and [double] $visual.screenshotComparison.height -gt 0
$mediaQualityFields = @('sourceResolutionComparable', 'rasterQualityComparable', 'hardwareAccelerationEnabled', 'visualQualityComparable')
$mediaQualityValid = $null -ne $visual.mediaQuality -and @($mediaQualityFields | Where-Object { $visual.mediaQuality.$_ -ne $true }).Count -eq 0
$mediaQualityProvenanceValid = $visual.mediaQualityProvenance.comparisonTool -eq 'Compare-DiscordMediaQuality.mjs' -and $null -ne $visual.mediaQualityProvenance.source
$visualPassed = ($visual.parityReady -eq $true) -and ($visual.visualReviewPassed -eq $true) -and $visualComparisonValid -and $mediaQualityValid -and $mediaQualityProvenanceValid

$report = [pscustomobject] @{
    schemaVersion = 1
    capturedAt = (Get-Date).ToUniversalTime().ToString('o')
    candidateSummary = (Resolve-Path -LiteralPath $CandidateSummary).Path
    functionalReport = (Resolve-Path -LiteralPath $FunctionalReport).Path
    visualReport = (Resolve-Path -LiteralPath $VisualReport).Path
    resourcePassed = $resourcePassed
    functionalCoverageComplete = $functionalCoverageComplete
    functionalProcessValid = $functionalProcessValid
    functionalWindowResponsive = $functionalWindowResponsive
    mediaEvidenceComplete = $mediaEvidenceMissing.Count -eq 0
    mediaEvidenceMissingIds = @($mediaEvidenceMissing)
    functionalPassed = $functionalPassed
    visualComparisonValid = $visualComparisonValid
    mediaQualityValid = $mediaQualityValid
    mediaQualityProvenanceValid = $mediaQualityProvenanceValid
    visualPassed = $visualPassed
    measurementEvidence = [pscustomobject] @{
        totalWorkingSetMedianMiB = [double] $candidate.workingSetMiB.median
        totalWorkingSetP95MiB = [double] $candidate.workingSetMiB.p95
        privateWorkingSetMedianMiB = [double] $candidate.privateWorkingSetMiB.median
        privateWorkingSetP95MiB = [double] $candidate.privateWorkingSetMiB.p95
        privateBytesMedianMiB = [double] $candidate.privateMemoryMiB.median
        privateBytesP95MiB = [double] $candidate.privateMemoryMiB.p95
        cpuMedianPercentOfTotal = [double] $candidate.cpuPercentOfTotal.medianRun
        cpuP95PercentOfTotal = [double] $candidate.cpuPercentOfTotal.p95Run
        processCountMedian = [double] $candidate.processCount.median
        processCountMaximum = [double] $candidate.processCount.maximum
    }
    resourceMetrics = @($resourceFields | ForEach-Object {
        [pscustomobject] @{ name = $_.name; value = [math]::Round($_.value, 5); limit = $_.limit; passed = ($_.value -le $_.limit) }
    })
    candidateBuildValid = $candidateBuildValid
    passed = $candidateBuildValid -and $resourcePassed -and $functionalPassed -and $visualPassed
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
