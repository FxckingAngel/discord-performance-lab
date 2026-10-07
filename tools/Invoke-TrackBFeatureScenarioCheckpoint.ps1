[CmdletBinding()]
param(
    [string] $ExecutablePath,

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'KoroneDiscordShell',

    [ValidateSet('blank-webview2', 'discord-app-shell', 'static-dm', 'static-server-text', 'active-text', 'channel-navigation', 'scrolling', 'media-heavy', 'voice-idle', 'active-voice', 'video', 'screen-sharing', 'notifications', 'gaming-background')]
    [string] $Scenario = 'static-server-text',

    [ValidateRange(5, 86400)]
    [int] $DurationSeconds = 600,

    [ValidateRange(1, 60)]
    [int] $IntervalSeconds = 10,

    [switch] $RequireSettled,

    [ValidateRange(2, 30)]
    [int] $StableSamples = 6,

    [ValidateRange(0.1, 25)]
    [double] $MaxVariationPercent = 1,

    [ValidateNotNullOrEmpty()]
    [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-b-feature-' + $Scenario + '-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

$ErrorActionPreference = 'Stop'
$measureTool = Join-Path $PSScriptRoot 'Measure-DiscordProcessTree.ps1'
$settledTool = Join-Path $PSScriptRoot 'Invoke-TrackBSettledAttribution.ps1'
$residentTool = Join-Path $PSScriptRoot 'Measure-TrackBResidentMemoryTypes.ps1'
$virtualTool = Join-Path $PSScriptRoot 'Measure-TrackBVirtualMemoryTypes.ps1'
foreach ($path in @($measureTool, $residentTool, $virtualTool)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required diagnostic tool was not found: $path" }
}
if ($RequireSettled -and -not (Test-Path -LiteralPath $settledTool -PathType Leaf)) { throw "Required settle tool was not found: $settledTool" }

function Get-RootProcess {
    $matches = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    if ($matches.Count -gt 1) { throw "More than one $ProcessName process is running." }
    return $matches | Select-Object -First 1
}

$root = Get-RootProcess
$startedByScript = $false
if (-not $root) {
    if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
        throw "Track B is not running. Start it manually or pass -ExecutablePath."
    }
    $resolved = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
    $root = Start-Process -FilePath $resolved -PassThru
    $startedByScript = $true
    Start-Sleep -Seconds 3
    $root = Get-RootProcess
    if (-not $root) { throw 'Track B did not remain running after launch.' }
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$treePath = Join-Path $OutputDirectory 'process-tree.json'
$residentDirectory = Join-Path $OutputDirectory 'resident-types'
$residentManifestPath = Join-Path $OutputDirectory 'resident-types.json'
$virtualTypesPath = Join-Path $OutputDirectory 'virtual-types.json'
$settleResultPath = $null

Write-Host "Track B detected: PID $($root.Id)"
Write-Host "Scenario: $Scenario"
Write-Host 'Prepare the requested state manually. Do not send messages or change account settings during capture.'
Write-Host 'Leave the window at the requested route, call state, media state, and display configuration.'
$confirmation = Read-Host 'Type READY to begin measurement'
if ($confirmation -cne 'READY') { throw 'Manual checkpoint was not confirmed. No measurement was started.' }

if ($RequireSettled) {
    $settledDirectory = Join-Path $OutputDirectory 'settled'
    & $settledTool -RootPid $root.Id -ProbeSeconds 5 -StableSamples $StableSamples -MaxVariationPercent $MaxVariationPercent -MeasurementSeconds $DurationSeconds -MeasurementIntervalSeconds $IntervalSeconds -Scenario $Scenario -OutputDirectory $settledDirectory | Out-Null
    if (-not $?) { throw 'Settled process-tree capture failed.' }
    $treePath = Join-Path $settledDirectory 'measurement.json'
    $settleResultPath = Join-Path $settledDirectory 'settle-result.json'
}
else {
    & $measureTool -ProcessName $ProcessName -RootPid $root.Id -DurationSeconds $DurationSeconds -IntervalSeconds $IntervalSeconds -Scenario $Scenario -OutputPath $treePath | Out-Null
    if (-not $?) { throw 'Process-tree capture failed.' }
}

$tree = Get-Content -LiteralPath $treePath -Raw | ConvertFrom-Json
$virtualResult = & $virtualTool -RootPid $root.Id -ProcessName $ProcessName -OutputPath $virtualTypesPath
if (-not $?) { throw 'Virtual-memory classification failed.' }
$final = @($tree.samples[-1].processes)
$rows = [System.Collections.Generic.List[object]]::new()
foreach ($process in $final) {
    $safeRole = ([string] $process.role -replace '[^A-Za-z0-9._-]', '_')
    $outputPath = Join-Path $residentDirectory ("$($process.pid)-$safeRole.json")
    try {
        $measurement = & $residentTool -ProcessId ([int] $process.pid) -Role ([string] $process.role) -OutputPath $outputPath
        $rows.Add([pscustomobject]@{
            pid = [int] $process.pid
            role = [string] $process.role
            outputPath = $outputPath
            captured = $true
            error = $null
        })
    }
    catch {
        $rows.Add([pscustomobject]@{
            pid = [int] $process.pid
            role = [string] $process.role
            outputPath = $outputPath
            captured = $false
            error = $_.Exception.Message
        })
    }
}
[pscustomobject]@{
    schemaVersion = 1
    capturedAt = (Get-Date).ToUniversalTime().ToString('o')
    scenario = $Scenario
    rootPid = [int] $root.Id
    sourceTree = (Resolve-Path -LiteralPath $treePath).Path
    policy = 'Per-PID resident page classification. It preserves renderer identity and does not deduplicate shared physical pages across processes.'
    rows = @($rows)
    virtualTypesPath = (Resolve-Path -LiteralPath $virtualTypesPath).Path
    requireSettled = [bool]$RequireSettled
    settleResultPath = if ($settleResultPath) { (Resolve-Path -LiteralPath $settleResultPath).Path } else { $null }
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $residentManifestPath -Encoding utf8

[pscustomobject]@{
    result = 'PASS'
    scenario = $Scenario
    durationSeconds = $DurationSeconds
    processTreePath = (Resolve-Path -LiteralPath $treePath).Path
    residentManifestPath = (Resolve-Path -LiteralPath $residentManifestPath).Path
    virtualTypesPath = (Resolve-Path -LiteralPath $virtualTypesPath).Path
    residentCaptureCount = @($rows | Where-Object captured).Count
    residentFailureCount = @($rows | Where-Object { -not $_.captured }).Count
    startedByScript = $startedByScript
} | ConvertTo-Json -Depth 4
