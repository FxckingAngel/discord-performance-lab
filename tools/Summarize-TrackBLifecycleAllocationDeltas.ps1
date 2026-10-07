[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ManifestPath,

    [ValidateRange(1, 100)]
    [int] $TopN = 10,

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = (Join-Path (Get-Location) ('artifacts/track-b-lifecycle-allocation-summary-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json'))
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

function Resolve-InputPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $Description
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Description was not found: $Path"
    }
    return (Resolve-Path -LiteralPath $Path).Path
}

function Get-MiB {
    param([AllowNull()][object] $Bytes)
    if ($null -eq $Bytes) { return $null }
    return [math]::Round(([double] $Bytes / 1MB), 3)
}

function Get-RendererSummary {
    param([AllowNull()][object] $Summary)
    if ($null -eq $Summary) { return $null }
    return @($Summary.roles | Where-Object { $_.role -eq 'renderer' } | Select-Object -First 1)[0]
}

function Get-V8UsedMiB {
    param([AllowNull()][object] $Cdp)
    $heap = Get-PropertyValue -Object $Cdp -Name 'heapUsage'
    return Get-MiB (Get-PropertyValue -Object $heap -Name 'usedSize')
}

$manifestPathResolved = (Resolve-Path -LiteralPath $ManifestPath).Path
$manifest = Get-Content -Raw -LiteralPath $manifestPathResolved | ConvertFrom-Json
$checkpoints = @($manifest.checkpoints)
if ($checkpoints.Count -eq 0) { throw 'The lifecycle manifest contains no checkpoints.' }

$rendererInstanceByPid = @{}
$nextRendererInstance = 1
$familyIdByKey = @{}
$nextFamilyId = 1
$checkpointRows = [System.Collections.Generic.List[object]]::new()
$groupRows = [System.Collections.Generic.List[object]]::new()

for ($checkpointIndex = 0; $checkpointIndex -lt $checkpoints.Count; $checkpointIndex++) {
    $checkpoint = $checkpoints[$checkpointIndex]
    $label = [string] (Get-PropertyValue -Object $checkpoint -Name 'label')
    if ([string]::IsNullOrWhiteSpace($label)) { throw "Checkpoint $checkpointIndex has no label." }

    $rendererPid = [int] (Get-PropertyValue -Object $checkpoint -Name 'rendererPid')
    if ($rendererPid -le 0) { throw "Checkpoint '$label' has no renderer PID." }
    $memoryPath = Resolve-InputPath -Path ([string] (Get-PropertyValue -Object $checkpoint -Name 'rendererMemoryTypesPath')) -Description "Renderer memory classification for '$label'"
    $memoryCapture = Get-Content -Raw -LiteralPath $memoryPath | ConvertFrom-Json
    $memory = Get-PropertyValue -Object $memoryCapture -Name 'memory'
    if ($null -eq $memory) { throw "Renderer memory classification for '$label' has no memory object." }

    $pidKey = [string] $rendererPid
    if (-not $rendererInstanceByPid.ContainsKey($pidKey)) {
        $rendererInstanceByPid[$pidKey] = 'renderer-{0:d2}' -f $nextRendererInstance
        $nextRendererInstance++
    }
    $rendererInstance = [string] $rendererInstanceByPid[$pidKey]

    $processSummary = $null
    $processSummaryPath = [string] (Get-PropertyValue -Object $checkpoint -Name 'processSummaryPath')
    if (-not [string]::IsNullOrWhiteSpace($processSummaryPath) -and (Test-Path -LiteralPath $processSummaryPath -PathType Leaf)) {
        $processSummary = Get-Content -Raw -LiteralPath $processSummaryPath | ConvertFrom-Json
    }
    $rendererSummary = Get-RendererSummary -Summary $processSummary

    $cdp = $null
    $cdpPath = [string] (Get-PropertyValue -Object $checkpoint -Name 'cdpPath')
    if (-not [string]::IsNullOrWhiteSpace($cdpPath) -and (Test-Path -LiteralPath $cdpPath -PathType Leaf)) {
        $cdp = Get-Content -Raw -LiteralPath $cdpPath | ConvertFrom-Json
    }

    $checkpointRows.Add([pscustomobject]@{
        checkpointIndex = $checkpointIndex
        label = $label
        rendererInstance = $rendererInstance
        rendererPid = $rendererPid
        rendererPidStable = [bool] (Get-PropertyValue -Object $checkpoint -Name 'rendererPidStable')
        processCountStable = [bool] (Get-PropertyValue -Object $checkpoint -Name 'processCountStable')
        processCount = Get-PropertyValue -Object $checkpoint -Name 'processCount'
        fullyInitializedCheckpoint = [bool] (Get-PropertyValue -Object $checkpoint -Name 'fullyInitializedCheckpoint')
        rendererPrivateWorkingSetMedianMiB = Get-PropertyValue -Object $rendererSummary -Name 'privateWorkingSetMedianMiB'
        rendererPrivateBytesMedianMiB = Get-PropertyValue -Object $rendererSummary -Name 'privateMemoryMedianMiB'
        rendererPrivateWritableResidentMiB = Get-MiB (Get-PropertyValue -Object $memory -Name 'privateWritableResidentBytes')
        rendererCommittedPrivateWritableMiB = Get-MiB (Get-PropertyValue -Object $memory -Name 'committedPrivateWritableBytes')
        v8UsedMiB = Get-V8UsedMiB -Cdp $cdp
        allocationGroupCount = @($memoryCapture.allocationBaseGroups).Count
    })

    $groups = @($memoryCapture.allocationBaseGroups | Where-Object {
        $residentBytes = Get-PropertyValue -Object $_ -Name 'residentBytes'
        $null -ne $residentBytes -and [double] $residentBytes -gt 0
    } | Sort-Object residentBytes -Descending)
    $limit = [math]::Min($TopN, $groups.Count)
    for ($rankIndex = 0; $rankIndex -lt $limit; $rankIndex++) {
        $group = $groups[$rankIndex]
        $allocationBase = [string] (Get-PropertyValue -Object $group -Name 'allocationBase')
        if ([string]::IsNullOrWhiteSpace($allocationBase)) { throw "Checkpoint '$label' contains an allocation group without an allocation base." }
        $familyKey = "$rendererInstance|$allocationBase"
        if (-not $familyIdByKey.ContainsKey($familyKey)) {
            $familyIdByKey[$familyKey] = 'family-{0:d3}' -f $nextFamilyId
            $nextFamilyId++
        }
        $groupRows.Add([pscustomobject]@{
            checkpointIndex = $checkpointIndex
            label = $label
            rendererInstance = $rendererInstance
            familyId = [string] $familyIdByKey[$familyKey]
            rank = $rankIndex + 1
            residentMiB = Get-MiB (Get-PropertyValue -Object $group -Name 'residentBytes')
            committedMiB = Get-MiB (Get-PropertyValue -Object $group -Name 'committedBytes')
            regionCount = [int] (Get-PropertyValue -Object $group -Name 'regionCount')
        })
    }
}

$familyRows = foreach ($familyGroup in @($groupRows | Group-Object familyId)) {
    $observations = @($familyGroup.Group | Sort-Object checkpointIndex)
    $first = $observations | Select-Object -First 1
    $last = $observations | Select-Object -Last 1
    $peak = $observations | Sort-Object residentMiB -Descending | Select-Object -First 1
    [pscustomobject]@{
        familyId = [string] $familyGroup.Name
        rendererInstance = [string] $first.rendererInstance
        firstCheckpoint = [string] $first.label
        lastCheckpoint = [string] $last.label
        observedCheckpointCount = $observations.Count
        peakResidentMiB = [double] $peak.residentMiB
        peakCommittedMiB = [double] (@($observations | Sort-Object committedMiB -Descending | Select-Object -First 1)[0]).committedMiB
        firstResidentMiB = [double] $first.residentMiB
        lastResidentMiB = [double] $last.residentMiB
        deltaFirstToLastMiB = [math]::Round(([double] $last.residentMiB - [double] $first.residentMiB), 3)
        observations = @($observations | Select-Object checkpointIndex,label,rank,residentMiB,committedMiB,regionCount)
    }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    policy = 'Sanitized lifecycle allocation aggregates. Exact allocation-base addresses are used only while reading the private capture and are intentionally omitted from this output. Exact family identity is asserted only within one renderer PID; observations across renderer PID changes remain separate instances and are rank-comparable only.'
    sourceManifest = $manifestPathResolved
    checkpointCount = $checkpointRows.Count
    rendererInstanceCount = @($checkpointRows | Select-Object -ExpandProperty rendererInstance -Unique).Count
    checkpoints = @($checkpointRows)
    topAllocationGroups = @($groupRows)
    allocationFamilies = @($familyRows | Sort-Object peakResidentMiB -Descending)
}

$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result
