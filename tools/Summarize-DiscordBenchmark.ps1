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

$runs = foreach ($path in $InputPath) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Benchmark file not found: $path"
    }
    Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
}

$samples = @($runs | ForEach-Object { $_.samples })
if ($samples.Count -eq 0) { throw 'No samples were found in the input files.' }

$workingSet = @($samples | ForEach-Object { [double] $_.workingSetBytes / 1MB })
$privateBytes = @($samples | ForEach-Object { [double] $_.privateBytes / 1MB })
$processCounts = @($samples | ForEach-Object { [double] $_.processCount })
$cpuDeltas = @($runs | ForEach-Object {
    [double] $_.samples[-1].cpuSeconds - [double] $_.samples[0].cpuSeconds
})

$summary = [pscustomobject] @{
    schemaVersion = 1
    runs = $runs.Count
    samples = $samples.Count
    builds = @($runs | ForEach-Object build | Sort-Object -Unique)
    scenarios = @($runs | ForEach-Object scenario | Sort-Object -Unique)
    workingSetMiB = [pscustomobject] @{
        median = [math]::Round((Get-Quantile $workingSet 0.50), 2)
        p95 = [math]::Round((Get-Quantile $workingSet 0.95), 2)
        minimum = [math]::Round(($workingSet | Measure-Object -Minimum).Minimum, 2)
        maximum = [math]::Round(($workingSet | Measure-Object -Maximum).Maximum, 2)
    }
    privateMemoryMiB = [pscustomobject] @{
        median = [math]::Round((Get-Quantile $privateBytes 0.50), 2)
        p95 = [math]::Round((Get-Quantile $privateBytes 0.95), 2)
        minimum = [math]::Round(($privateBytes | Measure-Object -Minimum).Minimum, 2)
        maximum = [math]::Round(($privateBytes | Measure-Object -Maximum).Maximum, 2)
    }
    processCount = [pscustomobject] @{
        median = [math]::Round((Get-Quantile $processCounts 0.50), 2)
        maximum = [math]::Round(($processCounts | Measure-Object -Maximum).Maximum, 2)
    }
    cpuSeconds = [pscustomobject] @{
        medianRunDelta = [math]::Round((Get-Quantile $cpuDeltas 0.50), 3)
        maximumRunDelta = [math]::Round(($cpuDeltas | Measure-Object -Maximum).Maximum, 3)
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
