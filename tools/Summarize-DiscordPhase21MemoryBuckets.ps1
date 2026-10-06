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

$v8UsedMiB = [math]::Round([double] $cdp.heapUsage.usedSize / 1MB, 3)
$v8TotalMiB = [math]::Round([double] $cdp.heapUsage.totalSize / 1MB, 3)
$rendererPrivateMiB = [double] $renderer.privateMemoryMedianMiB
$residualMiB = [math]::Round([math]::Max(0, $rendererPrivateMiB - $v8UsedMiB), 3)
$gpu = @($roles.roles | Where-Object role -eq 'gpu-process' | Select-Object -First 1)
$gpuPrivateMiB = if ($gpu.Count -gt 0) { [math]::Round([double] $gpu.privateMemoryMedianMiB, 3) } else { $null }
$buckets = @(
    [pscustomobject]@{ bucket = 'V8 JavaScript heap'; measuredMiB = $v8UsedMiB; evidence = 'Runtime.getHeapUsage.usedSize'; interpretation = 'Measured live V8 heap only.' }
    [pscustomobject]@{ bucket = 'Renderer private memory'; measuredMiB = [math]::Round($rendererPrivateMiB, 3); evidence = 'Rooted process attribution median'; interpretation = 'Whole renderer private memory; not equivalent to JavaScript heap.' }
    [pscustomobject]@{ bucket = 'Non-V8 renderer residual lower bound'; measuredMiB = $residualMiB; evidence = 'Renderer private median minus V8 used heap'; interpretation = 'May include Blink, native Chromium, decoded media, shared buffers, and other allocations. Not independently attributed.' }
    [pscustomobject]@{ bucket = 'GPU process private memory'; measuredMiB = $gpuPrivateMiB; evidence = 'Rooted process attribution median'; interpretation = 'Separate GPU-process allocation; shared texture ownership still needs GPU counters.' }
)
$result = [pscustomobject]@{
    schemaVersion = 1
    cdpSource = $CdpInputPath
    roleSummarySource = $RoleSummaryPath
    scenario = $roles.scenario
    rootPid = $roles.rootPid
    cdpCapturedAt = $cdp.capturedAt
    v8HeapCapacityMiB = $v8TotalMiB
    buckets = $buckets
    privacy = 'Sanitized aggregate only. No heap objects, function names, URLs, message contents, tokens, or snapshots are included.'
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result
