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
    [pscustomobject]@{
        label = [string]$checkpoint.label
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
    }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    summarizedAt = (Get-Date).ToUniversalTime().ToString('o')
    sourceManifest = (Resolve-Path -LiteralPath $ManifestPath).Path
    policy = 'Sanitized lifecycle aggregates only. Raw process, CDP, and virtual-memory artifacts remain local/private.'
    rows = @($rows)
    limitation = if ($automatic) {
        'Automatic timed checkpoints are unverified. They do not prove that Discord reached a fully initialized route or that a workload was held constant.'
    }
    else {
        'Checkpoint values describe the manually confirmed state at each label. They do not prove that a single route or workload was held constant unless the operator followed the checkpoint instructions.'
    }
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result
