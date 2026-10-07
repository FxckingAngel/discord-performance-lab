[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^https://(?:[^/]+\.)?discord\.com(?:/|$)')]
    [string] $StaticUrl,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^https://(?:[^/]+\.)?discord\.com(?:/|$)')]
    [string] $MediaUrl,

    [switch] $AllowNormalShellRestart,
    [ValidateRange(5, 600)] [int] $SettleSeconds = 30,
    [ValidateRange(5, 120)] [int] $DurationSeconds = 20,
    [ValidateRange(1, 30)] [int] $IntervalSeconds = 1,
    [ValidateNotNullOrEmpty()] [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-b-allocation-family-decay-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))),
    [string] $ExecutablePath,
    [ValidateRange(1, 65535)] [int] $Port = 9230,
    [switch] $PlanOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
    $ExecutablePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'track-b/discord-shell/bin/Release/net8.0-windows/KoroneDiscordShell.exe'
}
if ($Port -ne 9230) { throw 'The authenticated no-bridge diagnostic uses its fixed CDP port 9230.' }
if (-not $AllowNormalShellRestart -and -not $PlanOnly) { throw 'This diagnostic restarts Track B. Pass -AllowNormalShellRestart explicitly.' }

foreach ($candidate in @($StaticUrl, $MediaUrl)) {
    $uri = [Uri]$candidate
    if ($uri.Scheme -ne 'https' -or ($uri.Host -ne 'discord.com' -and -not $uri.Host.EndsWith('.discord.com', [StringComparison]::OrdinalIgnoreCase))) {
        throw 'Route inputs must be HTTPS Discord URLs.'
    }
}

$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$node = (Get-Command node.exe -ErrorAction Stop).Source
$measure = Join-Path $PSScriptRoot 'Measure-DiscordPhase2Attribution.ps1'
$regions = Join-Path $PSScriptRoot 'Measure-TrackBResidentMemoryTypes.ps1'
$probe = Join-Path $PSScriptRoot 'Probe-TrackBAllocationFamilyDecay.mjs'
foreach ($path in @($measure, $regions, $probe)) { if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required tool was not found: $path" } }

if ($PlanOnly) {
    [pscustomobject]@{
        result = 'PLAN'
        states = @('static-before', 'media-visible', 'static-after-30s', 'static-after-120s', 'static-after-300s')
        outputDirectory = $OutputDirectory
        policy = 'Read-only Track B diagnostic. Uses one renderer, aggregate CDP counters, complete-tree samples, and VirtualQueryEx/QueryWorkingSetEx maps. Does not clear caches, force GC, trim working sets, disable media/GPU, alter protocol/authentication, or touch official Discord.'
        interpretation = 'Families that expand during media and return near baseline are media/compositor-dependent candidates. Families that remain near baseline across all checkpoints are persistent settled candidates.'
    } | ConvertTo-Json -Depth 6
    exit 0
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$diagnostic = $null
$probeProcess = $null
$checkpoints = @('static-before', 'media-visible', 'static-after-30s', 'static-after-120s', 'static-after-300s')
try {
    foreach ($process in @(Get-Process -Name KoroneDiscordShell -ErrorAction SilentlyContinue)) {
        [void]$process.CloseMainWindow()
        if (-not $process.WaitForExit(10000)) { throw "Track B process $($process.Id) did not close normally." }
    }
    $diagnostic = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-authenticated-no-bridges' -PassThru
    $endpointDeadline = [DateTime]::UtcNow.AddSeconds(30)
    $targets = @()
    do {
        try { $targets = @(Invoke-RestMethod -Uri "http://127.0.0.1:$Port/json/list" -TimeoutSec 1) } catch { $targets = @() }
        if (@($targets | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl }).Count -gt 0) { break }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $endpointDeadline)
    if (@($targets | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl }).Count -eq 0) { throw 'Track B CDP endpoint did not become ready.' }

    $probeLog = Join-Path $OutputDirectory 'allocation-family-decay-probe.log'
    $probeArguments = @($probe, "$Port", $StaticUrl, $MediaUrl, "$SettleSeconds", (Resolve-Path -LiteralPath $OutputDirectory).Path)
    $probeProcess = Start-Process -FilePath $node -ArgumentList $probeArguments -RedirectStandardOutput $probeLog -RedirectStandardError ($probeLog + '.error') -PassThru -WindowStyle Hidden
    $rendererPid = $null
    $records = [System.Collections.Generic.List[object]]::new()
    foreach ($label in $checkpoints) {
        $marker = Join-Path $OutputDirectory "checkpoint-$label.ready"
        $deadlineSeconds = $SettleSeconds + 180
        $markerDeadline = [DateTime]::UtcNow.AddSeconds($deadlineSeconds)
        while (-not (Test-Path -LiteralPath $marker) -and [DateTime]::UtcNow -lt $markerDeadline) { Start-Sleep -Milliseconds 250 }
        if (-not (Test-Path -LiteralPath $marker)) { throw "Readiness marker was not produced for $label." }

        $rawPath = Join-Path $OutputDirectory "$label-process-tree.json"
        & (Get-Command pwsh.exe).Source -NoProfile -File $measure -RootPid $diagnostic.Id -DurationSeconds $DurationSeconds -IntervalSeconds $IntervalSeconds -Scenario "allocation-family-decay-$label" -OutputPath $rawPath -ProcessName KoroneDiscordShell
        $tree = Get-Content -LiteralPath $rawPath -Raw | ConvertFrom-Json
        $last = @($tree.samples)[-1]
        $renderer = @($last.processes | Where-Object { $_.role -eq 'renderer' -and $_.pid }) | Select-Object -First 1
        if (-not $renderer) { throw "Renderer was not found for $label." }
        if ($null -eq $rendererPid) { $rendererPid = [int]$renderer.pid }
        if ([int]$renderer.pid -ne $rendererPid) { throw "Renderer PID changed from $rendererPid to $($renderer.pid) during the experiment." }
        $memoryPath = Join-Path $OutputDirectory "$label-renderer-memory.json"
        & (Get-Command pwsh.exe).Source -NoProfile -File $regions -ProcessId $rendererPid -Role renderer -OutputPath $memoryPath
        $gpu = @($last.processes | Where-Object { $_.role -eq 'gpu-process' -and $_.pid }) | Select-Object -First 1
        $gpuPath = $null
        if ($gpu) {
            $gpuPath = Join-Path $OutputDirectory "$label-gpu-memory.json"
            & (Get-Command pwsh.exe).Source -NoProfile -File $regions -ProcessId ([int]$gpu.pid) -Role 'gpu-process' -OutputPath $gpuPath
        }
        $records.Add([pscustomobject]@{ label = $label; rendererPid = $rendererPid; processTreePath = (Resolve-Path -LiteralPath $rawPath).Path; rendererMemoryPath = (Resolve-Path -LiteralPath $memoryPath).Path; gpuMemoryPath = if ($gpuPath) { (Resolve-Path -LiteralPath $gpuPath).Path } else { $null } })
        Set-Content -LiteralPath (Join-Path $OutputDirectory "checkpoint-$label.continue") -Value 'continue' -Encoding utf8
    }
    $probeProcess.WaitForExit(30000)
    if (-not $probeProcess.HasExited -or $probeProcess.ExitCode -ne 0) { throw 'Allocation-family decay probe did not complete successfully.' }
    [pscustomobject]@{ result = 'CAPTURED'; schemaVersion = 1; rendererPid = $rendererPid; outputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).Path; checkpoints = @($records); policy = 'Read-only same-renderer diagnostic. Raw maps remain local; public summaries must omit addresses and private Discord data.' } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'allocation-family-decay-manifest.json') -Encoding utf8
}
finally {
    if ($probeProcess -and -not $probeProcess.HasExited) { $probeProcess.Kill(); $probeProcess.WaitForExit(5000) }
    if ($diagnostic) {
        $current = Get-Process -Id $diagnostic.Id -ErrorAction SilentlyContinue
        if ($current) { [void]$current.CloseMainWindow(); $current.WaitForExit(10000) }
    }
    $restored = Start-Process -FilePath $resolvedExecutable -PassThru
    $restoreDeadline = [DateTime]::UtcNow.AddSeconds(20)
    do { Start-Sleep -Milliseconds 250; $observed = Get-Process -Id $restored.Id -ErrorAction SilentlyContinue } while ((-not $observed -or -not $observed.Responding) -and [DateTime]::UtcNow -lt $restoreDeadline)
    if (-not $observed -or -not $observed.Responding) { throw "Track B did not become responsive after restore (PID $($restored.Id))." }
}
