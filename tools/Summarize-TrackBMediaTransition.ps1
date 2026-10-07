[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $InputDirectory,

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = (Join-Path (Get-Location) 'track-b-media-transition-summary.json'),

    [switch] $FunctionalPass,

    [switch] $MediaQualityPass
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$directory = (Resolve-Path -LiteralPath $InputDirectory -ErrorAction Stop).Path
$labels = @('static-before', 'media-visible', 'static-after')
$states = [ordered]@{}

function Get-StateValue {
    param([string] $Label)

    $summaryPath = Join-Path $directory "$Label-process-tree-summary.json"
    $memoryPath = Join-Path $directory "$Label-renderer-memory.json"
    if (-not (Test-Path -LiteralPath $summaryPath -PathType Leaf)) { throw "Missing process summary for $Label." }
    if (-not (Test-Path -LiteralPath $memoryPath -PathType Leaf)) { throw "Missing renderer memory map for $Label." }

    $summary = Get-Content -Raw -LiteralPath $summaryPath | ConvertFrom-Json
    $memory = Get-Content -Raw -LiteralPath $memoryPath | ConvertFrom-Json
    $renderer = @($summary.roles | Where-Object role -eq 'renderer' | Select-Object -First 1)
    $gpu = @($summary.roles | Where-Object role -eq 'gpu-process' | Select-Object -First 1)
    if ($renderer.Count -eq 0) { throw "Renderer role is missing from $Label." }

    $marker = Test-Path -LiteralPath (Join-Path $directory "checkpoint-$Label.ready") -PathType Leaf
    $families = @{}
    foreach ($family in @($memory.allocationBaseGroups)) {
        $families[[string]$family.allocationBase] = [double]$family.residentMiB
    }
    [pscustomobject]@{
        label = $Label
        readinessMarker = $marker
        completeTreePrivateWorkingSetMiB = [double]$summary.processTree.privateWorkingSetMedianMiB
        rendererPrivateWorkingSetMiB = [double]$renderer[0].privateWorkingSetMedianMiB
        gpuPrivateWorkingSetMiB = if ($gpu.Count -gt 0) { [double]$gpu[0].privateWorkingSetMedianMiB } else { $null }
        completeTreeCpuMedianPercent = [double]$summary.processTree.cpuMedianPercentOfTotal
        rendererPrivateWritableResidentMiB = [math]::Round([double]$memory.memory.privateWritableResidentBytes / 1MB, 3)
        allocationFamiliesMiB = $families
    }
}

foreach ($label in $labels) { $states[$label] = Get-StateValue -Label $label }
$before = $states['static-before']
$media = $states['media-visible']
$after = $states['static-after']
$allocationFamilyKeys = @(
    @($before.allocationFamiliesMiB.Keys)
    @($media.allocationFamiliesMiB.Keys)
    @($after.allocationFamiliesMiB.Keys)
) | Sort-Object -Unique
$sharedFamilyDeltas = foreach ($base in $allocationFamilyKeys) {
    $beforeMiB = if ($before.allocationFamiliesMiB.ContainsKey($base)) { [double]$before.allocationFamiliesMiB[$base] } else { 0.0 }
    $mediaMiB = if ($media.allocationFamiliesMiB.ContainsKey($base)) { [double]$media.allocationFamiliesMiB[$base] } else { 0.0 }
    $afterMiB = if ($after.allocationFamiliesMiB.ContainsKey($base)) { [double]$after.allocationFamiliesMiB[$base] } else { 0.0 }
    [pscustomobject]@{
        allocationBase = $base
        staticBeforeMiB = $beforeMiB
        mediaVisibleMiB = $mediaMiB
        staticAfterMiB = $afterMiB
        mediaDeltaMiB = [math]::Round($mediaMiB - $beforeMiB, 3)
        returnDeltaMiB = [math]::Round($afterMiB - $beforeMiB, 3)
    }
}
$largestMediaFamily = @($sharedFamilyDeltas | Sort-Object mediaDeltaMiB -Descending | Select-Object -First 1)
$mediaDelta = [pscustomobject]@{
    completeTreePrivateWorkingSetMiB = [math]::Round($media.completeTreePrivateWorkingSetMiB - $before.completeTreePrivateWorkingSetMiB, 3)
    rendererPrivateWorkingSetMiB = [math]::Round($media.rendererPrivateWorkingSetMiB - $before.rendererPrivateWorkingSetMiB, 3)
    gpuPrivateWorkingSetMiB = if ($null -ne $media.gpuPrivateWorkingSetMiB -and $null -ne $before.gpuPrivateWorkingSetMiB) { [math]::Round($media.gpuPrivateWorkingSetMiB - $before.gpuPrivateWorkingSetMiB, 3) } else { $null }
    largestSharedAllocationFamily = if ($largestMediaFamily.Count -gt 0) { $largestMediaFamily[0] } else { $null }
}
$returnDelta = [pscustomobject]@{
    completeTreePrivateWorkingSetMiB = [math]::Round($after.completeTreePrivateWorkingSetMiB - $before.completeTreePrivateWorkingSetMiB, 3)
    rendererPrivateWorkingSetMiB = [math]::Round($after.rendererPrivateWorkingSetMiB - $before.rendererPrivateWorkingSetMiB, 3)
    gpuPrivateWorkingSetMiB = if ($null -ne $after.gpuPrivateWorkingSetMiB -and $null -ne $before.gpuPrivateWorkingSetMiB) { [math]::Round($after.gpuPrivateWorkingSetMiB - $before.gpuPrivateWorkingSetMiB, 3) } else { $null }
    sharedAllocationFamilyDeltas = @($sharedFamilyDeltas)
}
$readinessPassed = @($states.Values | Where-Object { -not $_.readinessMarker }).Count -eq 0
$acceptancePassed = $readinessPassed -and $FunctionalPass -and $MediaQualityPass
$eligibilityReason = if (-not $readinessPassed) {
    'A readiness marker is missing.'
}
elseif (-not $FunctionalPass) {
    'Explicit functional pass evidence was not supplied.'
}
elseif (-not $MediaQualityPass) {
    'Explicit media-quality pass evidence was not supplied.'
}
else {
    'All supplied gates passed; inspect the deltas and repeatability before accepting a production change.'
}

[pscustomobject]@{
    schemaVersion = 1
    result = 'CAPTURE_SUMMARIZED'
    inputDirectory = $directory
    states = $states
    mediaDelta = $mediaDelta
    returnDelta = $returnDelta
    sharedAllocationFamilyDeltas = @($sharedFamilyDeltas)
    readinessPassed = $readinessPassed
    functionalPass = [bool]$FunctionalPass
    mediaQualityPass = [bool]$MediaQualityPass
    optimizationEligible = $acceptancePassed
    eligibilityReason = $eligibilityReason
    policy = 'Aggregate-only summary. It does not identify allocation families as specific subsystems and never accepts a change without readiness, functionality, and media-quality evidence.'
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8

Write-Output "summary=$OutputPath"
