[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ManifestPath,

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = (Join-Path (Get-Location) ('artifacts/track-b-renderer-lifecycle-summary-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json'))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-JsonFile {
    param([Parameter(Mandatory = $true)][string] $Path)
    return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
}

function Resolve-ManifestArtifact {
    param(
        [Parameter(Mandatory = $true)][string] $ManifestDirectory,
        [Parameter(Mandatory = $true)][string] $Reference
    )

    $candidates = [System.Collections.Generic.List[string]]::new()
    if ([IO.Path]::IsPathRooted($Reference)) {
        $candidates.Add($Reference)
    }
    else {
        $candidates.Add((Join-Path (Get-Location) $Reference))
        $candidates.Add((Join-Path $ManifestDirectory $Reference))
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    throw "Lifecycle artifact was not found: $Reference"
}

function Get-Median {
    param([double[]] $Values)
    $ordered = @($Values | Sort-Object)
    if ($ordered.Count -eq 0) { return $null }
    $middle = [int][math]::Floor($ordered.Count / 2)
    if (($ordered.Count % 2) -eq 1) { return [double]$ordered[$middle] }
    return ([double]$ordered[$middle - 1] + [double]$ordered[$middle]) / 2
}

function Get-Number {
    param([object] $Object, [string] $Name)
    if ($null -eq $Object -or -not ($Object.PSObject.Properties.Name -contains $Name)) { return $null }
    if ($null -eq $Object.$Name) { return $null }
    return [double]$Object.$Name
}

function To-MiB {
    param([object] $Bytes)
    if ($null -eq $Bytes) { return $null }
    return [math]::Round(([double]$Bytes / 1MB), 3)
}

function Read-Stage {
    param(
        [Parameter(Mandatory = $true)][object] $Stage,
        [Parameter(Mandatory = $true)][string] $ManifestDirectory,
        [Parameter(Mandatory = $true)][int] $Index
    )

    foreach ($field in @('label', 'rendererPid', 'regionPath', 'processPath', 'cdpPath')) {
        if (-not ($Stage.PSObject.Properties.Name -contains $field)) {
            throw "Lifecycle stage $Index is missing '$field'."
        }
    }
    $regionPath = Resolve-ManifestArtifact $ManifestDirectory ([string]$Stage.regionPath)
    $processPath = Resolve-ManifestArtifact $ManifestDirectory ([string]$Stage.processPath)
    $cdpPath = Resolve-ManifestArtifact $ManifestDirectory ([string]$Stage.cdpPath)
    $region = Read-JsonFile $regionPath
    $processCapture = Read-JsonFile $processPath
    $cdp = Read-JsonFile $cdpPath

    $rendererRows = @($processCapture.samples | ForEach-Object {
        @($_.processes | Where-Object { $_.role -eq 'renderer' -and $null -ne $_.pid })
    })
    $rendererPids = @($rendererRows | ForEach-Object { [int]$_.pid } | Sort-Object -Unique)
    if ($rendererPids.Count -ne 1 -or $rendererPids[0] -ne [int]$Stage.rendererPid) {
        throw "Stage '$($Stage.label)' does not have one renderer matching rendererPid $($Stage.rendererPid)."
    }

    $treePrivateWorkingSet = @($processCapture.samples | ForEach-Object {
        $values = @($_.processes | Where-Object { $null -ne $_.privateWorkingSetMiB } | ForEach-Object { [double]$_.privateWorkingSetMiB })
        if ($values.Count -gt 0) { [double](($values | Measure-Object -Sum).Sum) }
    })
    $treePrivateBytes = @($processCapture.samples | ForEach-Object {
        $values = @($_.processes | Where-Object { $null -ne $_.privateMemoryMiB } | ForEach-Object { [double]$_.privateMemoryMiB })
        if ($values.Count -gt 0) { [double](($values | Measure-Object -Sum).Sum) }
    })
    $rendererPrivateWorkingSet = @($rendererRows | ForEach-Object { [double]$_.privateWorkingSetMiB })
    $rendererPrivateBytes = @($rendererRows | ForEach-Object { [double]$_.privateMemoryMiB })
    $families = @($region.allocationBaseGroups | Sort-Object residentBytes -Descending)
    $topThreeResidentMiB = [math]::Round((@($families | Select-Object -First 3 | ForEach-Object { [double]$_.residentBytes } | Measure-Object -Sum).Sum / 1MB), 3)
    $heap = $cdp.heapUsage
    $documents = $cdp.domCounters
    $aggregate = $cdp.documentAggregates

    [pscustomobject]@{
        label = [string]$Stage.label
        rendererPid = [int]$Stage.rendererPid
        processCount = [int]$processCapture.samples[-1].processCount
        processSampleCount = @($processCapture.samples).Count
        treePrivateWorkingSetMedianMiB = [math]::Round((Get-Median $treePrivateWorkingSet), 3)
        treePrivateBytesMedianMiB = [math]::Round((Get-Median $treePrivateBytes), 3)
        rendererPrivateWorkingSetMedianMiB = [math]::Round((Get-Median $rendererPrivateWorkingSet), 3)
        rendererPrivateBytesMedianMiB = [math]::Round((Get-Median $rendererPrivateBytes), 3)
        rendererPrivateWritableResidentMiB = To-MiB $region.memory.privateWritableResidentBytes
        rendererResidentMiB = To-MiB $region.memory.residentValidBytes
        rendererCommittedPrivateWritableMiB = To-MiB $region.memory.committedPrivateWritableBytes
        rendererTopThreeAllocationFamiliesResidentMiB = $topThreeResidentMiB
        rendererAllocationFamilyCount = @($families).Count
        v8UsedMiB = To-MiB (Get-Number $heap 'usedSize')
        v8BackingStorageMiB = To-MiB (Get-Number $heap 'backingStorageSize')
        documents = Get-Number $documents 'documents'
        domNodes = Get-Number $documents 'nodes'
        imageElements = Get-Number $aggregate 'imageElementCount'
        videoElements = Get-Number $aggregate 'videoElementCount'
        canvasElements = Get-Number $aggregate 'canvasElementCount'
    }
}

$manifestPathResolved = (Resolve-Path -LiteralPath $ManifestPath).Path
$manifestDirectory = Split-Path -Parent $manifestPathResolved
$manifest = Read-JsonFile $manifestPathResolved
if (-not ($manifest.PSObject.Properties.Name -contains 'stages')) { throw 'Lifecycle manifest does not contain stages.' }
$stages = @($manifest.stages)
if ($stages.Count -lt 3) { throw "Lifecycle manifest has $($stages.Count) stages; at least three are required." }

$rows = for ($index = 0; $index -lt $stages.Count; $index++) {
    Read-Stage -Stage $stages[$index] -ManifestDirectory $manifestDirectory -Index ($index + 1)
}
$rendererPids = @($rows.rendererPid | Sort-Object -Unique)
$requiredLabels = @('startup-5s', 'frontend-15s', 'friends-40s')
$missingLabels = @($requiredLabels | Where-Object { $_ -notin @($rows.label) })
if ($missingLabels.Count -gt 0) { throw "Lifecycle manifest is missing required stages: $($missingLabels -join ', ')." }

$startup = @($rows | Where-Object label -eq 'startup-5s' | Select-Object -First 1)[0]
$frontend = @($rows | Where-Object label -eq 'frontend-15s' | Select-Object -First 1)[0]
$friends = @($rows | Where-Object label -eq 'friends-40s' | Select-Object -First 1)[0]
$frontendDelta = [math]::Round($frontend.rendererPrivateWritableResidentMiB - $startup.rendererPrivateWritableResidentMiB, 3)
$friendsDelta = [math]::Round($friends.rendererPrivateWritableResidentMiB - $startup.rendererPrivateWritableResidentMiB, 3)
$friendsTopThreeDelta = [math]::Round($friends.rendererTopThreeAllocationFamiliesResidentMiB - $startup.rendererTopThreeAllocationFamiliesResidentMiB, 3)

$result = [pscustomobject]@{
    schemaVersion = 1
    result = 'CAPTURED'
    summarizedAt = (Get-Date).ToUniversalTime().ToString('o')
    sourceManifest = Split-Path -Leaf $manifestPathResolved
    policy = 'Sanitized lifecycle summary. Renderer PIDs, allocation addresses, command lines, page content, URLs, cookies, tokens, and heap objects are not written.'
    gates = [pscustomobject]@{
        requiredStagesPresent = ($missingLabels.Count -eq 0)
        rendererPidStable = ($rendererPids.Count -eq 1)
        rendererPid = if ($rendererPids.Count -eq 1) { $rendererPids[0] } else { $null }
        stageCount = $rows.Count
        passed = ($missingLabels.Count -eq 0 -and $rendererPids.Count -eq 1)
    }
    stages = @($rows)
    deltas = [pscustomobject]@{
        startupToFrontendPrivateWritableResidentMiB = $frontendDelta
        startupToFriendsPrivateWritableResidentMiB = $friendsDelta
        startupToFriendsTopThreeFamilyResidentMiB = $friendsTopThreeDelta
    }
    interpretation = [pscustomobject]@{
        loadedState = if ($friendsDelta -ge 15) { 'likely-discord-loaded-private-state' } else { 'no-material-loaded-state-delta' }
        fixedWebView2Floor = 'not-evaluable-from-startup-only-lifecycle; requires an about:blank checkpoint in the same renderer'
        allocationOwnership = 'unresolved; allocation-base families are size evidence only'
        optimizationDecision = 'no-renderer-change-authorized'
    }
}

$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result | Select-Object result,gates,deltas,interpretation
