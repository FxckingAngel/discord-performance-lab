[CmdletBinding()]
param(
    [ValidateSet('active-text', 'channel-navigation', 'scrolling', 'media-heavy', 'voice-idle', 'active-voice', 'video', 'screen-sharing', 'notifications', 'gaming-background')]
    [string] $Scenario = 'active-text',

    [ValidateRange(1, 10)]
    [int] $Repetitions = 3,

    [ValidateRange(5, 86400)]
    [int] $DurationSeconds = 600,

    [ValidateRange(1, 60)]
    [int] $IntervalSeconds = 10,

    [switch] $RequireSettled,

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'KoroneDiscordShell',

    [ValidateNotNullOrEmpty()]
    [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-b-active-' + $Scenario + '-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

$ErrorActionPreference = 'Stop'
$featureCheckpointTool = Join-Path $PSScriptRoot 'Invoke-TrackBFeatureScenarioCheckpoint.ps1'
if (-not (Test-Path -LiteralPath $featureCheckpointTool -PathType Leaf)) {
    throw "Feature scenario checkpoint tool was not found: $featureCheckpointTool"
}

function Get-TrackBRoot {
    $processes = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    if ($processes.Count -eq 0) {
        throw "Track B process '$ProcessName' is not running. Start the shell before using this checkpoint."
    }
    if ($processes.Count -ne 1) {
        throw "Expected exactly one Track B process named '$ProcessName', found $($processes.Count)."
    }
    if (-not $processes[0].Responding) {
        throw "Track B process PID $($processes[0].Id) is not responding."
    }
    return $processes[0]
}

$scenarioContracts = @{
    'active-text' = [pscustomobject]@{ workload = 'typing and sending messages'; voice = $false; video = $false; screenShare = $false; visibleMedia = $true }
    'channel-navigation' = [pscustomobject]@{ workload = 'normal channel or DM navigation'; voice = $false; video = $false; screenShare = $false; visibleMedia = $true }
    'scrolling' = [pscustomobject]@{ workload = 'sustained history scrolling'; voice = $false; video = $false; screenShare = $false; visibleMedia = $true }
    'media-heavy' = [pscustomobject]@{ workload = 'visible GIFs, stickers, images, or embeds'; voice = $false; video = $false; screenShare = $false; visibleMedia = $true }
    'voice-idle' = [pscustomobject]@{ workload = 'connected voice with no active speech'; voice = $true; video = $false; screenShare = $false; visibleMedia = $true }
    'active-voice' = [pscustomobject]@{ workload = 'voice with active speech'; voice = $true; video = $false; screenShare = $false; visibleMedia = $true }
    'video' = [pscustomobject]@{ workload = 'active video call'; voice = $true; video = $true; screenShare = $false; visibleMedia = $true }
    'screen-sharing' = [pscustomobject]@{ workload = 'active screen sharing'; voice = $true; video = $false; screenShare = $true; visibleMedia = $true }
    'notifications' = [pscustomobject]@{ workload = 'notification receive and open'; voice = $false; video = $false; screenShare = $false; visibleMedia = $true }
    'gaming-background' = [pscustomobject]@{ workload = 'Discord in the background during gaming'; voice = $false; video = $false; screenShare = $false; visibleMedia = $true }
}
$contract = $scenarioContracts[$Scenario]
if ($null -eq $contract) { throw "No checkpoint contract is defined for scenario '$Scenario'." }

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$outputDirectories = [System.Collections.Generic.List[string]]::new()
$rootPids = [System.Collections.Generic.List[int]]::new()

for ($index = 1; $index -le $Repetitions; $index++) {
    $root = Get-TrackBRoot
    $rootPids.Add([int] $root.Id)
    $repeatDirectory = Join-Path $OutputDirectory ('repeat-{0:D2}' -f $index)
    New-Item -ItemType Directory -Path $repeatDirectory -Force | Out-Null

    Write-Host "Track B PID $($root.Id), scenario '$Scenario', repetition $index of $Repetitions."
    Write-Host "Prepare: $($contract.workload)."
    Write-Host 'Keep the same account, route, window size, display, and workload for this capture.'
    Write-Host 'Do not disable or pause visible Discord features to reduce resource usage.'
    $confirmation = Read-Host 'Type READY after the state is fully initialized and ready'
    if ($confirmation -cne 'READY') {
        throw "Manual checkpoint was not confirmed for repetition $index. No result was recorded for that repetition."
    }

    $childParameters = @{
        ProcessName = $ProcessName
        Scenario = $Scenario
        DurationSeconds = $DurationSeconds
        IntervalSeconds = $IntervalSeconds
        OutputDirectory = $repeatDirectory
    }
    if ($RequireSettled) { $childParameters.RequireSettled = $true }
    & $featureCheckpointTool @childParameters | Out-Host
    if (-not $?) { throw "Feature scenario capture failed for repetition $index." }

    $treePath = Join-Path $repeatDirectory 'process-tree.json'
    $manifestPath = Join-Path $repeatDirectory 'resident-types.json'
    if (-not (Test-Path -LiteralPath $treePath -PathType Leaf) -or -not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Feature scenario capture did not produce the expected sanitized outputs for repetition $index."
    }
    $outputDirectories.Add((Resolve-Path -LiteralPath $repeatDirectory).Path)
}

$report = [pscustomobject]@{
    schemaVersion = 1
    capturedAt = (Get-Date).ToUniversalTime().ToString('o')
    processName = $ProcessName
    scenario = $Scenario
    repetitions = $Repetitions
    requireSettled = [bool] $RequireSettled
    rootPids = @($rootPids)
    checkpointMode = 'manual-ready-per-repetition'
    scenarioContract = [pscustomobject]@{
        workload = $contract.workload
        voice = [bool] $contract.voice
        video = [bool] $contract.video
        screenShare = [bool] $contract.screenShare
        visibleMedia = [bool] $contract.visibleMedia
        sameAccountRouteWindowAndDisplayRequired = $true
        frontendMustBeFullyInitialized = $true
        noProductionFeatureReduction = $true
        functionalValidationRequired = $true
    }
    outputDirectories = @($outputDirectories)
    policy = 'Manual active-workload checkpoint. Raw process data remains local. The scenario contract does not prove functional success; functional results must be recorded separately.'
} 
$reportPath = Join-Path $OutputDirectory 'active-workload-checkpoint.json'
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding utf8

[pscustomobject]@{
    result = 'PASS'
    scenario = $Scenario
    repetitions = $Repetitions
    reportPath = (Resolve-Path -LiteralPath $reportPath).Path
    outputDirectories = @($outputDirectories)
} | ConvertTo-Json -Depth 5
