[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $EtlPath,

    [ValidateNotNullOrEmpty()]
    [string] $OutputDirectory = (Join-Path (Split-Path -Parent $EtlPath) 'tracerpt')
)

$ErrorActionPreference = 'Stop'
$tracerpt = (Get-Command tracerpt.exe -ErrorAction Stop).Source
$resolvedEtl = (Resolve-Path -LiteralPath $EtlPath).Path
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$summaryPath = Join-Path $OutputDirectory 'tracerpt-summary.txt'
$reportPath = Join-Path $OutputDirectory 'tracerpt-report.xml'
$aggregatePath = Join-Path $OutputDirectory 'wpr-aggregate-summary.json'

& $tracerpt $resolvedEtl -y -summary $summaryPath -report $reportPath
if ($LASTEXITCODE -ne 0) {
    throw "tracerpt failed with exit code $LASTEXITCODE."
}

[xml] $report = Get-Content -LiteralPath $reportPath -Raw
$collection = $report.Report.Section | Where-Object { $_.key -eq '-90000' } |
    ForEach-Object { $_.Table | Where-Object { $_.name -eq 'collection' } } |
    Select-Object -ExpandProperty Item -First 1

function Get-ReportValue {
    param(
        [Parameter(Mandatory)] $Item,
        [Parameter(Mandatory)] [string] $Name
    )

    $data = @($Item.Data | Where-Object { $_.name -eq $Name } | Select-Object -First 1)
    if ($data.Count -eq 0) { return $null }
    return [string] $data[0].'#text'
}

$eventItems = @($report.Report.Section | ForEach-Object {
    $_.Table | Where-Object { $_.name -eq 'events' } | Select-Object -ExpandProperty Item
})

function Get-EventCount {
    param(
        [Parameter(Mandatory)] [string] $Event,
        [Parameter(Mandatory)] [string] $Opcode
    )

    $item = $eventItems | Where-Object {
        (Get-ReportValue $_ 'event') -eq $Event -and (Get-ReportValue $_ 'opcode') -eq $Opcode
    } | Select-Object -First 1
    if ($null -eq $item) { return $null }
    $value = Get-ReportValue $item 'count'
    if ($null -eq $value) { return $null }
    return [int64] ($value -replace ',', '')
}

$summaryText = Get-Content -LiteralPath $summaryPath -Raw
function Get-SummaryNumber {
    param([Parameter(Mandatory)] [string] $Label)
    $match = [regex]::Match($summaryText, "(?m)^\s*${Label}\s+([0-9,]+)\s*$")
    if (-not $match.Success) { return $null }
    return [int64] ($match.Groups[1].Value -replace ',', '')
}

$result = [ordered]@{
    schemaVersion = 1
    sourceEtl = $resolvedEtl
    generatedAt = (Get-Date).ToString('o')
    collection = [ordered]@{
        start = Get-ReportValue $collection 'start'
        end = Get-ReportValue $collection 'end'
        durationSeconds = Get-ReportValue $collection 'duration'
        buffers = Get-ReportValue $collection 'buffers'
        eventsProcessed = Get-ReportValue $collection 'events'
        lostEvents = Get-ReportValue $collection 'lostEvents'
    }
    aggregateEventCounts = [ordered]@{
        cpuSamples = Get-EventCount 'PerfInfo' 'SampleProf'
        stackWalks = Get-EventCount 'StackWalk' 'Stack'
        hardFaults = Get-EventCount 'PageFault' 'HardFault'
        diskReads = Get-EventCount 'DiskIo' 'Read'
        diskWrites = Get-EventCount 'DiskIo' 'Write'
        processStarts = Get-EventCount 'Process' 'Start'
        processEnds = Get-EventCount 'Process' 'End'
        threadReadyEvents = Get-EventCount 'Thread' 'ReadyThread'
    }
    privacy = [ordered]@{
        rawEventPayloadsPublished = $false
        reportAndSummaryRemainLocal = $true
        processTreeFilteringApplied = $false
    }
}
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $aggregatePath -Encoding utf8
[pscustomobject] $result
