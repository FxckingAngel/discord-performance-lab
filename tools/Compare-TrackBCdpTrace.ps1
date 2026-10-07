[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $BaselinePath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $CandidatePath,

    [string] $OutputPath
)

function Read-TraceSummary {
    param([string] $Path)
    $value = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ($null -eq $value.summary -or $value.durationSeconds -le 0) {
        throw "Trace summary is missing or has an invalid duration: $Path"
    }
    return $value
}

function Get-Count {
    param([object] $Trace, [string] $Name)
    $property = $Trace.summary.selectedCounts.PSObject.Properties[$Name]
    if ($null -eq $property) { return 0 }
    return [double] $property.Value
}

function Get-Duration {
    param([object] $Trace, [string] $Name)
    foreach ($entry in @($Trace.summary.eventDurationsMicroseconds)) {
        if ([string] $entry.key -ceq $Name) { return [double] $entry.count }
    }
    return 0
}

$baseline = Read-TraceSummary $BaselinePath
$candidate = Read-TraceSummary $CandidatePath
$names = @('RunTask', 'EvaluateScript', 'FunctionCall', 'UpdateLayoutTree', 'Layout', 'Paint', 'CompositeLayers', 'DrawFrame', 'memory_dump', 'periodic_interval')
$rows = foreach ($name in $names) {
    $baselineCount = Get-Count $baseline $name
    $candidateCount = Get-Count $candidate $name
    $baselineDuration = Get-Duration $baseline $name
    $candidateDuration = Get-Duration $candidate $name
    [pscustomobject]@{
        event = $name
        baselinePerSecond = [math]::Round($baselineCount / [double] $baseline.durationSeconds, 3)
        candidatePerSecond = [math]::Round($candidateCount / [double] $candidate.durationSeconds, 3)
        baselineDurationMsPerSecond = [math]::Round(($baselineDuration / 1000) / [double] $baseline.durationSeconds, 3)
        candidateDurationMsPerSecond = [math]::Round(($candidateDuration / 1000) / [double] $candidate.durationSeconds, 3)
    }
}

$comparison = [pscustomobject]@{
    schemaVersion = 1
    baselinePath = (Resolve-Path -LiteralPath $BaselinePath).Path
    candidatePath = (Resolve-Path -LiteralPath $CandidatePath).Path
    baselineDurationSeconds = $baseline.durationSeconds
    candidateDurationSeconds = $candidate.durationSeconds
    baselineDataLossOccurred = $baseline.dataLossOccurred
    candidateDataLossOccurred = $candidate.dataLossOccurred
    metrics = @($rows)
    policy = 'Aggregate trace comparison only. No raw trace events or page data are read into the report.'
}

if ($OutputPath) {
    $parent = Split-Path -Parent $OutputPath
    if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $comparison | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding utf8
}
$comparison | ConvertTo-Json -Depth 6
