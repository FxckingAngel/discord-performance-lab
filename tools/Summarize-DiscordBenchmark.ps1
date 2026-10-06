[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string[]] $InputPath,

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath
)

function Get-Quantile {
    param(
        [Parameter(Mandatory = $true)] [double[]] $Values,
        [Parameter(Mandatory = $true)] [double] $Probability
    )

    $ordered = @($Values | Sort-Object)
    if ($ordered.Count -eq 0) { return $null }
    $position = ($ordered.Count - 1) * $Probability
    $lower = [math]::Floor($position)
    $upper = [math]::Ceiling($position)
    if ($lower -eq $upper) { return [double] $ordered[$lower] }
    $fraction = $position - $lower
    return [double] ($ordered[$lower] + (($ordered[$upper] - $ordered[$lower]) * $fraction))
}

function Get-MemorySummary {
    param([double[]] $Values)

    $valid = @($Values | Where-Object { $null -ne $_ })
    if ($valid.Count -eq 0) {
        return [pscustomobject]@{ median = $null; p95 = $null; minimum = $null; maximum = $null }
    }
    return [pscustomobject]@{
        median = [math]::Round((Get-Quantile $valid 0.50), 2)
        p95 = [math]::Round((Get-Quantile $valid 0.95), 2)
        minimum = [math]::Round(($valid | Measure-Object -Minimum).Minimum, 2)
        maximum = [math]::Round(($valid | Measure-Object -Maximum).Maximum, 2)
    }
}

$runs = foreach ($path in $InputPath) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Benchmark file not found: $path"
    }
    Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
}

$samples = @($runs | ForEach-Object { $_.samples })
if ($samples.Count -eq 0) { throw 'No samples were found in the input files.' }

$workingSet = @($samples | ForEach-Object { [double] $_.workingSetBytes / 1MB })
$workingSetPrivate = @($samples | ForEach-Object { if ($null -ne $_.workingSetPrivateBytes) { [double] $_.workingSetPrivateBytes / 1MB } })
$workingSetShareable = @($samples | ForEach-Object { if ($null -ne $_.workingSetShareableBytes) { [double] $_.workingSetShareableBytes / 1MB } })
$privateBytes = @($samples | ForEach-Object { [double] $_.privateBytes / 1MB })
$commitBytes = @($samples | ForEach-Object { if ($null -ne $_.commitBytes) { [double] $_.commitBytes / 1MB } })
$processCounts = @($samples | ForEach-Object { [double] $_.processCount })
$cpuDeltas = @($runs | ForEach-Object {
    [double] $_.samples[-1].cpuSeconds - [double] $_.samples[0].cpuSeconds
})
$logicalProcessors = [int] (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
$cpuPercent = @($runs | ForEach-Object {
    $start = [datetime]::Parse($_.samples[0].timestamp)
    $end = [datetime]::Parse($_.samples[-1].timestamp)
    $wallSeconds = ($end - $start).TotalSeconds
    if ($wallSeconds -le 0 -or $logicalProcessors -le 0) { return }
    (([double] $_.samples[-1].cpuSeconds - [double] $_.samples[0].cpuSeconds) / $wallSeconds / $logicalProcessors) * 100
})

$summary = [pscustomobject] @{
    schemaVersion = 1
    runs = $runs.Count
    samples = $samples.Count
    builds = @($runs | ForEach-Object build | Sort-Object -Unique)
    scenarios = @($runs | ForEach-Object scenario | Sort-Object -Unique)
    logicalProcessorCount = $logicalProcessors
    workingSetMiB = [pscustomobject] @{
        median = [math]::Round((Get-Quantile $workingSet 0.50), 2)
        p95 = [math]::Round((Get-Quantile $workingSet 0.95), 2)
        minimum = [math]::Round(($workingSet | Measure-Object -Minimum).Minimum, 2)
        maximum = [math]::Round(($workingSet | Measure-Object -Maximum).Maximum, 2)
    }
    privateWorkingSetMiB = Get-MemorySummary $workingSetPrivate
    shareableWorkingSetMiB = Get-MemorySummary $workingSetShareable
    privateMemoryMiB = [pscustomobject] @{
        median = [math]::Round((Get-Quantile $privateBytes 0.50), 2)
        p95 = [math]::Round((Get-Quantile $privateBytes 0.95), 2)
        minimum = [math]::Round(($privateBytes | Measure-Object -Minimum).Minimum, 2)
        maximum = [math]::Round(($privateBytes | Measure-Object -Maximum).Maximum, 2)
    }
    commitMiB = Get-MemorySummary $commitBytes
    processCount = [pscustomobject] @{
        median = [math]::Round((Get-Quantile $processCounts 0.50), 2)
        maximum = [math]::Round(($processCounts | Measure-Object -Maximum).Maximum, 2)
    }
    cpuSeconds = [pscustomobject] @{
        medianRunDelta = [math]::Round((Get-Quantile $cpuDeltas 0.50), 3)
        maximumRunDelta = [math]::Round(($cpuDeltas | Measure-Object -Maximum).Maximum, 3)
    }
    cpuPercentOfTotal = [pscustomobject] @{
        medianRun = [math]::Round((Get-Quantile $cpuPercent 0.50), 3)
        p95Run = [math]::Round((Get-Quantile $cpuPercent 0.95), 3)
    }
}

if ($OutputPath) {
    $parent = Split-Path -Parent $OutputPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding utf8
}

$summary | ConvertTo-Json -Depth 6
