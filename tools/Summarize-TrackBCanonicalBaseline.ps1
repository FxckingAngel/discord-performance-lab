[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })] [string] $ManifestPath,
    [ValidateNotNullOrEmpty()] [string] $OutputPath = (Join-Path (Get-Location) ('artifacts/track-b-canonical-summary-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json'))
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
function Values([string]$Property) {
    @($manifest.repetitions | ForEach-Object { (Get-Content -Raw -LiteralPath $_.processSummaryPath | ConvertFrom-Json).processTree.$Property } | ForEach-Object { [double]$_ } | Sort-Object)
}
function Stats([string]$Property) {
    $values = @(Values $Property)
    $p95Index = [math]::Min($values.Count - 1, [math]::Max(0, [math]::Ceiling($values.Count * 0.95) - 1))
    $mean = ($values | Measure-Object -Average).Average
    $variance = if ($values.Count -gt 1) { (($values | ForEach-Object { ($_ - $mean) * ($_ - $mean) } | Measure-Object -Average).Average) } else { 0 }
    [pscustomobject]@{ metric = $Property; median = $values[[math]::Floor(($values.Count - 1) / 2)]; p95 = $values[$p95Index]; minimum = $values[0]; maximum = $values[-1]; mean = [math]::Round($mean, 3); standardDeviation = [math]::Round([math]::Sqrt($variance), 3); range = [math]::Round(($values[-1] - $values[0]), 3) }
}
$result = [pscustomobject]@{
    schemaVersion = 1
    summarizedAt = (Get-Date).ToUniversalTime().ToString('o')
    sourceManifest = (Resolve-Path -LiteralPath $ManifestPath).Path
    policy = 'Five-repetition canonical static-state summary. Route identity is based on manual confirmation and is not inferred from process data.'
    statistics = @((Stats 'privateWorkingSetMedianMiB'), (Stats 'privateMemoryMedianMiB'), (Stats 'cpuMedianPercentOfTotal'))
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result
