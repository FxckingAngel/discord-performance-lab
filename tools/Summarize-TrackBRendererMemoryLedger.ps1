[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ResidentTypesPath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $VirtualTypesPath,

    [ValidateNotNullOrEmpty()]
    [string] $CdpDiagnosticsPath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath
)

$resident = Get-Content -Raw -LiteralPath $ResidentTypesPath | ConvertFrom-Json
$virtual = Get-Content -Raw -LiteralPath $VirtualTypesPath | ConvertFrom-Json
$rendererResident = @($resident | Select-Object -First 1)
$rendererVirtual = @($virtual.processes | Where-Object role -eq 'renderer' | Select-Object -First 1)
if ($rendererResident.Count -eq 0 -or $rendererVirtual.Count -eq 0) {
    throw 'Both inputs must contain a renderer classification.'
}
$residentMemory = $rendererResident.memory
if ($null -eq $residentMemory) {
    throw 'The resident classification does not contain a memory object.'
}

$v8UsedMiB = $null
if ($CdpDiagnosticsPath) {
    $cdp = Get-Content -Raw -LiteralPath $CdpDiagnosticsPath | ConvertFrom-Json
    if ($cdp.heapUsage -and $null -ne $cdp.heapUsage.usedSize) {
        $v8UsedMiB = [math]::Round([double] $cdp.heapUsage.usedSize / 1MB, 3)
    }
}

$privateWritableResidentMiB = [math]::Round([double] $residentMemory.privateWritableResidentBytes / 1MB, 3)
$result = [pscustomobject]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    processId = [int] $rendererResident.processId
    role = 'renderer'
    policy = 'Sanitized boundary ledger. Resident and committed categories are separate measurements and must not be summed across views. V8 is optional and is not assumed to own native resident pages.'
    sources = [pscustomobject]@{
        residentTypes = (Resolve-Path -LiteralPath $ResidentTypesPath).Path
        virtualTypes = (Resolve-Path -LiteralPath $VirtualTypesPath).Path
        cdpDiagnostics = if ($CdpDiagnosticsPath) { (Resolve-Path -LiteralPath $CdpDiagnosticsPath).Path } else { $null }
    }
    resident = [pscustomobject]@{
        totalMiB = [math]::Round([double] $residentMemory.residentValidBytes / 1MB, 3)
        privateWritableMiB = $privateWritableResidentMiB
        privateExecutableMiB = [math]::Round([double] $residentMemory.privateExecutableResidentBytes / 1MB, 3)
        privateOtherMiB = [math]::Round([double] $residentMemory.privateOtherResidentBytes / 1MB, 3)
        mappedMiB = [math]::Round([double] $residentMemory.mappedResidentBytes / 1MB, 3)
        imageMiB = [math]::Round([double] $residentMemory.imageResidentBytes / 1MB, 3)
    }
    committed = [pscustomobject]@{
        totalMiB = [math]::Round([double] $residentMemory.committedBytes / 1MB, 3)
        privateWritableMiB = [math]::Round([double] $rendererVirtual.privateWritableCommittedBytes / 1MB, 3)
        privateExecutableMiB = [math]::Round([double] $rendererVirtual.privateExecutableCommittedBytes / 1MB, 3)
        privateOtherMiB = [math]::Round([double] $rendererVirtual.privateOtherProtectionCommittedBytes / 1MB, 3)
        mappedMiB = [math]::Round([double] $rendererVirtual.mappedCommittedBytes / 1MB, 3)
        imageMiB = [math]::Round([double] $rendererVirtual.imageCommittedBytes / 1MB, 3)
        nonResidentPrivateWritableMiB = [math]::Round(([double] $rendererVirtual.privateWritableCommittedBytes / 1MB) - $privateWritableResidentMiB, 3)
    }
    v8 = [pscustomobject]@{
        usedMiB = $v8UsedMiB
        interpretation = 'Live V8 heap only; null means no paired CDP capture was supplied.'
    }
    boundaries = [pscustomobject]@{
        privateResidentBeyondV8MiB = if ($null -ne $v8UsedMiB) { [math]::Round([math]::Max(0, $privateWritableResidentMiB - $v8UsedMiB), 3) } else { $null }
        privateWritableCommittedBeyondResidentMiB = [math]::Round(([double] $rendererVirtual.privateWritableCommittedBytes / 1MB) - $privateWritableResidentMiB, 3)
        reservedAddressSpaceExcluded = $true
    }
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result
