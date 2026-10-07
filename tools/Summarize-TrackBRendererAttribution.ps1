[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ProcessTreePath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $CdpPath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath
)

function Get-Percentile {
    param([object[]] $Values, [double] $Percentile)

    $valid = @($Values | Where-Object { $_ -ne $null } | ForEach-Object { [double] $_ } | Sort-Object)
    if ($valid.Count -eq 0) { return $null }
    $index = [math]::Min($valid.Count - 1, [math]::Max(0, [math]::Ceiling($Percentile * $valid.Count) - 1))
    return [math]::Round([double] $valid[$index], 3)
}

function Convert-ToMiB {
    param([object] $Bytes)

    if ($null -eq $Bytes) { return $null }
    return [math]::Round(([double] $Bytes / 1MB), 3)
}

$tree = Get-Content -LiteralPath $ProcessTreePath -Raw | ConvertFrom-Json
$cdp = Get-Content -LiteralPath $CdpPath -Raw | ConvertFrom-Json
$rendererRows = foreach ($sample in @($tree.samples)) {
    foreach ($process in @($sample.processes | Where-Object { $_.role -eq 'renderer' -and $_.status -ne 'unavailable' })) {
        [pscustomobject]@{
            pid = [int] $process.pid
            privateWorkingSetMiB = [double] $process.privateWorkingSetMiB
            workingSetMiB = [double] $process.workingSetMiB
            privateBytesMiB = [double] $process.privateMemoryMiB
            cpuPercentOfTotal = $process.cpuPercentOfTotal
            pageFaultsPerSecond = $process.pageFaultsPerSecond
        }
    }
}

$rendererPids = @($rendererRows | Select-Object -ExpandProperty pid -Unique)
$native = $cdp.nativeMemorySamplingWindow
if ($null -eq $native) { $native = $cdp.nativeMemorySampling }
$result = [pscustomobject]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    policy = 'Aggregate renderer attribution only. Native samples are not resident-memory totals. No page text, URLs, cookies, tokens, heap objects, addresses, or raw stacks are copied.'
    processTreeSource = (Resolve-Path -LiteralPath $ProcessTreePath).Path
    cdpSource = (Resolve-Path -LiteralPath $CdpPath).Path
    renderer = [pscustomobject]@{
        processCount = $rendererPids.Count
        pids = $rendererPids
        privateWorkingSetMedianMiB = Get-Percentile @($rendererRows.privateWorkingSetMiB) 0.50
        privateWorkingSetP95MiB = Get-Percentile @($rendererRows.privateWorkingSetMiB) 0.95
        workingSetMedianMiB = Get-Percentile @($rendererRows.workingSetMiB) 0.50
        privateBytesMedianMiB = Get-Percentile @($rendererRows.privateBytesMiB) 0.50
        cpuMedianPercentOfTotal = Get-Percentile @($rendererRows.cpuPercentOfTotal) 0.50
        pageFaultsMedianPerSecond = Get-Percentile @($rendererRows.pageFaultsPerSecond) 0.50
    }
    v8 = [pscustomobject]@{
        usedMiB = Convert-ToMiB $cdp.heapUsage.usedSize
        totalMiB = Convert-ToMiB $cdp.heapUsage.totalSize
        embedderHeapUsedMiB = Convert-ToMiB $cdp.heapUsage.embedderHeapUsedSize
        backingStorageMiB = Convert-ToMiB $cdp.heapUsage.backingStorageSize
    }
    blink = [pscustomobject]@{
        documents = $cdp.domCounters.documents
        domNodes = $cdp.domCounters.nodes
        jsEventListeners = $cdp.domCounters.jsEventListeners
        frames = $cdp.documentAggregates.frameCount
        imageElements = $cdp.documentAggregates.imageElementCount
        imageNaturalPixels = $cdp.documentAggregates.imageNaturalPixelCount
        videoElements = $cdp.documentAggregates.videoElementCount
        canvasElements = $cdp.documentAggregates.canvasElementCount
        canvasPixels = $cdp.documentAggregates.canvasPixelCount
    }
    nativeSampling = [pscustomobject]@{
        sourceMethod = $native.sourceMethod
        sampleCount = $native.sampleCount
        sampledMiB = Convert-ToMiB $native.sampledBytes
        attributedMiB = Convert-ToMiB $native.attributedBytes
        categories = @($native.nativeAllocationCategories | ForEach-Object {
            [pscustomobject]@{
                category = $_.category
                sampleCount = $_.sampleCount
                sampledMiB = Convert-ToMiB $_.sampledBytes
            }
        })
        modules = @($native.nativeAllocationModules | ForEach-Object {
            [pscustomobject]@{
                module = $_.module
                sampleCount = $_.sampleCount
                sampledMiB = Convert-ToMiB $_.sampledBytes
            }
        })
    }
}

$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result | ConvertTo-Json -Depth 8
