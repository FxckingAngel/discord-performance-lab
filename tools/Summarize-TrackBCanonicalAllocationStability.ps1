[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string] $InputDirectory,

    [ValidateRange(1, 32)]
    [int] $TopN = 32,

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = (Join-Path (Get-Location) ('artifacts/track-b-canonical-allocation-stability-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json'))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-PropertyValue {
    param(
        [AllowNull()]
        [object] $Object,

        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Get-MiB {
    param([AllowNull()][object] $Bytes)
    if ($null -eq $Bytes) { return $null }
    return [math]::Round(([double] $Bytes / 1MB), 3)
}

function Get-Percentile {
    param(
        [object[]] $Values,
        [double] $Percentile
    )

    $valid = @($Values | Where-Object { $null -ne $_ } | ForEach-Object { [double] $_ } | Sort-Object)
    if ($valid.Count -eq 0) { return $null }
    $index = [math]::Min($valid.Count - 1, [math]::Max(0, [math]::Ceiling($Percentile * $valid.Count) - 1))
    return [math]::Round([double] $valid[$index], 3)
}

function Get-SummaryMetric {
    param(
        [AllowNull()][object] $Summary,
        [Parameter(Mandatory = $true)][string] $Section,
        [Parameter(Mandatory = $true)][string] $Name
    )

    $sectionObject = Get-PropertyValue -Object $Summary -Name $Section
    if ($Section -eq 'roles') {
        $sectionObject = @($sectionObject | Where-Object { $_.role -eq 'renderer' } | Select-Object -First 1)[0]
    }
    return Get-PropertyValue -Object $sectionObject -Name $Name
}

$inputDirectoryResolved = (Resolve-Path -LiteralPath $InputDirectory).Path
$repeatDirectories = @(Get-ChildItem -LiteralPath $inputDirectoryResolved -Directory | Where-Object { $_.Name -match '^repeat-[0-9]+$' } | Sort-Object Name)
if ($repeatDirectories.Count -eq 0) { throw "No repeat-* directories were found under $inputDirectoryResolved." }

$familyIdByKey = @{}
$nextFamilyId = 1
$repeatRows = [System.Collections.Generic.List[object]]::new()
$groupRows = [System.Collections.Generic.List[object]]::new()

foreach ($repeatDirectory in $repeatDirectories) {
    $residentPath = Join-Path $repeatDirectory.FullName 'renderer-resident-types.json'
    if (-not (Test-Path -LiteralPath $residentPath -PathType Leaf)) { throw "Renderer classification is missing: $residentPath" }
    $residentCapture = Get-Content -Raw -LiteralPath $residentPath | ConvertFrom-Json
    $memory = Get-PropertyValue -Object $residentCapture -Name 'memory'
    if ($null -eq $memory) { throw "Renderer classification has no memory object: $residentPath" }
    $rendererPid = [int] (Get-PropertyValue -Object $residentCapture -Name 'processId')
    if ($rendererPid -le 0) { throw "Renderer classification has no valid PID: $residentPath" }

    $summaryPath = Join-Path $repeatDirectory.FullName 'process-tree-summary.json'
    $summary = $null
    if (Test-Path -LiteralPath $summaryPath -PathType Leaf) {
        $summary = Get-Content -Raw -LiteralPath $summaryPath | ConvertFrom-Json
    }

    $groups = @($residentCapture.allocationBaseGroups | Where-Object {
        $residentBytes = Get-PropertyValue -Object $_ -Name 'residentBytes'
        $null -ne $residentBytes -and [double] $residentBytes -gt 0
    } | Sort-Object residentBytes -Descending)
    $limit = [math]::Min($TopN, $groups.Count)
    $topNResidentMiB = 0.0
    for ($rankIndex = 0; $rankIndex -lt $limit; $rankIndex++) {
        $group = $groups[$rankIndex]
        $residentMiB = Get-MiB (Get-PropertyValue -Object $group -Name 'residentBytes')
        $topNResidentMiB += [double] $residentMiB
        $allocationBase = [string] (Get-PropertyValue -Object $group -Name 'allocationBase')
        if ([string]::IsNullOrWhiteSpace($allocationBase)) { throw "Allocation group at rank $($rankIndex + 1) has no allocation base: $residentPath" }
        $familyKey = "$rendererPid|$allocationBase"
        if (-not $familyIdByKey.ContainsKey($familyKey)) {
            $familyIdByKey[$familyKey] = 'family-{0:d3}' -f $nextFamilyId
            $nextFamilyId++
        }
        $groupRows.Add([pscustomobject]@{
            repeat = $repeatDirectory.Name
            rendererPid = $rendererPid
            familyId = [string] $familyIdByKey[$familyKey]
            rank = $rankIndex + 1
            residentMiB = $residentMiB
            committedMiB = Get-MiB (Get-PropertyValue -Object $group -Name 'committedBytes')
            regionCount = [int] (Get-PropertyValue -Object $group -Name 'regionCount')
        })
    }

    $repeatRows.Add([pscustomobject]@{
        repeat = $repeatDirectory.Name
        rendererPid = $rendererPid
        rendererPrivateWritableResidentMiB = Get-MiB (Get-PropertyValue -Object $memory -Name 'privateWritableResidentBytes')
        rendererCommittedPrivateWritableMiB = Get-MiB (Get-PropertyValue -Object $memory -Name 'committedPrivateWritableBytes')
        rendererResidentMiB = Get-MiB (Get-PropertyValue -Object $memory -Name 'residentValidBytes')
        topNResidentMiB = [math]::Round($topNResidentMiB, 3)
        processTreePrivateWorkingSetMedianMiB = Get-SummaryMetric -Summary $summary -Section 'processTree' -Name 'privateWorkingSetMedianMiB'
        processTreePrivateBytesMedianMiB = Get-SummaryMetric -Summary $summary -Section 'processTree' -Name 'privateMemoryMedianMiB'
        rendererPrivateWorkingSetMedianMiB = Get-SummaryMetric -Summary $summary -Section 'roles' -Name 'privateWorkingSetMedianMiB'
        rendererPrivateBytesMedianMiB = Get-SummaryMetric -Summary $summary -Section 'roles' -Name 'privateMemoryMedianMiB'
    })
}

$familyRows = foreach ($familyGroup in @($groupRows | Group-Object familyId)) {
    $observations = @($familyGroup.Group | Sort-Object repeat)
    $residentValues = @($observations | ForEach-Object residentMiB)
    $committedValues = @($observations | ForEach-Object committedMiB)
    $rankValues = @($observations | ForEach-Object rank)
    [pscustomobject]@{
        familyId = [string] $familyGroup.Name
        rendererPid = [int] (@($observations | Select-Object -First 1)[0]).rendererPid
        observedRepeatCount = $observations.Count
        presenceRate = [math]::Round(($observations.Count / $repeatRows.Count), 3)
        residentMinMiB = Get-Percentile $residentValues 0.0
        residentMedianMiB = Get-Percentile $residentValues 0.5
        residentP95MiB = Get-Percentile $residentValues 0.95
        residentMaxMiB = Get-Percentile $residentValues 1.0
        committedMedianMiB = Get-Percentile $committedValues 0.5
        rankMedian = Get-Percentile $rankValues 0.5
        rankMin = Get-Percentile $rankValues 0.0
        rankMax = Get-Percentile $rankValues 1.0
        observations = @($observations | Select-Object repeat,rank,residentMiB,committedMiB,regionCount)
    }
}

$rankRows = foreach ($rankGroup in @($groupRows | Group-Object rank | Sort-Object { [int] $_.Name })) {
    $observations = @($rankGroup.Group)
    [pscustomobject]@{
        rank = [int] $rankGroup.Name
        observedRepeatCount = $observations.Count
        residentMedianMiB = Get-Percentile @($observations | ForEach-Object residentMiB) 0.5
        residentP95MiB = Get-Percentile @($observations | ForEach-Object residentMiB) 0.95
        residentMinMiB = Get-Percentile @($observations | ForEach-Object residentMiB) 0.0
        residentMaxMiB = Get-Percentile @($observations | ForEach-Object residentMiB) 1.0
        committedMedianMiB = Get-Percentile @($observations | ForEach-Object committedMiB) 0.5
    }
}

$rendererPids = @($repeatRows | ForEach-Object rendererPid | Sort-Object -Unique)
$result = [pscustomobject]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    policy = 'Read-only canonical allocation stability summary. Exact allocation-base addresses are used only to correlate groups inside the private input files and are intentionally omitted. Family identity is valid only when the renderer PID is the same; rank rows remain the cross-process fallback.'
    sourceDirectory = $inputDirectoryResolved
    repeatCount = $repeatRows.Count
    rendererPidUniqueCount = $rendererPids.Count
    sameRendererPidAcrossRepeats = ($rendererPids.Count -eq 1)
    topN = $TopN
    repeats = @($repeatRows)
    rankStability = @($rankRows)
    allocationFamilies = @($familyRows | Sort-Object residentMedianMiB -Descending)
    uncertainty = [pscustomobject]@{
        exactFamilyCorrelation = if ($rendererPids.Count -eq 1) { 'Supported within this series because every repetition reports one renderer PID. This does not identify the allocator owner.' } else { 'Not supported across renderer PID changes. Use rank stability only.' }
        topNLimit = "Only the largest $TopN groups captured by the resident classifier are included; groups below that capture limit are not represented."
        attributionBoundary = 'Allocation-base continuity shows lifecycle stability or change, not whether a group belongs to Blink, Skia, V8, WebView2, or Discord application code.'
    }
}

$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result
