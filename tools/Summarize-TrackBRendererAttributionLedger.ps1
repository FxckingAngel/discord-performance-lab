[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ResidentTypesPath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $CdpPath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath
)

$ErrorActionPreference = 'Stop'
$resident = Get-Content -LiteralPath $ResidentTypesPath -Raw | ConvertFrom-Json
$cdp = Get-Content -LiteralPath $CdpPath -Raw | ConvertFrom-Json
$memory = $resident.memory
$heap = $cdp.heapUsage
$nativeWindow = $cdp.nativeMemorySamplingWindow

function To-MiB([double] $Bytes) { return [math]::Round(($Bytes / 1MB), 3) }

$privateWritableResidentMiB = To-MiB $memory.privateWritableResidentBytes
$v8UsedMiB = To-MiB $heap.usedSize
$result = [pscustomobject]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    processId = [int] $resident.processId
    residentSource = (Resolve-Path -LiteralPath $ResidentTypesPath).Path
    cdpSource = (Resolve-Path -LiteralPath $CdpPath).Path
    policy = 'Sanitized aggregate join. No heap objects, strings, URLs, command lines, or page content are copied.'
    renderer = [pscustomobject]@{
        workingSetMiB = To-MiB $resident.workingSetBytes
        privateBytesMiB = To-MiB $resident.privateBytes
        residentMiB = To-MiB $memory.residentValidBytes
        privateWritableResidentMiB = $privateWritableResidentMiB
        privateExecutableResidentMiB = To-MiB $memory.privateExecutableResidentBytes
        privateOtherResidentMiB = To-MiB $memory.privateOtherResidentBytes
        mappedResidentMiB = To-MiB $memory.mappedResidentBytes
        imageResidentMiB = To-MiB $memory.imageResidentBytes
        committedPrivateWritableMiB = To-MiB $memory.committedPrivateWritableBytes
        committedMappedMiB = To-MiB $memory.committedMappedBytes
        committedImageMiB = To-MiB $memory.committedImageBytes
    }
    v8 = [pscustomobject]@{
        usedMiB = $v8UsedMiB
        totalMiB = To-MiB $heap.totalSize
        embedderHeapUsedMiB = To-MiB $heap.embedderHeapUsedSize
        backingStorageMiB = To-MiB $heap.backingStorageSize
    }
    boundaries = [pscustomobject]@{
        privateWritableResidentMinusV8UsedMiB = [math]::Round(($privateWritableResidentMiB - $v8UsedMiB), 3)
        nativeSampledMiB = if ($nativeWindow) { To-MiB $nativeWindow.sampledBytes } else { $null }
        nativeAttributedMiB = if ($nativeWindow) { To-MiB $nativeWindow.attributedBytes } else { $null }
        nativeSamplingStatus = if ($nativeWindow) { [string] $nativeWindow.sampleStatus } else { 'missing' }
    }
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result | Select-Object processId,renderer,v8,boundaries
