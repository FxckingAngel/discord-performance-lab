[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('static-dm', 'static-server-text', 'media-heavy', 'voice-idle', 'active-voice', 'video', 'screen-sharing')]
    [string] $Scenario,

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'KoroneDiscordShell',

    [ValidateRange(0, [int]::MaxValue)]
    [int] $RootPid = 0,

    [ValidateRange(5, 60)]
    [int] $SettleSeconds = 10,

    [switch] $DecodeSymbols,

    [ValidateNotNullOrEmpty()]
    [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-b-wpr-scenario-' + $Scenario + '-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$isAdministrator = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdministrator) { throw 'This scenario capture requires an elevated PowerShell session.' }

$measureTool = Join-Path $PSScriptRoot 'Measure-DiscordProcessTree.ps1'
$heapTool = Join-Path $PSScriptRoot 'Invoke-TrackBWprHeapSnapshot.ps1'
$decodeTool = Join-Path $PSScriptRoot 'Decode-TrackBWprHeapSnapshot.ps1'
foreach ($tool in @($measureTool, $heapTool)) {
    if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) { throw "Required diagnostic tool was not found: $tool" }
}

if ($RootPid -le 0) {
    $roots = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    if ($roots.Count -ne 1) { throw "Expected exactly one $ProcessName process; found $($roots.Count)." }
    $RootPid = [int]$roots[0].Id
}
Get-Process -Id $RootPid -ErrorAction Stop | Out-Null

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$treePath = Join-Path $OutputDirectory 'process-tree-before.json'
$scenarioCapturePath = Join-Path $OutputDirectory 'scenario-capture.json'
$captureDirectory = Join-Path $OutputDirectory 'wpr-heap-snapshot'

Write-Host "Track B root PID: $RootPid"
Write-Host "Scenario: $Scenario"
Write-Host 'Leave Discord in the requested state. Do not navigate, type, or change the call/media state during the capture.'
$confirmation = Read-Host 'Type READY to begin the read-only process-tree and WPR capture'
if ($confirmation -cne 'READY') { throw 'Manual checkpoint was not confirmed. No capture was started.' }

& powershell -NoProfile -ExecutionPolicy Bypass -File $measureTool `
    -ProcessName $ProcessName `
    -RootPid $RootPid `
    -DurationSeconds ([Math]::Max(5, $SettleSeconds)) `
    -IntervalSeconds ([Math]::Max(1, [Math]::Min(5, $SettleSeconds))) `
    -Scenario "$Scenario-pre-wpr" `
    -OutputPath $treePath | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Process-tree pre-capture failed with exit code $LASTEXITCODE." }

$tree = Get-Content -LiteralPath $treePath -Raw | ConvertFrom-Json
$finalProcesses = @($tree.samples[-1].processes)
$renderer = @($finalProcesses | Where-Object { $_.role -eq 'renderer' })
if ($renderer.Count -ne 1) { throw "Expected exactly one renderer in the final process tree; found $($renderer.Count)." }
$rendererPid = [int]$renderer[0].pid

& $heapTool -ProcessId $rendererPid -SettleSeconds $SettleSeconds -OutputDirectory $captureDirectory | Out-Null
if ($LASTEXITCODE -ne 0) { throw "WPR heap snapshot failed with exit code $LASTEXITCODE." }

$statusPath = Join-Path $captureDirectory 'capture-status.json'
$status = if (Test-Path -LiteralPath $statusPath) { Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json } else { $null }
$decodedOutputPath = $null
if ($DecodeSymbols -and $status -and $status.etlPath -and (Test-Path -LiteralPath $decodeTool -PathType Leaf)) {
    $decodedOutputPath = Join-Path $captureDirectory 'sanitized-xperf-native-ownership.json'
    $decodeArguments = @(
        '-EtlPath', [string]$status.etlPath,
        '-ProcessId', [string]$rendererPid,
        '-OutputPath', $decodedOutputPath,
        '-EnableSymbols'
    )
    & powershell -NoProfile -ExecutionPolicy Bypass -File $decodeTool @decodeArguments | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "WPR heap snapshot decode failed with exit code $LASTEXITCODE." }
}
$result = [pscustomobject]@{
    schemaVersion = 1
    capturedAt = (Get-Date).ToUniversalTime().ToString('o')
    scenario = $Scenario
    rootPid = $RootPid
    rendererPid = $rendererPid
    settleSeconds = $SettleSeconds
    processTreePath = (Resolve-Path -LiteralPath $treePath).Path
    wprStatusPath = if ($statusPath -and (Test-Path -LiteralPath $statusPath)) { (Resolve-Path -LiteralPath $statusPath).Path } else { $null }
    etlPath = if ($status -and $status.etlPath) { [string]$status.etlPath } else { $null }
    decodedOwnershipPath = if ($decodedOutputPath -and (Test-Path -LiteralPath $decodedOutputPath)) { (Resolve-Path -LiteralPath $decodedOutputPath).Path } else { $null }
    symbolsRequested = [bool]$DecodeSymbols
    rawTraceRetainedPrivate = $true
    policy = 'Manual-state, read-only process accounting plus PID-scoped WPR heap snapshot. No navigation, authentication, network, renderer, or shell behavior is changed.'
}
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $scenarioCapturePath -Encoding utf8
$result
