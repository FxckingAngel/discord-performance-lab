[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $ProcessId,

    [ValidateRange(2, 60)]
    [int] $IntervalSeconds = 5,

    [ValidateRange(2, 20)]
    [int] $Repetitions = 6,

    [ValidateNotNullOrEmpty()]
    [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-b-allocation-base-watch-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$global:LASTEXITCODE = 0
$residentTool = Join-Path $PSScriptRoot 'Measure-TrackBResidentMemoryTypes.ps1'
if (-not (Test-Path -LiteralPath $residentTool -PathType Leaf)) { throw "Resident-memory classifier was not found: $residentTool" }
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$captures = [System.Collections.Generic.List[object]]::new()
for ($index = 1; $index -le $Repetitions; $index++) {
    $process = Get-Process -Id $ProcessId -ErrorAction Stop
    if ($index -gt 1) { Start-Sleep -Seconds $IntervalSeconds }
    $path = Join-Path $OutputDirectory ("capture-{0:D2}.json" -f $index)
    & $residentTool -ProcessId $ProcessId -Role renderer -OutputPath $path | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Resident-memory capture failed at repetition $index." }
    $data = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
    $groups = @($data.largestPrivateWritableRegions | Group-Object allocationBase | ForEach-Object {
        [pscustomobject]@{
            allocationBase = [string]$_.Name
            regionCount = @($_.Group).Count
            residentBytes = [double](($_.Group | Measure-Object residentBytes -Sum).Sum)
            committedBytes = [double](($_.Group | Measure-Object committedBytes -Sum).Sum)
        }
    })
    $captures.Add([pscustomobject]@{
        repetition = $index
        capturedAt = $data.capturedAt
        processId = $data.processId
        residentMiB = [double]$data.memory.residentValidBytes / 1MB
        privateWritableResidentMiB = [double]$data.memory.privateWritableResidentBytes / 1MB
        groups = $groups
        sourcePath = (Resolve-Path -LiteralPath $path).Path
    })
}

$bases = @($captures.groups | ForEach-Object allocationBase | Sort-Object -Unique)
$summary = foreach ($base in $bases) {
    $rows = @($captures | ForEach-Object { $_.groups | Where-Object allocationBase -eq $base } | Sort-Object repetition)
    $resident = @($rows | ForEach-Object { [double]$_.residentBytes / 1MB })
    $committed = @($rows | ForEach-Object { [double]$_.committedBytes / 1MB })
    [pscustomobject]@{
        allocationBase = $base
        observations = $rows.Count
        residentMiBMinimum = [math]::Round(($resident | Measure-Object -Minimum).Minimum, 3)
        residentMiBMaximum = [math]::Round(($resident | Measure-Object -Maximum).Maximum, 3)
        residentMiBDelta = [math]::Round(($resident[-1] - $resident[0]), 3)
        committedMiBMinimum = [math]::Round(($committed | Measure-Object -Minimum).Minimum, 3)
        committedMiBMaximum = [math]::Round(($committed | Measure-Object -Maximum).Maximum, 3)
        committedMiBDelta = [math]::Round(($committed[-1] - $committed[0]), 3)
    }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    capturedAt = (Get-Date).ToUniversalTime().ToString('o')
    processId = $ProcessId
    repetitions = $Repetitions
    intervalSeconds = $IntervalSeconds
    policy = 'Read-only per-process allocation-base watch. No navigation, renderer setting, working-set trimming, garbage collection, or page-state change was requested.'
    captures = @($captures)
    allocationBaseSummary = @($summary | Sort-Object residentMiBMaximum -Descending)
}
$outputPath = Join-Path $OutputDirectory 'manifest.json'
$result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $outputPath -Encoding utf8
[pscustomobject]@{
    processId = $ProcessId
    repetitions = $Repetitions
    allocationBaseCount = $summary.Count
    outputPath = $outputPath
}
