[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $RootPid,

    [string] $OutputPath = (Join-Path (Get-Location) 'memory-source-comparison.json')
)

function Get-RootedProcesses {
    $all = @(Get-CimInstance Win32_Process)
    if (-not @($all | Where-Object { [int] $_.ProcessId -eq $RootPid })) { throw "Root PID $RootPid was not found." }
    $pids = [System.Collections.Generic.HashSet[int]]::new()
    $queue = [System.Collections.Generic.Queue[int]]::new()
    [void] $pids.Add($RootPid)
    $queue.Enqueue($RootPid)
    while ($queue.Count -gt 0) {
        $parent = $queue.Dequeue()
        foreach ($row in @($all | Where-Object { [int] $_.ParentProcessId -eq $parent })) {
            if ($pids.Add([int] $row.ProcessId)) { $queue.Enqueue([int] $row.ProcessId) }
        }
    }
    return @($all | Where-Object { $pids.Contains([int] $_.ProcessId) })
}

$rooted = @(Get-RootedProcesses)
$rootedPids = @($rooted | ForEach-Object { [int] $_.ProcessId })
$wmiByPid = @{}
foreach ($row in @(Get-CimInstance Win32_PerfFormattedData_PerfProc_Process)) {
    $id = [int] $row.IDProcess
    if ($rootedPids -contains $id) { $wmiByPid[$id] = $row }
}

$counterByPid = @{}
try {
    $counterResult = Get-Counter -Counter @(
        '\Process(*)\ID Process',
        '\Process(*)\Working Set - Private',
        '\Process(*)\Private Bytes'
    ) -MaxSamples 1 -ErrorAction Stop
    $instanceByName = @{}
    foreach ($sample in @($counterResult.CounterSamples)) {
        if ($sample.Path -notmatch '\\Process\(([^)]+)\)\\(.+)$') { continue }
        $instance = $Matches[1].ToLowerInvariant()
        $metric = $Matches[2]
        if (-not $instanceByName.ContainsKey($instance)) { $instanceByName[$instance] = @{} }
        $instanceByName[$instance][$metric] = [double] $sample.CookedValue
    }
    foreach ($entry in $instanceByName.GetEnumerator()) {
        if (-not $entry.Value.ContainsKey('ID Process')) { continue }
        $id = [int] $entry.Value['ID Process']
        if ($rootedPids -contains $id) { $counterByPid[$id] = $entry.Value }
    }
}
catch {
    $counterError = $_.Exception.Message
}

$rows = foreach ($process in $rooted) {
    $id = [int] $process.ProcessId
    $wmi = $wmiByPid[$id]
    $counter = $counterByPid[$id]
    [pscustomobject]@{
        pid = $id
        name = $process.Name
        wmiPrivateWorkingSetBytes = if ($wmi) { [double] $wmi.WorkingSetPrivate } else { $null }
        counterPrivateWorkingSetBytes = if ($counter -and $counter.ContainsKey('Working Set - Private')) { $counter['Working Set - Private'] } else { $null }
        workingSetPrivateDifferenceBytes = if ($wmi -and $counter -and $counter.ContainsKey('Working Set - Private')) { [double] $counter['Working Set - Private'] - [double] $wmi.WorkingSetPrivate } else { $null }
        wmiPrivateBytes = if ($wmi) { [double] $wmi.PrivateBytes } else { $null }
        counterPrivateBytes = if ($counter -and $counter.ContainsKey('Private Bytes')) { $counter['Private Bytes'] } else { $null }
        privateBytesDifferenceBytes = if ($wmi -and $counter -and $counter.ContainsKey('Private Bytes')) { [double] $counter['Private Bytes'] - [double] $wmi.PrivateBytes } else { $null }
    }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    capturedAt = [DateTime]::UtcNow.ToString('o')
    rootPid = $RootPid
    processCount = $rows.Count
    counterError = $counterError
    processes = @($rows)
    totals = [pscustomobject]@{
        wmiPrivateWorkingSetBytes = [double](($rows | Measure-Object wmiPrivateWorkingSetBytes -Sum).Sum)
        counterPrivateWorkingSetBytes = [double](($rows | Measure-Object counterPrivateWorkingSetBytes -Sum).Sum)
        wmiPrivateBytes = [double](($rows | Measure-Object wmiPrivateBytes -Sum).Sum)
        counterPrivateBytes = [double](($rows | Measure-Object counterPrivateBytes -Sum).Sum)
    }
}
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$result | Select-Object rootPid,processCount,@{Name='wmiPrivateWsMiB';Expression={[math]::Round($_.totals.wmiPrivateWorkingSetBytes/1MB,3)}},@{Name='counterPrivateWsMiB';Expression={[math]::Round($_.totals.counterPrivateWorkingSetBytes/1MB,3)}},@{Name='wmiPrivateBytesMiB';Expression={[math]::Round($_.totals.wmiPrivateBytes/1MB,3)}},@{Name='counterPrivateBytesMiB';Expression={[math]::Round($_.totals.counterPrivateBytes/1MB,3)}} | Format-List
