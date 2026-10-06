[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $CdpInputPath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $RoleSummaryPath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath
)

$cdp = Get-Content -Raw -LiteralPath $CdpInputPath | ConvertFrom-Json
$roles = Get-Content -Raw -LiteralPath $RoleSummaryPath | ConvertFrom-Json
$renderer = @($roles.roles | Where-Object role -eq 'renderer' | Select-Object -First 1)
if ($renderer.Count -eq 0) { throw 'The role summary does not contain a renderer row.' }
if (-not $cdp.heapUsage.usedSize) { throw 'The CDP capture does not contain Runtime.getHeapUsage data.' }
$rendererAttribution = @($roles.processes | Where-Object role -eq 'renderer' | ForEach-Object {
    [pscustomobject]@{
        pid = $_.pid
        parentPid = $_.parentPid
        samples = $_.samples
        lifetimeSecondsMedian = $_.lifetimeSecondsMedian
        privateWorkingSetMedianMiB = $_.privateWorkingSetMedianMiB
        privateWorkingSetP95MiB = $_.privateWorkingSetP95MiB
        privateMemoryMedianMiB = $_.privateMemoryMedianMiB
        privateMemoryP95MiB = $_.privateMemoryP95MiB
        cpuMedianPercentOfTotal = $_.cpuMedianPercentOfTotal
        cpuP95PercentOfTotal = $_.cpuP95PercentOfTotal
        pageFaultsMedianPerSecond = $_.pageFaultsMedianPerSecond
        pageFaultsP95PerSecond = $_.pageFaultsP95PerSecond
        handlesMedian = $_.handlesMedian
        threadsMedian = $_.threadsMedian
    }
})

$v8UsedMiB = [math]::Round([double] $cdp.heapUsage.usedSize / 1MB, 3)
$v8TotalMiB = [math]::Round([double] $cdp.heapUsage.totalSize / 1MB, 3)
$rendererPrivateWorkingMiB = [double] $renderer.privateWorkingSetMedianMiB
$rendererPrivateBytesMiB = [double] $renderer.privateMemoryMedianMiB
$residualMiB = [math]::Round([math]::Max(0, $rendererPrivateWorkingMiB - $v8UsedMiB), 3)
$gpu = @($roles.roles | Where-Object role -eq 'gpu-process' | Select-Object -First 1)
$gpuPrivateWorkingMiB = if ($gpu.Count -gt 0) { [math]::Round([double] $gpu.privateWorkingSetMedianMiB, 3) } else { $null }
$gpuPrivateBytesMiB = if ($gpu.Count -gt 0) { [math]::Round([double] $gpu.privateMemoryMedianMiB, 3) } else { $null }
$nativeCategories = if ($cdp.nativeMemorySamplingWindow -and $cdp.nativeMemorySamplingWindow.nativeAllocationCategories) {
    @($cdp.nativeMemorySamplingWindow.nativeAllocationCategories | ForEach-Object {
        [pscustomobject]@{
            category = [string] $_.category
            sampledMiB = [math]::Round([double] $_.sampledBytes / 1MB, 3)
            sampleCount = [int] $_.sampleCount
        }
    })
} else {
    $null
}
$domCounters = if ($cdp.domCounters -and -not $cdp.domCounters.error) {
    [pscustomobject]@{
        documents = $cdp.domCounters.documents
        nodes = $cdp.domCounters.nodes
        jsEventListeners = $cdp.domCounters.jsEventListeners
    }
} else { $null }
$buckets = @(
    [pscustomobject]@{ bucket = 'V8 JavaScript heap'; measuredMiB = $v8UsedMiB; evidence = 'Runtime.getHeapUsage.usedSize'; interpretation = 'Measured live V8 heap only.' }
    [pscustomobject]@{ bucket = 'Renderer private working set'; measuredMiB = [math]::Round($rendererPrivateWorkingMiB, 3); evidence = 'Rooted process attribution median'; interpretation = 'Primary renderer resident-memory KPI; not equivalent to JavaScript heap.' }
    [pscustomobject]@{ bucket = 'Renderer private bytes'; measuredMiB = [math]::Round($rendererPrivateBytesMiB, 3); evidence = 'Rooted process attribution median'; interpretation = 'Committed private memory; reported separately from resident memory.' }
    [pscustomobject]@{ bucket = 'Non-V8 renderer residual lower bound'; measuredMiB = $residualMiB; evidence = 'Renderer private median minus V8 used heap'; interpretation = 'May include Blink, native Chromium, decoded media, shared buffers, and other allocations. Not independently attributed.' }
    [pscustomobject]@{ bucket = 'GPU private working set'; measuredMiB = $gpuPrivateWorkingMiB; evidence = 'Rooted process attribution median'; interpretation = 'GPU resident-memory KPI; shared texture ownership still needs GPU counters.' }
    [pscustomobject]@{ bucket = 'GPU private bytes'; measuredMiB = $gpuPrivateBytesMiB; evidence = 'Rooted process attribution median'; interpretation = 'GPU committed private memory; reported separately from resident memory.' }
)
$result = [pscustomobject]@{
    schemaVersion = 1
    cdpSource = $CdpInputPath
    roleSummarySource = $RoleSummaryPath
    scenario = $roles.scenario
    rootPid = $roles.rootPid
    cdpCapturedAt = $cdp.capturedAt
    v8HeapCapacityMiB = $v8TotalMiB
    rendererCount = $rendererAttribution.Count
    rendererAttribution = $rendererAttribution
    buckets = $buckets
    nativeAllocationCategories = $nativeCategories
    domCounters = $domCounters
    privacy = 'Sanitized aggregate only. No heap objects, function names, URLs, message contents, tokens, or snapshots are included.'
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result
