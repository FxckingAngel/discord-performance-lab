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
    [ValidateRange(15, 120)] [int] $DurationSeconds = 45,
    [ValidateRange(1, 30)] [int] $IntervalSeconds = 5,
    [ValidateNotNullOrEmpty()] [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-b-route-transition-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))),
    [string] $ExecutablePath,
    [ValidateRange(1, 65535)] [int] $Port = 9230,
    [switch] $ClearBrowserCacheAfterMedia,
    [switch] $CaptureCdpTrace
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $AllowNormalShellRestart) { throw 'This diagnostic restarts Track B. Pass -AllowNormalShellRestart explicitly.' }
if ($Port -ne 9230) { throw 'The authenticated no-bridge diagnostic uses CDP port 9230.' }

if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
    $ExecutablePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe'
}

foreach ($candidate in @($StaticUrl, $MediaUrl)) {
    $uri = [Uri]$candidate
    if ($uri.Scheme -ne 'https' -or ($uri.Host -ne 'discord.com' -and -not $uri.Host.EndsWith('.discord.com', [StringComparison]::OrdinalIgnoreCase))) {
        throw 'Route inputs must be HTTPS Discord URLs.'
    }
}

$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$node = (Get-Command node.exe -ErrorAction Stop).Source
$measure = Join-Path $PSScriptRoot 'Measure-DiscordPhase2Attribution.ps1'
$summary = Join-Path $PSScriptRoot 'Summarize-DiscordPhase2Attribution.ps1'
$region = Join-Path $PSScriptRoot 'Measure-TrackBResidentMemoryTypes.ps1'
$probe = Join-Path $PSScriptRoot 'Probe-TrackBRouteTransition.mjs'
$trace = Join-Path $PSScriptRoot 'Capture-TrackBCdpTrace.mjs'
foreach ($path in @($measure, $summary, $region, $probe)) { if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required tool was not found: $path" } }
if ($CaptureCdpTrace -and -not (Test-Path -LiteralPath $trace -PathType Leaf)) { throw "CDP trace tool was not found: $trace" }

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$diagnostic = $null
$probeProcess = $null
try {
    foreach ($process in @(Get-Process -Name KoroneDiscordShell -ErrorAction SilentlyContinue)) {
        [void]$process.CloseMainWindow()
        if (-not $process.WaitForExit(10000)) { throw "Track B process $($process.Id) did not close normally." }
    }
    $diagnostic = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-authenticated-no-bridges' -PassThru
    $endpointDeadline = [DateTime]::UtcNow.AddSeconds(30)
    do {
        try {
            $targets = @(Invoke-RestMethod -Uri "http://127.0.0.1:$Port/json/list" -TimeoutSec 1)
            if (@($targets | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl }).Count -gt 0) { break }
        } catch { }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $endpointDeadline)
    if (@($targets | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl }).Count -eq 0) { throw 'Track B CDP endpoint did not become ready.' }

    $probeLog = Join-Path $OutputDirectory 'route-transition-probe.log'
    $probeArguments = @($probe, "$Port", $StaticUrl, $MediaUrl, "$SettleSeconds", (Resolve-Path -LiteralPath $OutputDirectory).Path)
    if ($ClearBrowserCacheAfterMedia) { $probeArguments += '--clear-cache-after-media' }
    $probeProcess = Start-Process -FilePath $node -ArgumentList $probeArguments -RedirectStandardOutput $probeLog -RedirectStandardError ($probeLog + '.error') -PassThru -WindowStyle Hidden

    foreach ($label in @('static-before', 'media-visible', 'static-after')) {
        $marker = Join-Path $OutputDirectory "checkpoint-$label.ready"
        $deadline = [DateTime]::UtcNow.AddSeconds($SettleSeconds + 180)
        while (-not (Test-Path -LiteralPath $marker) -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 250 }
        if (-not (Test-Path -LiteralPath $marker)) { throw "Readiness marker was not produced for $label." }

        $safeLabel = $label
        $rawPath = Join-Path $OutputDirectory "$safeLabel-process-tree.json"
        $summaryPath = Join-Path $OutputDirectory "$safeLabel-process-tree-summary.json"
        $traceProcess = $null
        if ($CaptureCdpTrace) {
            $tracePath = Join-Path $OutputDirectory "$safeLabel-cdp-trace.json"
            $traceLog = Join-Path $OutputDirectory "$safeLabel-cdp-trace.log"
            $traceProcess = Start-Process -FilePath $node -ArgumentList @($trace, "$Port", "$DurationSeconds", $tracePath) -RedirectStandardOutput $traceLog -RedirectStandardError ($traceLog + '.error') -PassThru -WindowStyle Hidden
            Start-Sleep -Milliseconds 500
        }
        & (Get-Command pwsh.exe).Source -NoProfile -File $measure -RootPid $diagnostic.Id -DurationSeconds $DurationSeconds -IntervalSeconds $IntervalSeconds -Scenario "route-transition-$safeLabel" -OutputPath $rawPath -ProcessName KoroneDiscordShell
        if ($traceProcess) {
            $traceProcess.WaitForExit(($DurationSeconds + 20) * 1000)
            if (-not $traceProcess.HasExited -or $traceProcess.ExitCode -ne 0) { throw "CDP trace failed for $label." }
        }
        & (Get-Command pwsh.exe).Source -NoProfile -File $summary -InputPath $rawPath -OutputPath $summaryPath | Out-Null
        $tree = Get-Content -LiteralPath $rawPath -Raw | ConvertFrom-Json
        $last = @($tree.samples)[-1]
        $renderer = @($last.processes | Where-Object { $_.role -eq 'renderer' -and $_.pid }) | Select-Object -First 1
        if (-not $renderer) { throw "Renderer was not found for $label." }
        & (Get-Command pwsh.exe).Source -NoProfile -File $region -ProcessId ([int]$renderer.pid) -Role renderer -OutputPath (Join-Path $OutputDirectory "$safeLabel-renderer-memory.json") | Out-Null
        $gpu = @($last.processes | Where-Object { $_.role -eq 'gpu-process' -and $_.pid }) | Select-Object -First 1
        if (-not $gpu) { throw "GPU process was not found for $label." }
        & (Get-Command pwsh.exe).Source -NoProfile -File $region -ProcessId ([int]$gpu.pid) -Role 'gpu-process' -OutputPath (Join-Path $OutputDirectory "$safeLabel-gpu-memory.json") | Out-Null
        Set-Content -LiteralPath (Join-Path $OutputDirectory "checkpoint-$label.continue") -Value 'continue' -Encoding utf8
    }
    $probeProcess.WaitForExit(30000)
    if (-not $probeProcess.HasExited -or $probeProcess.ExitCode -ne 0) { throw 'Route transition probe did not complete successfully.' }
    [pscustomobject]@{ result = 'CAPTURED'; stateCount = 3; outputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).Path; policy = 'Same-renderer diagnostic only. URLs are inputs and are not written to artifacts; no account data, IDs, tokens, cookies, page text, or media pixels are collected.' } | ConvertTo-Json -Depth 4
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
