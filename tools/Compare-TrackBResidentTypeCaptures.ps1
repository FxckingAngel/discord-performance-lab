[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $BaselineManifestPath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ComparisonManifestPath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath
)

function Read-Rows {
    param([string] $ManifestPath)

    $manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    $rows = foreach ($entry in @($manifest.rows | Where-Object captured)) {
        $capture = Get-Content -LiteralPath $entry.outputPath -Raw | ConvertFrom-Json
        $memory = $capture.memory
        [pscustomobject]@{
            role = [string] $entry.role
            pid = [int] $entry.pid
            residentMiB = [math]::Round(([double] $memory.residentValidBytes / 1MB), 3)
            privateWritableMiB = [math]::Round(([double] $memory.privateWritableResidentBytes / 1MB), 3)
            privateExecutableMiB = [math]::Round(([double] $memory.privateExecutableResidentBytes / 1MB), 3)
            privateOtherMiB = [math]::Round(([double] $memory.privateOtherResidentBytes / 1MB), 3)
            privateWritableSharedFlagMiB = [math]::Round(([double] $memory.privateWritableSharedFlagResidentBytes / 1MB), 3)
            privateExecutableSharedFlagMiB = [math]::Round(([double] $memory.privateExecutableSharedFlagResidentBytes / 1MB), 3)
            privateOtherSharedFlagMiB = [math]::Round(([double] $memory.privateOtherSharedFlagResidentBytes / 1MB), 3)
            mappedMiB = [math]::Round(([double] $memory.mappedResidentBytes / 1MB), 3)
            imageMiB = [math]::Round(([double] $memory.imageResidentBytes / 1MB), 3)
            committedMiB = [math]::Round(([double] $memory.committedBytes / 1MB), 3)
            reservedMiB = [math]::Round(([double] $memory.reservedBytes / 1MB), 3)
            committedPrivateWritableMiB = [math]::Round(([double] $memory.committedPrivateWritableBytes / 1MB), 3)
            committedPrivateExecutableMiB = [math]::Round(([double] $memory.committedPrivateExecutableBytes / 1MB), 3)
            committedPrivateOtherMiB = [math]::Round(([double] $memory.committedPrivateOtherBytes / 1MB), 3)
            committedMappedMiB = [math]::Round(([double] $memory.committedMappedBytes / 1MB), 3)
            committedImageMiB = [math]::Round(([double] $memory.committedImageBytes / 1MB), 3)
        }
    }
    return @($rows)
}

function Sum-Role {
    param([object[]] $Rows, [string] $Role, [string] $Property)

    $value = @($Rows | Where-Object role -eq $Role | Measure-Object -Property $Property -Sum).Sum
    if ($value.Count -eq 0 -or $null -eq $value[0]) { return 0 }
    return [math]::Round([double] $value[0], 3)
}

$baselineRows = Read-Rows $BaselineManifestPath
$comparisonRows = Read-Rows $ComparisonManifestPath
$roles = @($baselineRows.role + $comparisonRows.role | Sort-Object -Unique)
$properties = @('residentMiB', 'privateWritableMiB', 'privateExecutableMiB', 'privateOtherMiB', 'privateWritableSharedFlagMiB', 'privateExecutableSharedFlagMiB', 'privateOtherSharedFlagMiB', 'mappedMiB', 'imageMiB', 'committedMiB', 'reservedMiB', 'committedPrivateWritableMiB', 'committedPrivateExecutableMiB', 'committedPrivateOtherMiB', 'committedMappedMiB', 'committedImageMiB')
$roleDeltas = foreach ($role in $roles) {
    $result = [ordered]@{ role = $role }
    foreach ($property in $properties) {
        $before = Sum-Role $baselineRows $role $property
        $after = Sum-Role $comparisonRows $role $property
        $result["baseline$property"] = $before
        $result["comparison$property"] = $after
        $result["delta$property"] = [math]::Round(($after - $before), 3)
    }
    [pscustomobject] $result
}

$totals = foreach ($property in $properties) {
    $before = [math]::Round((@($baselineRows | Measure-Object -Property $property -Sum).Sum), 3)
    $after = [math]::Round((@($comparisonRows | Measure-Object -Property $property -Sum).Sum), 3)
    [pscustomobject]@{ category = $property; baselineMiB = $before; comparisonMiB = $after; deltaMiB = [math]::Round(($after - $before), 3) }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    policy = 'Aggregate per-role resident-page comparison. PIDs are preserved only in local source artifacts; no command lines, page content, or account data are copied.'
    baselineSource = (Resolve-Path -LiteralPath $BaselineManifestPath).Path
    comparisonSource = (Resolve-Path -LiteralPath $ComparisonManifestPath).Path
    baselineProcessCount = $baselineRows.Count
    comparisonProcessCount = $comparisonRows.Count
    totals = @($totals)
    roles = @($roleDeltas)
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result.totals | Format-Table -AutoSize
$result.roles | Format-Table -AutoSize
