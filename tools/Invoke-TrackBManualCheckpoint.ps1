[CmdletBinding()]
param(
    [string] $ExecutablePath,

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'KoroneDiscordShell',

    [ValidateRange(5, 86400)]
    [int] $DurationSeconds = 600,

    [ValidateRange(1, 60)]
    [int] $IntervalSeconds = 30,

    [ValidateNotNullOrEmpty()]
    [string] $Scenario = 'authenticated-manual-checkpoint',

    [string] $OutputPath = (Join-Path (Get-Location) ('benchmarks/raw/track-b-manual-checkpoint-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json'))
)

$measureTool = Join-Path $PSScriptRoot 'Measure-DiscordProcessTree.ps1'
if (-not (Test-Path -LiteralPath $measureTool -PathType Leaf)) {
    throw "Process-tree measurement tool was not found: $measureTool"
}

function Get-TrackBProcess {
    $processes = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    if ($processes.Count -eq 0) { return $null }
    if ($processes.Count -gt 1) {
        throw "More than one $ProcessName process is running. Pass a single-process state before using the manual checkpoint."
    }
    return $processes[0]
}

$process = Get-TrackBProcess
if (-not $process) {
    if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
        throw "Track B is not running. Pass -ExecutablePath to launch it, or start it manually first."
    }
    $resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
    $process = Start-Process -FilePath $resolvedExecutable -PassThru
    Start-Sleep -Seconds 3
    $process = Get-TrackBProcess
    if (-not $process) { throw "Track B did not remain running after launch." }
}

Write-Host "Track B process detected: PID $($process.Id)"
Write-Host 'Complete these steps manually:'
Write-Host '1. Log into Discord normally if needed.'
Write-Host '2. Navigate to the requested test channel or DM.'
Write-Host '3. Leave the window at the requested route and workload.'
Write-Host '4. Confirm the application is ready for measurement.'
$confirmation = Read-Host 'Type READY to begin measurement'
if ($confirmation -cne 'READY') {
    throw 'Manual checkpoint was not confirmed. No measurement was started.'
}

$process = Get-TrackBProcess
if (-not $process) { throw 'Track B exited before measurement began.' }
& $measureTool -ProcessName $ProcessName -RootPid $process.Id -DurationSeconds $DurationSeconds -IntervalSeconds $IntervalSeconds -Scenario $Scenario -OutputPath $OutputPath
