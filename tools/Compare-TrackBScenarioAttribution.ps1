[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $BaselineCdpPath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $CandidateCdpPath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $BaselineRoleSummaryPath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $CandidateRoleSummaryPath,

    [string] $OutputPath
)

function Read-JsonFile {
    param([string] $Path)
    return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Get-RoleRow {
    param([object] $Summary, [string] $Role)
    return @($Summary.roles | Where-Object role -eq $Role | Select-Object -First 1)[0]
}

function Get-NullableDouble {
    param([object] $Value)
    if ($null -eq $Value) { return $null }
    return [double] $Value
}

function Get-NativeCategoryMiB {
    param([object] $Cdp, [string] $Category)
    $rows = @($Cdp.nativeMemorySamplingWindow.nativeAllocationCategories | Where-Object category -eq $Category | Select-Object -First 1)
    if ($rows.Count -eq 0 -or $null -eq $rows[0].sampledBytes) { return $null }
    return [math]::Round([double] $rows[0].sampledBytes / 1MB, 3)
}

function Get-DomCounter {
    param([object] $Cdp, [string] $Name)
    if ($null -eq $Cdp.domCounters -or $null -eq $Cdp.domCounters.$Name) { return $null }
    return [double] $Cdp.domCounters.$Name
}

function Get-MetricValue {
    param([object] $Cdp, [object] $Summary, [string] $Metric)
    switch ($Metric) {
        'processTree.privateWorkingSetMedianMiB' { return [double] $Summary.processTree.privateWorkingSetMedianMiB }
        'processTree.privateWorkingSetP95MiB' { return [double] $Summary.processTree.privateWorkingSetP95MiB }
        'processTree.privateMemoryMedianMiB' { return [double] $Summary.processTree.privateMemoryMedianMiB }
        'processTree.privateMemoryP95MiB' { return [double] $Summary.processTree.privateMemoryP95MiB }
        'renderer.privateWorkingSetMedianMiB' { return [double] (Get-RoleRow -Summary $Summary -Role 'renderer').privateWorkingSetMedianMiB }
        'renderer.privateMemoryMedianMiB' { return [double] (Get-RoleRow -Summary $Summary -Role 'renderer').privateMemoryMedianMiB }
        'v8.usedMiB' { return [math]::Round([double] $Cdp.heapUsage.usedSize / 1MB, 3) }
        'v8.capacityMiB' { return [math]::Round([double] $Cdp.heapUsage.totalSize / 1MB, 3) }
        'media.imageNaturalPixelCount' { return Get-NullableDouble -Value $Cdp.documentAggregates.imageNaturalPixelCount }
        'media.videoPixelCount' { return Get-NullableDouble -Value $Cdp.documentAggregates.videoPixelCount }
        'media.canvasPixelCount' { return Get-NullableDouble -Value $Cdp.documentAggregates.canvasPixelCount }
        'native.image-media.sampledMiB' { return Get-NativeCategoryMiB -Cdp $Cdp -Category 'image-media' }
        'native.gpu-graphics.sampledMiB' { return Get-NativeCategoryMiB -Cdp $Cdp -Category 'gpu-graphics' }
        'native.media-webrtc.sampledMiB' { return Get-NativeCategoryMiB -Cdp $Cdp -Category 'media-webrtc' }
        'native.blink.sampledMiB' { return Get-NativeCategoryMiB -Cdp $Cdp -Category 'blink' }
        'native.network-cache.sampledMiB' { return Get-NativeCategoryMiB -Cdp $Cdp -Category 'network-cache' }
        'dom.documents' { return Get-DomCounter -Cdp $Cdp -Name 'documents' }
        'dom.nodes' { return Get-DomCounter -Cdp $Cdp -Name 'nodes' }
        'dom.jsEventListeners' { return Get-DomCounter -Cdp $Cdp -Name 'jsEventListeners' }
        default { throw "Unknown attribution metric: $Metric" }
    }
}

$baselineCdp = Read-JsonFile -Path $BaselineCdpPath
$candidateCdp = Read-JsonFile -Path $CandidateCdpPath
$baselineSummary = Read-JsonFile -Path $BaselineRoleSummaryPath
$candidateSummary = Read-JsonFile -Path $CandidateRoleSummaryPath
$metricNames = @(
    'processTree.privateWorkingSetMedianMiB',
    'processTree.privateWorkingSetP95MiB',
    'processTree.privateMemoryMedianMiB',
    'processTree.privateMemoryP95MiB',
    'renderer.privateWorkingSetMedianMiB',
    'renderer.privateMemoryMedianMiB',
    'v8.usedMiB',
    'v8.capacityMiB',
    'media.imageNaturalPixelCount',
    'media.videoPixelCount',
    'media.canvasPixelCount',
    'native.image-media.sampledMiB',
    'native.gpu-graphics.sampledMiB',
    'native.media-webrtc.sampledMiB',
    'native.blink.sampledMiB',
    'native.network-cache.sampledMiB',
    'dom.documents',
    'dom.nodes',
    'dom.jsEventListeners'
)
$metrics = foreach ($name in $metricNames) {
    $baseline = Get-MetricValue -Cdp $baselineCdp -Summary $baselineSummary -Metric $name
    $candidate = Get-MetricValue -Cdp $candidateCdp -Summary $candidateSummary -Metric $name
    [pscustomobject]@{
        name = $name
        baseline = if ($null -ne $baseline) { [math]::Round($baseline, 3) } else { $null }
        candidate = if ($null -ne $candidate) { [math]::Round($candidate, 3) } else { $null }
        delta = if ($null -ne $baseline -and $null -ne $candidate) { [math]::Round($candidate - $baseline, 3) } else { $null }
    }
}
$comparison = [pscustomobject]@{
    schemaVersion = 1
    baselineCdp = (Resolve-Path -LiteralPath $BaselineCdpPath).Path
    candidateCdp = (Resolve-Path -LiteralPath $CandidateCdpPath).Path
    baselineRoleSummary = (Resolve-Path -LiteralPath $BaselineRoleSummaryPath).Path
    candidateRoleSummary = (Resolve-Path -LiteralPath $CandidateRoleSummaryPath).Path
    interpretation = 'Descriptive workload comparison. Deltas do not establish an optimization or a functional result.'
    metrics = @($metrics)
}
if ($OutputPath) {
    $parent = Split-Path -Parent $OutputPath
    if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $comparison | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
}
$comparison | ConvertTo-Json -Depth 8
