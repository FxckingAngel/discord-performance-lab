[CmdletBinding()]
param(
    [ValidateRange(5, 120)]
    [int] $DurationSeconds = 20,

    [ValidateNotNullOrEmpty()]
    [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-b-wpr-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))),

    [int] $RootPid = 0,

    [ValidateNotNullOrEmpty()]
    [string] $Scenario = 'unspecified'
)

$ErrorActionPreference = 'Stop'
$wpr = (Get-Command wpr.exe -ErrorAction Stop).Source
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$etlPath = Join-Path $OutputDirectory 'track-b-cpu-resident.etl'
$statusPath = Join-Path $OutputDirectory 'capture-status.json'
$started = $false
$startCode = $null
$stopCode = $null
$errorText = $null
$rootProcessTree = @()

function Get-RootedProcessTree {
    param([Parameter(Mandatory)] [int] $ProcessId)

    $all = @(Get-CimInstance Win32_Process | Select-Object ProcessId,ParentProcessId,Name,CommandLine,CreationDate)
    if (-not @($all | Where-Object { [int] $_.ProcessId -eq $ProcessId })) {
        throw "Root PID $ProcessId was not found."
    }
    $ids = [Collections.Generic.HashSet[int]]::new()
    $queue = [Collections.Generic.Queue[int]]::new()
    [void] $ids.Add($ProcessId)
    $queue.Enqueue($ProcessId)
    while ($queue.Count -gt 0) {
        $parent = $queue.Dequeue()
        foreach ($child in @($all | Where-Object { [int] $_.ParentProcessId -eq $parent })) {
            $childId = [int] $child.ProcessId
            if ($ids.Add($childId)) { $queue.Enqueue($childId) }
        }
    }
    @($all | Where-Object { $ids.Contains([int] $_.ProcessId) } | Sort-Object ProcessId)
}

if ($RootPid -gt 0) {
    $rootProcessTree = @(Get-RootedProcessTree -ProcessId $RootPid)
    $rootProcessTree | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'root-process-tree-before.json') -Encoding utf8
}

try {
    & $wpr -start CPU.Verbose -start ResidentSet.Verbose -filemode
    $startCode = $LASTEXITCODE
    if ($startCode -ne 0) { throw "WPR start failed with exit code $startCode." }
    $started = $true
    Start-Sleep -Seconds $DurationSeconds
}
catch {
    $errorText = $_.Exception.Message
}
finally {
    if ($started) {
        & $wpr -stop $etlPath 'Track B read-only CPU and resident-set diagnostic' -skipPdbGen
        $stopCode = $LASTEXITCODE
    }
    if ($RootPid -gt 0) {
        try {
            @(Get-RootedProcessTree -ProcessId $RootPid) | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'root-process-tree-after.json') -Encoding utf8
        }
        catch {
            $_.Exception.Message | Set-Content -LiteralPath (Join-Path $OutputDirectory 'root-process-tree-after-error.txt') -Encoding utf8
        }
    }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    elevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    durationSeconds = $DurationSeconds
    scenario = $Scenario
    rootPid = if ($RootPid -gt 0) { $RootPid } else { $null }
    rootProcessCountBefore = @($rootProcessTree).Count
    profiles = @('CPU.Verbose', 'ResidentSet.Verbose')
    started = $started
    startCode = $startCode
    stopCode = $stopCode
    etlPath = if (Test-Path -LiteralPath $etlPath) { (Resolve-Path -LiteralPath $etlPath).Path } else { $null }
    error = $errorText
}
$result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $statusPath -Encoding utf8
$result
