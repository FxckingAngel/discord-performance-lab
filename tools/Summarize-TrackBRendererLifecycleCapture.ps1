[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ManifestPath,

    [string] $OutputPath = (Join-Path (Get-Location) ('artifacts/track-b-renderer-lifecycle-summary-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json') )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-CheckpointRecords($Manifest) {
    foreach ($entry in @($Manifest.checkpoints)) {
        if ($entry -is [array] -and $entry.Count -eq 2 -and $null -ne $entry[1].name) {
            $entry[1]
        }
        else {
            $entry
        }
    }
}

function Get-MetricSum($Rows, [string] $Property) {
    $values = @($Rows | ForEach-Object {
        if ($_.PSObject.Properties.Name -contains $Property) {
            $value = $_ | Select-Object -ExpandProperty $Property
            if ($null -ne $value) { [double]$value }
        }
    })
    if ($values.Count -eq 0) { return $null }
    return [math]::Round(($values | Measure-Object -Sum).Sum, 3)
}

function Get-Percentile($Values, [double] $Percentile) {
    $valid = @($Values | Where-Object { $null -ne $_ } | ForEach-Object { [double]$_ } | Sort-Object)
    if ($valid.Count -eq 0) { return $null }
    $index = [math]::Min($valid.Count - 1, [math]::Max(0, [math]::Ceiling($Percentile * $valid.Count) - 1))
    return [math]::Round($valid[$index], 3)
}

$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
$rows = foreach ($checkpoint in @(Get-CheckpointRecords $manifest)) {
    $process = Get-Content -Raw -LiteralPath $checkpoint.processPath | ConvertFrom-Json
    $sample = @($process.samples)[-1]
    $sampleRows = foreach ($sampleEntry in @($process.samples)) {
        $validSampleRows = @($sampleEntry.processes | Where-Object {
            $hasStatus = $_.PSObject.Properties.Name -contains 'status'
            (-not $hasStatus -or $_.status -ne 'unavailable') -and $null -ne $_.pid
        })
        [pscustomobject]@{
            totalCpu = Get-MetricSum $validSampleRows 'cpuPercentOfTotal'
            rendererCpu = Get-MetricSum @($validSampleRows | Where-Object { [string]$_.role -eq 'renderer' }) 'cpuPercentOfTotal'
        }
    }
    $processRows = @($sample.processes | Where-Object {
        $hasStatus = $_.PSObject.Properties.Name -contains 'status'
        (-not $hasStatus -or $_.status -ne 'unavailable') -and $null -ne $_.pid
    })
    $cdp = Get-Content -Raw -LiteralPath $checkpoint.cdpPath | ConvertFrom-Json
    $cdpCheckpoint = $cdp.checkpoint
    $rendererRows = @($processRows | Where-Object { [string]$_.role -eq 'renderer' })
    $roleRows = foreach ($role in @($processRows.role | Sort-Object -Unique)) {
        $matching = @($processRows | Where-Object { [string]$_.role -eq [string]$role })
        [pscustomobject]@{
            role = [string]$role
            processCount = $matching.Count
            privateWorkingSetMiB = Get-MetricSum $matching 'privateWorkingSetMiB'
            workingSetMiB = Get-MetricSum $matching 'workingSetMiB'
            privateBytesMiB = Get-MetricSum $matching 'privateMemoryMiB'
        }
    }
    [pscustomobject]@{
        checkpoint = [string]$checkpoint.name
        applicationReady = [bool]$checkpoint.applicationReady
        routeClass = [string]$cdpCheckpoint.routeClass
        rendererPids = @($processRows | Where-Object { [string]$_.role -eq 'renderer' } | ForEach-Object { [int]$_.pid })
        processCount = $processRows.Count
        sampleCount = @($process.samples).Count
        totalPrivateWorkingSetMiB = Get-MetricSum $processRows 'privateWorkingSetMiB'
        totalWorkingSetMiB = Get-MetricSum $processRows 'workingSetMiB'
        totalPrivateBytesMiB = Get-MetricSum $processRows 'privateMemoryMiB'
        totalCpuMedianPercent = Get-Percentile @($sampleRows.totalCpu) 0.50
        totalCpuP95Percent = Get-Percentile @($sampleRows.totalCpu) 0.95
        rendererPrivateWorkingSetMiB = Get-MetricSum $rendererRows 'privateWorkingSetMiB'
        rendererWorkingSetMiB = Get-MetricSum $rendererRows 'workingSetMiB'
        rendererPrivateBytesMiB = Get-MetricSum $rendererRows 'privateMemoryMiB'
        rendererCpuMedianPercent = Get-Percentile @($sampleRows.rendererCpu) 0.50
        rendererCpuP95Percent = Get-Percentile @($sampleRows.rendererCpu) 0.95
        v8UsedMiB = if ($cdpCheckpoint.heapUsage) { [math]::Round(([double]$cdpCheckpoint.heapUsage.usedSize / 1MB), 3) } else { $null }
        v8TotalMiB = if ($cdpCheckpoint.heapUsage) { [math]::Round(([double]$cdpCheckpoint.heapUsage.totalSize / 1MB), 3) } else { $null }
        domNodes = if ($cdpCheckpoint.domCounters) { [int]$cdpCheckpoint.domCounters.nodes } else { $null }
        documents = if ($cdpCheckpoint.domCounters) { [int]$cdpCheckpoint.domCounters.documents } else { $null }
        eventListeners = if ($cdpCheckpoint.domCounters) { [int]$cdpCheckpoint.domCounters.jsEventListeners } else { $null }
        rendererPrivateResidentOutsideV8MiB = if ($rendererRows.Count -gt 0 -and $cdpCheckpoint.heapUsage) { [math]::Round((Get-MetricSum $rendererRows 'privateWorkingSetMiB') - ([double]$cdpCheckpoint.heapUsage.usedSize / 1MB), 3) } else { $null }
        roleTotals = @($roleRows)
    }
}

$result = [ordered]@{
    schemaVersion = 1
    summarizedAt = (Get-Date).ToUniversalTime().ToString('o')
    sourceManifest = (Resolve-Path -LiteralPath $ManifestPath).Path
    mode = [string]$manifest.mode
    policy = 'Sanitized lifecycle aggregates. Raw process, CDP, and virtual-memory artifacts remain local/private. The automatic route is not a manually confirmed canonical channel.'
    rows = @($rows)
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result
