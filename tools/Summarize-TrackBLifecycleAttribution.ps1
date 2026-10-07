[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ManifestPath,

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = (Join-Path (Get-Location) ('artifacts/track-b-lifecycle-summary-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json'))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
$automatic = [string]$manifest.mode -eq 'automatic-unverified'
$rows = foreach ($checkpoint in @($manifest.checkpoints)) {
    $processSummary = Get-Content -Raw -LiteralPath $checkpoint.processSummaryPath | ConvertFrom-Json
    $cdp = Get-Content -Raw -LiteralPath $checkpoint.cdpPath | ConvertFrom-Json
    $renderer = @($processSummary.roles | Where-Object { $_.role -eq 'renderer' } | Select-Object -First 1)[0]
    $heap = $cdp.heapUsage
    $document = $cdp.documentAggregates
    $readiness = if ($cdp.PSObject.Properties.Name -contains 'applicationReadiness') { $cdp.applicationReadiness } else { $null }
    $fullyInitialized = ($checkpoint.PSObject.Properties.Name -contains 'fullyInitializedCheckpoint') -and [bool]$checkpoint.fullyInitializedCheckpoint
    $rendererPidStable = ($checkpoint.PSObject.Properties.Name -contains 'rendererPidStable') -and [bool]$checkpoint.rendererPidStable
    $processCountStable = ($checkpoint.PSObject.Properties.Name -contains 'processCountStable') -and [bool]$checkpoint.processCountStable
    [pscustomobject]@{
        label = [string]$checkpoint.label
        stateClass = if ($fullyInitialized -and $rendererPidStable -and $processCountStable) { 'fully-initialized' } else { 'transition-or-incomplete' }
        fullyInitializedCheckpoint = $fullyInitialized
        rendererPidStable = $rendererPidStable
        processCountStable = $processCountStable
        acceptanceEligible = ($fullyInitialized -and $rendererPidStable -and $processCountStable)
        rendererPid = [int]$checkpoint.rendererPid
        processCountMedian = $processSummary.processTree.processCountMedian
        totalPrivateWorkingSetMedianMiB = $processSummary.processTree.privateWorkingSetMedianMiB
        totalPrivateBytesMedianMiB = $processSummary.processTree.privateMemoryMedianMiB
        totalCpuMedianPercent = $processSummary.processTree.cpuMedianPercentOfTotal
        rendererPrivateWorkingSetMedianMiB = if ($renderer) { $renderer.privateWorkingSetMedianMiB } else { $null }
        rendererPrivateBytesMedianMiB = if ($renderer) { $renderer.privateMemoryMedianMiB } else { $null }
        rendererCpuMedianPercent = if ($renderer) { $renderer.cpuMedianPercentOfTotal } else { $null }
        v8UsedMiB = if ($heap) { [math]::Round(([double]$heap.usedSize / 1MB), 3) } else { $null }
        v8TotalMiB = if ($heap) { [math]::Round(([double]$heap.totalSize / 1MB), 3) } else { $null }
        domNodeCount = if ($document) { $document.domNodeCount } else { $null }
        frameCount = if ($document) { $document.frameCount } else { $null }
        imageElementCount = if ($document) { $document.imageElementCount } else { $null }
        videoElementCount = if ($document) { $document.videoElementCount } else { $null }
        canvasElementCount = if ($document) { $document.canvasElementCount } else { $null }
        applicationReady = if ($readiness) { [bool]$readiness.ready } else { $false }
        applicationReadiness = $readiness
    }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    summarizedAt = (Get-Date).ToUniversalTime().ToString('o')
    sourceManifest = (Resolve-Path -LiteralPath $ManifestPath).Path
    policy = 'Sanitized lifecycle aggregates only. Raw process, CDP, and virtual-memory artifacts remain local/private.'
    rows = @($rows)
    fullyInitializedRowCount = @($rows | Where-Object { $_.acceptanceEligible }).Count
    incompleteOrTransitionRowCount = @($rows | Where-Object { -not $_.acceptanceEligible }).Count
    limitation = if ($automatic) {
        'Automatic timed checkpoints are unverified. Only rows marked fully-initialized have stable renderer identity and process count; they do not prove that Discord reached a valid route or that a workload was held constant.'
    }
    else {
        'Only rows marked fully-initialized have stable renderer identity and process count. Endpoint, loading, session, and shell-transition rows remain diagnostic; manually confirmed rows still do not prove that a single route or workload was held constant unless the operator followed the checkpoint instructions.'
    }
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result
