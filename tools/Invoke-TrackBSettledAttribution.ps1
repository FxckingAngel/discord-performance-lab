[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [int]$RootPid,

    [ValidateRange(5, 60)]
    [int]$ProbeSeconds = 5,

    [ValidateRange(2, 30)]
    [int]$StableSamples = 6,

    [ValidateRange(0.1, 25)]
    [double]$MaxVariationPercent = 1,

    [ValidateRange(5, 3600)]
    [int]$MeasurementSeconds = 60,

    [ValidateRange(1, 60)]
    [int]$MeasurementIntervalSeconds = 5,

    [ValidateNotNullOrEmpty()]
    [string]$Scenario = 'track-b-settled-attribution',

    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$measure = Join-Path $PSScriptRoot 'Measure-DiscordPhase2Attribution.ps1'
$summary = Join-Path $PSScriptRoot 'Summarize-DiscordPhase2Attribution.ps1'
if (-not (Test-Path -LiteralPath $measure -PathType Leaf)) { throw "Missing measurement tool: $measure" }
if (-not (Test-Path -LiteralPath $summary -PathType Leaf)) { throw "Missing summary tool: $summary" }
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

function Get-LastSample([string]$Path) {
    $raw = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
    return $raw.samples[-1]
}

function Get-Key([object]$Sample) {
    $allProcesses = @($Sample.processes | Sort-Object role, pid)
    $roles = @($allProcesses | Where-Object { $_.role -in @('renderer', 'gpu-process') } | Sort-Object role)
    $pidKey = ($allProcesses | ForEach-Object { "$($_.role):$($_.pid)" }) -join '|'
    $privateWorkingSetValues = @($allProcesses | ForEach-Object {
        if ($null -eq $_.privateWorkingSetMiB) { return $null }
        [double]$_.privateWorkingSetMiB
    })
    $treePrivateWorkingSetMiB = if ($privateWorkingSetValues.Count -eq $allProcesses.Count -and $allProcesses.Count -gt 0) {
        [double](($privateWorkingSetValues | Measure-Object -Sum).Sum)
    }
    else {
        $null
    }
    $window = $Sample.windowState
    return [pscustomobject]@{
        pidKey = $pidKey
        processCount = [int]$Sample.processCount
        windowHandle = if ($window) { $window.handle } else { $null }
        minimized = if ($window) { [bool]$window.minimized } else { $null }
        visible = if ($window) { [bool]$window.visible } else { $null }
        treePrivateWorkingSetMiB = $treePrivateWorkingSetMiB
        rendererPrivateWorkingSetMiB = [double](($roles | Where-Object role -eq 'renderer').privateWorkingSetMiB)
        gpuPrivateWorkingSetMiB = [double](($roles | Where-Object role -eq 'gpu-process').privateWorkingSetMiB)
        timestamp = $Sample.timestamp
    }
}

function Test-Stable([object[]]$Rows) {
    if ($Rows.Count -lt $StableSamples) { return $false }
    $recent = @($Rows | Select-Object -Last $StableSamples)
    $first = $recent[0]
    foreach ($row in $recent) {
        if ($row.pidKey -ne $first.pidKey -or $row.processCount -ne $first.processCount -or $row.windowHandle -ne $first.windowHandle -or $row.minimized -ne $first.minimized -or $row.visible -ne $first.visible) { return $false }
    }
    foreach ($name in @('treePrivateWorkingSetMiB', 'rendererPrivateWorkingSetMiB', 'gpuPrivateWorkingSetMiB')) {
        $values = @($recent | ForEach-Object { [double]$_.$name })
        if (@($recent | Where-Object { $null -eq $_.$name }).Count -gt 0) { return $false }
        $min = ($values | Measure-Object -Minimum).Minimum
        $max = ($values | Measure-Object -Maximum).Maximum
        $mean = ($values | Measure-Object -Average).Average
        if ($mean -le 0 -or (($max - $min) / $mean * 100) -gt $MaxVariationPercent) { return $false }
    }
    return $true
}

$probes = New-Object System.Collections.Generic.List[object]
$stable = $false
for ($i = 1; $i -le 120; $i++) {
    $rawPath = Join-Path $OutputDirectory ("settle-probe-{0:D3}.json" -f $i)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $measure -RootPid $RootPid -DurationSeconds $ProbeSeconds -IntervalSeconds $ProbeSeconds -Scenario "$Scenario-settle-$i" -OutputPath $rawPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Settle probe failed with exit code $LASTEXITCODE." }
    $row = Get-Key (Get-LastSample $rawPath)
    $probes.Add($row)
    $probeArray = @($probes | ForEach-Object { $_ })
    if (Test-Stable -Rows $probeArray) { $stable = $true; break }
}

$settlePath = Join-Path $OutputDirectory 'settle-result.json'
[pscustomobject]@{
    schemaVersion = 1
    scenario = $Scenario
    rootPid = $RootPid
    stable = $stable
    probeSeconds = $ProbeSeconds
    stableSamplesRequired = $StableSamples
    maxVariationPercent = $MaxVariationPercent
    probeCount = $probes.Count
    probes = @($probeArray)
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $settlePath -Encoding UTF8

if (-not $stable) { throw "No stable settle window found after $($probes.Count) probes. See $settlePath." }

$measurementPath = Join-Path $OutputDirectory 'measurement.json'
$summaryPath = Join-Path $OutputDirectory 'measurement-summary.json'
& powershell -NoProfile -ExecutionPolicy Bypass -File $measure -RootPid $RootPid -DurationSeconds $MeasurementSeconds -IntervalSeconds $MeasurementIntervalSeconds -Scenario $Scenario -OutputPath $measurementPath | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Settled measurement failed with exit code $LASTEXITCODE." }
& powershell -NoProfile -ExecutionPolicy Bypass -File $summary -InputPath $measurementPath -OutputPath $summaryPath | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Settled measurement summary failed with exit code $LASTEXITCODE." }

[pscustomobject]@{
    result = 'PASS'
    stable = $true
    settleResult = (Resolve-Path -LiteralPath $settlePath).Path
    measurement = (Resolve-Path -LiteralPath $measurementPath).Path
    summary = (Resolve-Path -LiteralPath $summaryPath).Path
} | ConvertTo-Json -Depth 4
