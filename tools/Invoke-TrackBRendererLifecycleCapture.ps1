[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^https://(?:[^/]+\.)?discord\.com(?:/|$)')]
    [string] $CanonicalRoute,

    [string] $ExecutablePath,
    [ValidateRange(1, 65535)] [int] $Port = 9230,
    [ValidateRange(5, 60)] [int] $CheckpointSeconds = 5,
    [ValidateRange(1, 30)] [int] $IntervalSeconds = 1,
    [ValidateRange(5, 300)] [int] $ReadinessTimeoutSeconds = 120,
    [ValidateNotNullOrEmpty()] [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-b-renderer-lifecycle-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))),
    [switch] $PlanOnly,
    [switch] $Automatic
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$toolRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
    $ExecutablePath = Join-Path (Split-Path -Parent $toolRoot) 'track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe'
}
$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$node = (Get-Command node.exe -ErrorAction Stop).Source
$measure = Join-Path $PSScriptRoot 'Measure-DiscordPhase2Attribution.ps1'
$regions = Join-Path $PSScriptRoot 'Measure-TrackBResidentMemoryTypes.ps1'
$cdpProbe = Join-Path $PSScriptRoot 'Probe-TrackBRendererLifecycleCdp.mjs'
foreach ($path in @($measure, $regions, $cdpProbe)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required lifecycle tool was not found: $path" }
}
if ($Port -ne 9230) { throw 'The authenticated no-bridge diagnostic uses its fixed CDP port 9230.' }

$checkpointPlan = @(
    [pscustomobject]@{ name = 'blank'; description = 'about:blank runtime floor; readiness must be false.'; requiresReady = $false; delaySeconds = 0 },
    [pscustomobject]@{ name = 'navigation'; description = 'early navigation checkpoint after the canonical Discord route is requested.'; requiresReady = $false; delaySeconds = 0 },
    [pscustomobject]@{ name = 'application-shell'; description = 'Discord mount and document are populated, but the canonical gate is not yet confirmed.'; requiresReady = $true; delaySeconds = 0 },
    [pscustomobject]@{ name = 'canonical-route'; description = 'manually confirmed fully initialized canonical route.'; requiresReady = $true; delaySeconds = 0 },
    [pscustomobject]@{ name = 'settled-1m'; description = 'one minute after canonical confirmation.'; requiresReady = $true; delaySeconds = 60 },
    [pscustomobject]@{ name = 'settled-5m'; description = 'five minutes after canonical confirmation.'; requiresReady = $true; delaySeconds = 240 },
    [pscustomobject]@{ name = 'settled-10m'; description = 'ten minutes after canonical confirmation.'; requiresReady = $true; delaySeconds = 300 }
)

if ($PlanOnly) {
    [pscustomobject]@{
        result = 'PLAN'
        outputDirectory = $OutputDirectory
        launchArgument = '--diagnostic-authenticated-no-bridges'
        canonicalRouteStored = $false
        checkpoints = @($checkpointPlan | Select-Object name, description, requiresReady, delaySeconds)
        policy = 'Diagnostic-only. Does not launch a process, navigate, write account content, clear caches, force GC, trim working sets, or touch official Discord.'
    } | ConvertTo-Json -Depth 6
    exit 0
}

if (-not $Automatic) {
    Write-Host 'This capture restarts only the Track B diagnostic shell. It does not stop or modify official Discord.'
    $confirmation = Read-Host 'Type CAPTURE to continue'
    if ($confirmation -cne 'CAPTURE') { throw 'Capture was not confirmed.' }
}
if (@(Get-Process -Name 'KoroneDiscordShell' -ErrorAction SilentlyContinue).Count -gt 0) {
    throw 'A Track B shell is already running. Close it manually before starting this diagnostic.'
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$shell = $null
$records = [System.Collections.Generic.List[object]]::new()

function Wait-Endpoint {
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    do {
        try {
            $targets = @(Invoke-RestMethod -Uri "http://127.0.0.1:$Port/json/list" -TimeoutSec 1)
            if (@($targets | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl }).Count -gt 0) { return $true }
        } catch { }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $deadline)
    return $false
}

function Get-RendererAndGpuPids([string] $ProcessPath) {
    $tree = Get-Content -LiteralPath $ProcessPath -Raw | ConvertFrom-Json
    $last = @($tree.samples)[-1]
    if ($null -eq $last) { throw "Process capture has no samples: $ProcessPath" }
    $rows = @($last.processes | Where-Object {
        $hasStatus = $_.PSObject.Properties.Name -contains 'status'
        (-not $hasStatus -or $_.status -ne 'unavailable') -and $null -ne $_.pid
    })
    if ($rows.Count -eq 0) { throw "Process capture has no usable process rows: $ProcessPath" }
    $rendererRows = @($rows | Where-Object { [string]$_.role -eq 'renderer' })
    $gpuRows = @($rows | Where-Object { [string]$_.role -eq 'gpu-process' })
    [pscustomobject]@{ lastSample = $last; rows = $rows; rendererRows = $rendererRows; gpuRows = $gpuRows }
}

function Capture-Checkpoint([string] $Name, [string] $Action, [string] $NavigationArgument, [bool] $RequireReady) {
    $safe = $Name -replace '[^A-Za-z0-9_-]', '-'
    $dir = Join-Path $OutputDirectory $safe
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $cdpPath = Join-Path $dir 'cdp-checkpoint.json'
    $processPath = Join-Path $dir 'process-tree.json'
    $regionManifestPath = Join-Path $dir 'memory-type-manifest.json'
    $cdpArguments = @($cdpProbe, "$Port", $Action, $cdpPath)
    if (-not [string]::IsNullOrWhiteSpace($NavigationArgument)) { $cdpArguments += $NavigationArgument }
    $measureProcess = Start-Process -FilePath (Get-Command powershell.exe).Source -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $measure,
        '-RootPid', "$($shell.Id)", '-DurationSeconds', "$CheckpointSeconds", '-IntervalSeconds', "$IntervalSeconds",
        '-Scenario', "renderer-lifecycle-$safe", '-OutputPath', $processPath, '-ProcessName', 'KoroneDiscordShell'
    ) -WindowStyle Hidden -PassThru
    try {
        Start-Sleep -Milliseconds 350
        & $node @cdpArguments | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "CDP checkpoint failed for $Name." }
        $measureProcess.WaitForExit(($CheckpointSeconds + 30) * 1000)
        if (-not $measureProcess.HasExited -or $measureProcess.ExitCode -ne 0) { throw "Process-tree capture failed for $Name." }
        $cdp = Get-Content -LiteralPath $cdpPath -Raw | ConvertFrom-Json
        $readiness = $cdp.checkpoint.applicationReadiness
        if ($RequireReady -and -not [bool]$readiness.ready) { throw "Readiness gate failed for $Name." }
        $inventory = Get-RendererAndGpuPids -ProcessPath $processPath
        $memoryRows = [System.Collections.Generic.List[object]]::new()
        foreach ($row in @($inventory.rendererRows + $inventory.gpuRows)) {
            $role = if ([string]$row.role -eq 'gpu-process') { 'gpu' } else { 'renderer' }
            $memoryPath = Join-Path $dir "$role-$([int]$row.pid)-memory-types.json"
            $regionProcess = Start-Process -FilePath (Get-Command powershell.exe).Source -ArgumentList @(
                '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $regions,
                '-ProcessId', "$([int]$row.pid)", '-Role', $role, '-OutputPath', $memoryPath
            ) -WindowStyle Hidden -Wait -PassThru
            if ($regionProcess.ExitCode -ne 0) { throw "Virtual-memory capture failed for PID $($row.pid) at $Name." }
            $memoryRows.Add([pscustomobject]@{ pid = [int]$row.pid; role = $role; path = (Resolve-Path -LiteralPath $memoryPath).Path })
        }
        [pscustomobject]@{
            name = $Name
            cdpPath = (Resolve-Path -LiteralPath $cdpPath).Path
            processPath = (Resolve-Path -LiteralPath $processPath).Path
            applicationReady = [bool]$readiness.ready
            rendererPids = @($inventory.rendererRows | ForEach-Object { [int]$_.pid })
            gpuPids = @($inventory.gpuRows | ForEach-Object { [int]$_.pid })
            memoryTypePaths = @($memoryRows)
            lastProcessSample = $inventory.lastSample.timestamp
        }
    }
    finally {
        if ($measureProcess -and -not $measureProcess.HasExited) { $measureProcess.WaitForExit(5000) }
    }
}

try {
    $shell = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-authenticated-no-bridges' -PassThru
    if (-not (Wait-Endpoint)) { throw "Track B lifecycle CDP endpoint did not become ready on port $Port." }
    $null = $records.Add((Capture-Checkpoint -Name 'blank' -Action 'blank' -NavigationArgument '' -RequireReady $false))
    $null = $records.Add((Capture-Checkpoint -Name 'navigation' -Action 'navigate' -NavigationArgument $CanonicalRoute -RequireReady $false))
    & $node @($cdpProbe, "$Port", 'wait-ready', (Join-Path $OutputDirectory 'shell-ready-cdp.json'), "$ReadinessTimeoutSeconds") | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Discord application shell did not reach the readiness predicate.' }
    $null = $records.Add((Capture-Checkpoint -Name 'application-shell' -Action 'snapshot' -NavigationArgument '' -RequireReady $true))
    if (-not $Automatic) {
        $confirmation = Read-Host 'Confirm the exact canonical route is visible and untouched, then type READY'
        if ($confirmation -cne 'READY') { throw 'Canonical route was not confirmed.' }
    }
    $null = $records.Add((Capture-Checkpoint -Name 'canonical-route' -Action 'snapshot' -NavigationArgument '' -RequireReady $true))
    foreach ($checkpoint in @($checkpointPlan | Where-Object { $_.name -in @('settled-1m', 'settled-5m', 'settled-10m') })) {
        Start-Sleep -Seconds ([int]$checkpoint.delaySeconds)
        $null = $records.Add((Capture-Checkpoint -Name $checkpoint.name -Action 'snapshot' -NavigationArgument '' -RequireReady $true))
    }
    [pscustomobject]@{
        result = 'PASS'
        schemaVersion = 1
        routeStored = $false
        mode = if ($Automatic) { 'automatic-canonical-route-unverified' } else { 'manual-canonical-route-confirmed' }
        policy = 'Diagnostic-only lifecycle capture. Uses aggregate CDP data, complete-tree per-PID samples, and read-only VirtualQueryEx/QueryWorkingSetEx maps. Does not clear caches, force GC, trim working sets, alter production behavior, or touch official Discord.'
        outputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).Path
        checkpoints = @($records)
    } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'lifecycle-manifest.json') -Encoding utf8
}
finally {
    if ($shell) {
        $current = Get-Process -Id $shell.Id -ErrorAction SilentlyContinue
        if ($current) { [void]$current.CloseMainWindow(); $current.WaitForExit(8000) }
        if (Get-Process -Id $shell.Id -ErrorAction SilentlyContinue) { throw "Lifecycle diagnostic process $($shell.Id) did not exit through its normal close action." }
    }
}
