[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $InputPath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath
)

function Get-Percentile {
    param([object[]] $Values, [double] $Percentile)

    $valid = @($Values | Where-Object { $_ -ne $null } | ForEach-Object { [double] $_ } | Sort-Object)
    if ($valid.Count -eq 0) { return $null }
    $index = [math]::Min($valid.Count - 1, [math]::Max(0, [math]::Ceiling($Percentile * $valid.Count) - 1))
    return [math]::Round([double] $valid[$index], 3)
}

function Get-OptionalSum {
    param([object[]] $Rows, [string] $Property)

    $values = @($Rows | ForEach-Object {
        $propertyValue = $_.PSObject.Properties[$Property]
        if ($null -ne $propertyValue) { $propertyValue.Value }
    } | Where-Object { $_ -ne $null })
    if ($values.Count -eq 0) { return $null }
    return [math]::Round((@($values | Measure-Object -Sum).Sum), 3)
}

$input = Get-Content -Raw -LiteralPath $InputPath | ConvertFrom-Json
$firstProcess = $null
foreach ($sample in @($input.samples)) {
    foreach ($process in @($sample.processes)) {
        if ($null -ne $process) { $firstProcess = $process; break }
    }
    if ($null -ne $firstProcess) { break }
}
if ($null -eq $firstProcess) { throw 'The attribution input contains no process rows.' }
$propertyNames = @($firstProcess.PSObject.Properties | ForEach-Object Name)
if ('workingSetMiB' -notin $propertyNames -and 'workingSetBytes' -in $propertyNames) {
    throw 'This summarizer requires Measure-DiscordPhase2Attribution output with MiB fields. The input is byte-based Measure-DiscordProcessTree output; use its byte-aware reporting path instead.'
}
foreach ($requiredProperty in @('workingSetMiB', 'privateWorkingSetMiB', 'privateMemoryMiB')) {
    if ($requiredProperty -notin $propertyNames) { throw "The attribution input is missing required field: $requiredProperty" }
}
$windowStates = @($input.samples | ForEach-Object { $_.windowState } | Where-Object { $_ -ne $null })
$roleSamples = foreach ($sample in @($input.samples)) {
    foreach ($group in @($sample.processes | Where-Object role | Group-Object role)) {
        $valid = @($group.Group | Where-Object {
            $statusProperty = $_.PSObject.Properties['status']
            $null -eq $statusProperty -or $statusProperty.Value -ne 'unavailable'
        })
        if ($valid.Count -eq 0) { continue }
        [pscustomobject]@{
            role = $group.Name
            timestamp = $sample.timestamp
            processCount = $valid.Count
            workingSetMiB = Get-OptionalSum -Rows $valid -Property 'workingSetMiB'
            privateWorkingSetMiB = Get-OptionalSum -Rows $valid -Property 'privateWorkingSetMiB'
            workingSetShareableMiB = Get-OptionalSum -Rows $valid -Property 'workingSetShareableMiB'
            privateMemoryMiB = Get-OptionalSum -Rows $valid -Property 'privateMemoryMiB'
            cpuPercentOfTotal = Get-OptionalSum -Rows $valid -Property 'cpuPercentOfTotal'
            pageFaultsPerSecond = Get-OptionalSum -Rows $valid -Property 'pageFaultsPerSecond'
            ioReadBytesPerSecond = Get-OptionalSum -Rows $valid -Property 'ioReadBytesPerSecond'
            ioWriteBytesPerSecond = Get-OptionalSum -Rows $valid -Property 'ioWriteBytesPerSecond'
            handles = Get-OptionalSum -Rows $valid -Property 'handles'
            threads = Get-OptionalSum -Rows $valid -Property 'threads'
        }
    }
}

$roles = foreach ($group in @($roleSamples | Group-Object role)) {
    $rows = @($group.Group)
    [pscustomobject]@{
        role = $group.Name
        samples = $rows.Count
        workingSetMedianMiB = Get-Percentile @($rows.workingSetMiB) 0.50
        workingSetP95MiB = Get-Percentile @($rows.workingSetMiB) 0.95
        privateWorkingSetMedianMiB = Get-Percentile @($rows.privateWorkingSetMiB) 0.50
        privateWorkingSetP95MiB = Get-Percentile @($rows.privateWorkingSetMiB) 0.95
        workingSetShareableMedianMiB = Get-Percentile @($rows.workingSetShareableMiB) 0.50
        workingSetShareableP95MiB = Get-Percentile @($rows.workingSetShareableMiB) 0.95
        privateMemoryMedianMiB = Get-Percentile @($rows.privateMemoryMiB) 0.50
        privateMemoryP95MiB = Get-Percentile @($rows.privateMemoryMiB) 0.95
        cpuMedianPercentOfTotal = Get-Percentile @($rows.cpuPercentOfTotal) 0.50
        cpuP95PercentOfTotal = Get-Percentile @($rows.cpuPercentOfTotal) 0.95
        pageFaultsMedianPerSecond = Get-Percentile @($rows.pageFaultsPerSecond) 0.50
        pageFaultsP95PerSecond = Get-Percentile @($rows.pageFaultsPerSecond) 0.95
        ioReadMedianBytesPerSecond = Get-Percentile @($rows.ioReadBytesPerSecond) 0.50
        ioWriteMedianBytesPerSecond = Get-Percentile @($rows.ioWriteBytesPerSecond) 0.50
        handlesMedian = Get-Percentile @($rows.handles) 0.50
        threadsMedian = Get-Percentile @($rows.threads) 0.50
    }
}
$processSamples = foreach ($sample in @($input.samples)) {
    foreach ($process in @($sample.processes | Where-Object {
        $statusProperty = $_.PSObject.Properties['status']
        ($null -eq $statusProperty -or $statusProperty.Value -ne 'unavailable') -and $null -ne $_.pid
    })) {
        [pscustomobject]@{
            pid = [int] $process.pid
            parentPid = if ($null -ne $process.parentPid) { [int] $process.parentPid } else { $null }
            role = $process.role
            lifetimeSeconds = $process.lifetimeSeconds
            workingSetMiB = $process.workingSetMiB
            privateWorkingSetMiB = $process.privateWorkingSetMiB
            workingSetShareableMiB = $process.workingSetShareableMiB
            privateMemoryMiB = $process.privateMemoryMiB
            pagedMemoryMiB = $process.pagedMemoryMiB
            cpuPercentOfTotal = $process.cpuPercentOfTotal
            pageFaultsPerSecond = $process.pageFaultsPerSecond
            ioReadBytesPerSecond = $process.ioReadBytesPerSecond
            ioWriteBytesPerSecond = $process.ioWriteBytesPerSecond
            handles = $process.handles
            threads = $process.threads
        }
    }
}
$processes = foreach ($group in @($processSamples | Group-Object pid)) {
    $rows = @($group.Group)
    $first = $rows | Select-Object -First 1
    [pscustomobject]@{
        pid = [int] $group.Name
        parentPid = $first.parentPid
        role = $first.role
        samples = $rows.Count
        lifetimeSecondsMedian = Get-Percentile @($rows.lifetimeSeconds) 0.50
        workingSetMedianMiB = Get-Percentile @($rows.workingSetMiB) 0.50
        workingSetP95MiB = Get-Percentile @($rows.workingSetMiB) 0.95
        privateWorkingSetMedianMiB = Get-Percentile @($rows.privateWorkingSetMiB) 0.50
        privateWorkingSetP95MiB = Get-Percentile @($rows.privateWorkingSetMiB) 0.95
        workingSetShareableMedianMiB = Get-Percentile @($rows.workingSetShareableMiB) 0.50
        workingSetShareableP95MiB = Get-Percentile @($rows.workingSetShareableMiB) 0.95
        privateMemoryMedianMiB = Get-Percentile @($rows.privateMemoryMiB) 0.50
        privateMemoryP95MiB = Get-Percentile @($rows.privateMemoryMiB) 0.95
        pagedMemoryMedianMiB = Get-Percentile @($rows.pagedMemoryMiB) 0.50
        cpuMedianPercentOfTotal = Get-Percentile @($rows.cpuPercentOfTotal) 0.50
        cpuP95PercentOfTotal = Get-Percentile @($rows.cpuPercentOfTotal) 0.95
        pageFaultsMedianPerSecond = Get-Percentile @($rows.pageFaultsPerSecond) 0.50
        pageFaultsP95PerSecond = Get-Percentile @($rows.pageFaultsPerSecond) 0.95
        ioReadMedianBytesPerSecond = Get-Percentile @($rows.ioReadBytesPerSecond) 0.50
        ioWriteMedianBytesPerSecond = Get-Percentile @($rows.ioWriteBytesPerSecond) 0.50
        handlesMedian = Get-Percentile @($rows.handles) 0.50
        threadsMedian = Get-Percentile @($rows.threads) 0.50
    }
}
$treeSamples = foreach ($sample in @($input.samples)) {
    $valid = @($sample.processes | Where-Object {
        $statusProperty = $_.PSObject.Properties['status']
        $null -eq $statusProperty -or $statusProperty.Value -ne 'unavailable'
    })
    if ($valid.Count -eq 0) { continue }
    [pscustomobject]@{
        timestamp = $sample.timestamp
        processCount = $valid.Count
        workingSetMiB = Get-OptionalSum -Rows $valid -Property 'workingSetMiB'
        privateWorkingSetMiB = Get-OptionalSum -Rows $valid -Property 'privateWorkingSetMiB'
        workingSetShareableMiB = Get-OptionalSum -Rows $valid -Property 'workingSetShareableMiB'
        privateMemoryMiB = Get-OptionalSum -Rows $valid -Property 'privateMemoryMiB'
        cpuPercentOfTotal = Get-OptionalSum -Rows $valid -Property 'cpuPercentOfTotal'
    }
}
$treeSummary = [pscustomobject]@{
    samples = @($treeSamples).Count
    processCountMedian = Get-Percentile @($treeSamples.processCount) 0.50
    processCountP95 = Get-Percentile @($treeSamples.processCount) 0.95
    workingSetMedianMiB = Get-Percentile @($treeSamples.workingSetMiB) 0.50
    workingSetP95MiB = Get-Percentile @($treeSamples.workingSetMiB) 0.95
    privateWorkingSetMedianMiB = Get-Percentile @($treeSamples.privateWorkingSetMiB) 0.50
    privateWorkingSetP95MiB = Get-Percentile @($treeSamples.privateWorkingSetMiB) 0.95
    workingSetShareableMedianMiB = Get-Percentile @($treeSamples.workingSetShareableMiB) 0.50
    workingSetShareableP95MiB = Get-Percentile @($treeSamples.workingSetShareableMiB) 0.95
    privateMemoryMedianMiB = Get-Percentile @($treeSamples.privateMemoryMiB) 0.50
    privateMemoryP95MiB = Get-Percentile @($treeSamples.privateMemoryMiB) 0.95
    cpuMedianPercentOfTotal = Get-Percentile @($treeSamples.cpuPercentOfTotal) 0.50
    cpuP95PercentOfTotal = Get-Percentile @($treeSamples.cpuPercentOfTotal) 0.95
}
$ranked = @($roles | Sort-Object workingSetMedianMiB -Descending)
for ($index = 0; $index -lt $ranked.Count; $index++) {
    $ranked[$index] | Add-Member -NotePropertyName workingSetRank -NotePropertyValue ($index + 1)
}

$summary = [pscustomobject]@{
    schemaVersion = 2
    source = $InputPath
    scenario = $input.scenario
    rootPid = $input.rootPid
    sampleCount = @($input.samples).Count
    displayRefreshRate = $input.environment.displayRefreshRate
    displayWidth = $input.environment.displayWidth
    displayHeight = $input.environment.displayHeight
    windowStates = $windowStates
    processTree = $treeSummary
    roles = $ranked
    processes = @($processes | Sort-Object privateWorkingSetMedianMiB -Descending)
}
$parent = Split-Path -Parent $OutputPath
if ($parent) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$ranked | Select-Object workingSetRank,role,workingSetMedianMiB,privateWorkingSetMedianMiB,workingSetShareableMedianMiB,privateMemoryMedianMiB,cpuMedianPercentOfTotal,pageFaultsMedianPerSecond,handlesMedian,threadsMedian | Format-Table -AutoSize
