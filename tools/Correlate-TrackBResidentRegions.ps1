[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ResidentTypesPath,

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = (Join-Path (Get-Location) ('artifacts/track-b-region-module-correlation-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json'))
)

$ErrorActionPreference = 'Stop'
$inputData = Get-Content -LiteralPath $ResidentTypesPath -Raw | ConvertFrom-Json
$process = Get-Process -Id ([int] $inputData.processId) -ErrorAction Stop
$modules = @($process.Modules | ForEach-Object {
    [pscustomobject]@{
        moduleName = [string] $_.ModuleName
        fileName = [string] $_.FileName
        baseAddress = [uint64] $_.BaseAddress.ToInt64()
        sizeBytes = [uint64] $_.ModuleMemorySize
    }
})

$regions = @($inputData.largestPrivateWritableRegions | ForEach-Object {
    $addressText = [string] $_.baseAddress
    if ($addressText -notmatch '^0x[0-9a-fA-F]+$') { throw "Invalid region base address: $addressText" }
    $address = [Convert]::ToUInt64($addressText.Substring(2), 16)
    $module = $modules | Where-Object {
        $address -ge $_.baseAddress -and $address -lt ($_.baseAddress + $_.sizeBytes)
    } | Select-Object -First 1
    [pscustomobject]@{
        baseAddress = $addressText
        allocationBase = [string] $_.allocationBase
        committedMiB = [math]::Round(([double] $_.committedBytes / 1MB), 3)
        residentMiB = [math]::Round(([double] $_.residentBytes / 1MB), 3)
        residentPages = [long] $_.residentPages
        protect = [uint32] $_.protect
        module = if ($module) { $module.moduleName } else { $null }
        moduleFile = if ($module) { $module.fileName } else { $null }
    }
})

$result = [pscustomobject]@{
    schemaVersion = 1
    capturedAt = (Get-Date).ToUniversalTime().ToString('o')
    processId = [int] $inputData.processId
    regionSource = (Resolve-Path -LiteralPath $ResidentTypesPath).Path
    moduleSource = 'Get-Process.Modules; read-only'
    loadedModuleCount = $modules.Count
    regions = $regions
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
[pscustomobject]@{
    processId = $result.processId
    regionCount = $regions.Count
    moduleMatchedRegionCount = @($regions | Where-Object module).Count
    outputPath = $OutputPath
}
