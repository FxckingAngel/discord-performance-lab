[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string] $StaticCaptureDirectory,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string] $MediaCaptureDirectory,

    [Parameter(Mandatory = $true)]
    [string] $OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-Capture([string] $Directory) {
    $manifestPath = Join-Path $Directory 'scenario-capture.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "Scenario manifest is missing: $manifestPath" }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $decodedPath = if ($manifest.decodedOwnershipPath -and (Test-Path -LiteralPath $manifest.decodedOwnershipPath -PathType Leaf)) {
        [string]$manifest.decodedOwnershipPath
    }
    else {
        Join-Path $Directory 'wpr-heap-snapshot/sanitized-xperf-native-ownership.json'
    }
    $decoded = if (Test-Path -LiteralPath $decodedPath -PathType Leaf) {
        Get-Content -LiteralPath $decodedPath -Raw | ConvertFrom-Json
    }
    else { $null }
    return [pscustomobject]@{
        directory = (Resolve-Path -LiteralPath $Directory).Path
        scenario = [string]$manifest.scenario
        rootPid = [int]$manifest.rootPid
        rendererPid = [int]$manifest.rendererPid
        decoded = $decoded
    }
}

function Get-FamilyMap([object] $Decoded) {
    $map = @{}
    if (-not $Decoded) { return $map }
    foreach ($family in @($Decoded.families)) {
        $map[[string]$family.family] = [pscustomobject]@{
            outstandingBytes = [int64]$family.outstandingBytes
            allocationCount = [int64]$family.allocationCount
        }
    }
    return $map
}

$static = Read-Capture $StaticCaptureDirectory
$media = Read-Capture $MediaCaptureDirectory
$staticFamilies = Get-FamilyMap $static.decoded
$mediaFamilies = Get-FamilyMap $media.decoded
$familyNames = @($staticFamilies.Keys + $mediaFamilies.Keys | Sort-Object -Unique)
$familyDelta = foreach ($name in $familyNames) {
    $staticBytes = if ($staticFamilies.ContainsKey($name)) { $staticFamilies[$name].outstandingBytes } else { 0 }
    $mediaBytes = if ($mediaFamilies.ContainsKey($name)) { $mediaFamilies[$name].outstandingBytes } else { 0 }
    $staticCount = if ($staticFamilies.ContainsKey($name)) { $staticFamilies[$name].allocationCount } else { 0 }
    $mediaCount = if ($mediaFamilies.ContainsKey($name)) { $mediaFamilies[$name].allocationCount } else { 0 }
    [pscustomobject]@{
        family = $name
        staticOutstandingBytes = $staticBytes
        mediaOutstandingBytes = $mediaBytes
        deltaOutstandingBytes = $mediaBytes - $staticBytes
        staticAllocationCount = $staticCount
        mediaAllocationCount = $mediaCount
        deltaAllocationCount = $mediaCount - $staticCount
    }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    comparedAt = (Get-Date).ToUniversalTime().ToString('o')
    rawTracesRetainedPrivate = $true
    static = [pscustomobject]@{
        scenario = $static.scenario
        rendererPid = $static.rendererPid
        decodedOutstandingBytes = if ($static.decoded) { [int64]$static.decoded.decodedOutstandingBytes } else { $null }
        decodedAllocationCount = if ($static.decoded) { [int64]$static.decoded.decodedAllocationCount } else { $null }
    }
    media = [pscustomobject]@{
        scenario = $media.scenario
        rendererPid = $media.rendererPid
        decodedOutstandingBytes = if ($media.decoded) { [int64]$media.decoded.decodedOutstandingBytes } else { $null }
        decodedAllocationCount = if ($media.decoded) { [int64]$media.decoded.decodedAllocationCount } else { $null }
    }
    familyDeltas = @($familyDelta | Sort-Object deltaOutstandingBytes -Descending)
    limitation = 'This comparison covers only the decoded outstanding allocation set represented in each WPR snapshot. It is not a complete renderer private-working-set or unique-physical-page comparison.'
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result
