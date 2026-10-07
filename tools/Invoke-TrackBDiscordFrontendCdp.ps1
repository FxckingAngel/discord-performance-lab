[CmdletBinding()]
param(
    [string] $ExecutablePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe'),
    [ValidateRange(1, 65535)]
    [int] $Port = 9224,
    [ValidateRange(1, 60)]
    [int] $DurationSeconds = 10,
    [ValidateNotNullOrEmpty()]
    [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-b-discord-frontend-cdp-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$node = (Get-Command node.exe -ErrorAction Stop).Source
$cdpScript = Join-Path $PSScriptRoot 'Invoke-DiscordPhase2CdpDiagnostics.mjs'
$measureScript = Join-Path $PSScriptRoot 'Measure-DiscordPhase2Attribution.ps1'
$residentScript = Join-Path $PSScriptRoot 'Measure-TrackBResidentMemoryTypes.ps1'
$processInfoSource = Join-Path $env:LOCALAPPDATA 'KoroneDiscordShell/Diagnostics/webview-process-info.json'
foreach ($path in @($cdpScript, $measureScript, $residentScript)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required frontend diagnostic tool was not found: $path" }
}
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$diagnostic = $null
$measure = $null
$cdpPath = Join-Path $OutputDirectory 'cdp-diagnostics.json'
$processPath = Join-Path $OutputDirectory 'process-tree-attribution.json'
$residentPath = Join-Path $OutputDirectory 'renderer-resident-types.json'
try {
    $diagnostic = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-discord' -PassThru
    $ready = $false
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    do {
        try {
            $targets = @(Invoke-RestMethod -Uri "http://127.0.0.1:$Port/json/list" -TimeoutSec 1)
            if (@($targets | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl }).Count -gt 0) { $ready = $true; break }
        }
        catch { }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $deadline)
    if (-not $ready) { throw "Unauthenticated Discord CDP endpoint did not become ready on port $Port." }
    $measure = Start-Process -FilePath (Get-Command powershell.exe).Source -WindowStyle Hidden -PassThru -ArgumentList @(
        '-NoProfile', '-File', $measureScript,
        '-RootPid', "$($diagnostic.Id)",
        '-DurationSeconds', "$DurationSeconds",
        '-IntervalSeconds', ([math]::Max(1, [math]::Min(60, $DurationSeconds))),
        '-Scenario', 'track-b-unauthenticated-discord-frontend-cdp',
        '-OutputPath', $processPath
    )
    & $node $cdpScript $Port $DurationSeconds $cdpPath
    if ($LASTEXITCODE -ne 0) { throw "CDP frontend diagnostics failed with exit code $LASTEXITCODE." }
    $measure.WaitForExit(($DurationSeconds + 30) * 1000)
    if (-not $measure.HasExited) { throw 'Frontend process capture did not finish.' }
    if ($measure.ExitCode -ne 0) { throw "Frontend process capture failed with exit code $($measure.ExitCode)." }
    $tree = Get-Content -Raw -LiteralPath $processPath | ConvertFrom-Json
    $renderer = @($tree.samples[-1].processes | Where-Object { $_.role -eq 'renderer' } | Select-Object -First 1)[0]
    if (-not $renderer) { throw 'Frontend diagnostic renderer was not present in the process capture.' }
    $processInfoPath = Join-Path $OutputDirectory 'webview-process-info.json'
    $rendererPidCrossCheck = [pscustomobject]@{ available = $false; processTreeRendererPid = [int]$renderer.pid; matchingRendererPid = $null; matches = $false }
    if (Test-Path -LiteralPath $processInfoSource -PathType Leaf) {
        Copy-Item -LiteralPath $processInfoSource -Destination $processInfoPath -Force
        $processInfo = Get-Content -Raw -LiteralPath $processInfoSource | ConvertFrom-Json
        $reportedRenderer = @($processInfo.processes | Where-Object { $_.kind -eq 'Renderer' } | Select-Object -First 1)[0]
        if ($reportedRenderer) {
            $rendererPidCrossCheck = [pscustomobject]@{
                available = $true
                processTreeRendererPid = [int]$renderer.pid
                matchingRendererPid = [int]$reportedRenderer.processId
                activeFrameCount = $reportedRenderer.activeFrameCount
                matches = ([int]$reportedRenderer.processId -eq [int]$renderer.pid)
            }
        }
    }
    $resident = Start-Process -FilePath (Get-Command powershell.exe).Source -WindowStyle Hidden -Wait -PassThru -ArgumentList @(
        '-NoProfile', '-File', $residentScript,
        '-ProcessId', "$([int]$renderer.pid)",
        '-Role', 'renderer',
        '-OutputPath', $residentPath
    )
    if ($resident.ExitCode -ne 0) { throw "Frontend renderer resident classification failed with exit code $($resident.ExitCode)." }
    [pscustomobject]@{
        result = 'CAPTURED'
        diagnosticArgument = '--diagnostic-discord'
        port = $Port
        durationSeconds = $DurationSeconds
        cdpPath = (Resolve-Path -LiteralPath $cdpPath).Path
        processTreePath = (Resolve-Path -LiteralPath $processPath).Path
        rendererResidentTypesPath = (Resolve-Path -LiteralPath $residentPath).Path
        webViewProcessInfoPath = if (Test-Path -LiteralPath $processInfoPath) { (Resolve-Path -LiteralPath $processInfoPath).Path } else { $null }
        rendererPidCrossCheck = $rendererPidCrossCheck
        policy = 'Unauthenticated aggregate-only diagnostic. No credentials, cookies, tokens, page text, URLs, heap objects, or raw profiles are published.'
    } | ConvertTo-Json -Depth 5
}
finally {
    if ($measure -and -not $measure.HasExited) { $measure.WaitForExit(5000) }
    if ($diagnostic) {
        $current = Get-Process -Id $diagnostic.Id -ErrorAction SilentlyContinue
        if ($current) { [void]$current.CloseMainWindow(); if (-not $current.WaitForExit(8000)) { throw "Diagnostic process $($diagnostic.Id) did not close normally." } }
    }
}
