[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string[]] $InputDirectory,

    [ValidateNotNullOrEmpty()]
    [string] $BaselineScenario,

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = (Join-Path (Get-Location) ('artifacts/track-b-feature-summary-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json'))
)

$ErrorActionPreference = 'Stop'

function Read-ScenarioCapture {
    param([string] $Directory)

    $treePath = Join-Path $Directory 'process-tree.json'
    $manifestPath = Join-Path $Directory 'resident-types.json'
    if (-not (Test-Path -LiteralPath $treePath -PathType Leaf)) { throw "Missing process-tree.json in $Directory" }
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "Missing resident-types.json in $Directory" }

    $tree = Get-Content -LiteralPath $treePath -Raw | ConvertFrom-Json
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $scenario = [string] $manifest.scenario
    if ([string]::IsNullOrWhiteSpace($scenario)) { $scenario = [string] $tree.scenario }
    $finalSample = $tree.samples[-1]
    $residentRows = foreach ($entry in @($manifest.rows | Where-Object captured)) {
        $capture = Get-Content -LiteralPath ([string] $entry.outputPath) -Raw | ConvertFrom-Json
        $memory = $capture.memory
        [pscustomobject]@{
            scenario = $scenario
            pid = [int] $capture.processId
            role = [string] $capture.role
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
            privateWritableRegionCount = [int] $memory.privateWritableRegionCount
            privateWritableUnder64KiBRegionCount = [int] $memory.privateWritableUnder64KiBRegionCount
            privateWritable64KiBTo1MiBRegionCount = [int] $memory.privateWritable64KiBTo1MiBRegionCount
            privateWritable1MiBTo4MiBRegionCount = [int] $memory.privateWritable1MiBTo4MiBRegionCount
            privateWritable4MiBTo16MiBRegionCount = [int] $memory.privateWritable4MiBTo16MiBRegionCount
            privateWritable16MiBOrLargerRegionCount = [int] $memory.privateWritable16MiBOrLargerRegionCount
            privateWritableUnder64KiBResidentMiB = [math]::Round(([double] $memory.privateWritableUnder64KiBResidentBytes / 1MB), 3)
            privateWritable64KiBTo1MiBResidentMiB = [math]::Round(([double] $memory.privateWritable64KiBTo1MiBResidentBytes / 1MB), 3)
            privateWritable1MiBTo4MiBResidentMiB = [math]::Round(([double] $memory.privateWritable1MiBTo4MiBResidentBytes / 1MB), 3)
            privateWritable4MiBTo16MiBResidentMiB = [math]::Round(([double] $memory.privateWritable4MiBTo16MiBResidentBytes / 1MB), 3)
            privateWritable16MiBOrLargerResidentMiB = [math]::Round(([double] $memory.privateWritable16MiBOrLargerResidentBytes / 1MB), 3)
        }
    }

    $sampleTotals = [ordered]@{
        processCount = [int] $finalSample.processCount
        totalWorkingSetMiB = [math]::Round(([double] $finalSample.workingSetBytes / 1MB), 3)
        privateWorkingSetMiB = [math]::Round(([double] $finalSample.workingSetPrivateBytes / 1MB), 3)
        shareableWorkingSetMiB = [math]::Round(([double] $finalSample.workingSetShareableBytes / 1MB), 3)
        privateBytesMiB = [math]::Round(([double] $finalSample.privateBytes / 1MB), 3)
        cpuPercentOfTotal = if ($null -eq $finalSample.cpuPercentOfTotal) { $null } else { [math]::Round([double] $finalSample.cpuPercentOfTotal, 4) }
    }
    [pscustomobject]@{
        scenario = $scenario
        directory = (Resolve-Path -LiteralPath $Directory).Path
        finalSample = [pscustomobject] $sampleTotals
        residentRows = @($residentRows)
    }
}

function Sum-Property {
    param([object[]] $Rows, [string] $Property)
    $values = @($Rows | Measure-Object -Property $Property -Sum).Sum
    if ($values.Count -eq 0 -or $null -eq $values[0]) { return 0 }
    return [math]::Round([double] $values[0], 3)
}

$captures = @($InputDirectory | ForEach-Object { Read-ScenarioCapture $_ })
$categoryProperties = @('residentMiB', 'privateWritableMiB', 'privateExecutableMiB', 'privateOtherMiB', 'privateWritableSharedFlagMiB', 'privateExecutableSharedFlagMiB', 'privateOtherSharedFlagMiB', 'mappedMiB', 'imageMiB', 'committedMiB', 'reservedMiB', 'committedPrivateWritableMiB', 'committedPrivateExecutableMiB', 'committedPrivateOtherMiB', 'committedMappedMiB', 'committedImageMiB', 'privateWritableRegionCount', 'privateWritableUnder64KiBRegionCount', 'privateWritable64KiBTo1MiBRegionCount', 'privateWritable1MiBTo4MiBRegionCount', 'privateWritable4MiBTo16MiBRegionCount', 'privateWritable16MiBOrLargerRegionCount', 'privateWritableUnder64KiBResidentMiB', 'privateWritable64KiBTo1MiBResidentMiB', 'privateWritable1MiBTo4MiBResidentMiB', 'privateWritable4MiBTo16MiBResidentMiB', 'privateWritable16MiBOrLargerResidentMiB')
$scenarioSummaries = foreach ($capture in $captures) {
    $totals = [ordered]@{ scenario = $capture.scenario; directory = $capture.directory }
    foreach ($property in $categoryProperties) { $totals[$property] = Sum-Property $capture.residentRows $property }
    $totals['rendererRows'] = @($capture.residentRows | Where-Object role -eq 'renderer').Count
    $totals['gpuRows'] = @($capture.residentRows | Where-Object role -eq 'gpu-process').Count
    [pscustomobject] $totals
}

$baseline = if ($BaselineScenario) { $scenarioSummaries | Where-Object scenario -eq $BaselineScenario | Select-Object -First 1 } else { $null }
$deltas = @()
if ($baseline) {
    foreach ($summary in $scenarioSummaries | Where-Object scenario -ne $BaselineScenario) {
        $delta = [ordered]@{ baselineScenario = $BaselineScenario; scenario = $summary.scenario }
        foreach ($property in $categoryProperties) { $delta["delta$property"] = [math]::Round(([double] $summary.$property - [double] $baseline.$property), 3) }
        $deltas += [pscustomobject] $delta
    }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    policy = 'Final-sample per-PID classifications are preserved. Reserved address space is reported separately. Resident totals are per-process and do not deduplicate shared physical pages.'
    baselineScenario = $BaselineScenario
    scenarios = @($scenarioSummaries)
    deltasFromBaseline = @($deltas)
    perPid = @($captures | ForEach-Object { $_.residentRows })
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$scenarioSummaries | Format-Table -AutoSize
if ($deltas.Count -gt 0) { $deltas | Format-Table -AutoSize }
Write-Output "summary=$OutputPath"
