[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ProcessTreePath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $CdpPath,

    [string] $OutputPath
)

function Convert-ToMiB {
    param([double] $Bytes)
    [math]::Round($Bytes / 1MB, 2)
}

if (-not (Test-Path -LiteralPath $ProcessTreePath -PathType Leaf)) {
    throw "Process-tree file not found: $ProcessTreePath"
}
if (-not (Test-Path -LiteralPath $CdpPath -PathType Leaf)) {
    throw "CDP file not found: $CdpPath"
}

$tree = Get-Content -LiteralPath $ProcessTreePath -Raw | ConvertFrom-Json
$cdp = Get-Content -LiteralPath $CdpPath -Raw | ConvertFrom-Json
$lastSample = @($tree.samples)[-1]
$processes = @($lastSample.processes)
$renderer = @($processes | Where-Object { $_.role -eq 'renderer' })
$gpu = @($processes | Where-Object { $_.role -eq 'gpu-process' })
$rendererPrivateBytes = [double] (($renderer | Measure-Object privateBytes -Sum).Sum)
$rendererWorkingSetPrivateBytes = [double] (($renderer | Measure-Object workingSetPrivateBytes -Sum).Sum)
$v8UsedBytes = [double] $cdp.heapUsage.usedSize

$report = [pscustomobject] @{
    schemaVersion = 1
    processTreePath = $ProcessTreePath
    cdpPath = $CdpPath
    scenario = $tree.scenario
    capturedAt = $cdp.capturedAt
    processCount = $lastSample.processCount
    totalWorkingSetMiB = Convert-ToMiB $lastSample.workingSetBytes
    totalPrivateBytesMiB = Convert-ToMiB $lastSample.privateBytes
    rendererCount = $renderer.Count
    rendererWorkingSetPrivateMiB = Convert-ToMiB $rendererWorkingSetPrivateBytes
    rendererPrivateBytesMiB = Convert-ToMiB $rendererPrivateBytes
    rendererV8UsedMiB = Convert-ToMiB $v8UsedBytes
    rendererPrivateBeyondV8LowerBoundMiB = Convert-ToMiB ([math]::Max(0, $rendererPrivateBytes - $v8UsedBytes))
    gpuPrivateBytesMiB = Convert-ToMiB ([double] (($gpu | Measure-Object privateBytes -Sum).Sum))
    gpuWorkingSetPrivateMiB = Convert-ToMiB ([double] (($gpu | Measure-Object workingSetPrivateBytes -Sum).Sum))
    domNodeCount = $cdp.documentAggregates.domNodeCount
    frameCount = $cdp.performanceMetrics.Frames
    javascriptEventListenerCount = $cdp.performanceMetrics.JSEventListeners
    layoutObjectCount = $cdp.performanceMetrics.LayoutObjects
    imageElementCount = $cdp.documentAggregates.imageElementCount
    videoElementCount = $cdp.documentAggregates.videoElementCount
    canvasElementCount = $cdp.documentAggregates.canvasElementCount
    activeRtcPeerConnections = $cdp.performanceMetrics.RTCPeerConnections
}

if ($OutputPath) {
    $parent = Split-Path -Parent $OutputPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $OutputPath -Encoding utf8
}

$report | ConvertTo-Json -Depth 5
