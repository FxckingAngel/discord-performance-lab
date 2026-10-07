[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string] $ExecutablePath,
    [ValidateRange(1, 65535)] [int] $Port = 9228,
    [ValidateNotNullOrEmpty()] [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-b-native-family-lifecycle-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
    $ExecutablePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'track-b/discord-shell/bin/Release/net8.0-windows/KoroneDiscordShell.exe'
}
$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$node = (Get-Command node.exe -ErrorAction Stop).Source
$measure = Join-Path $PSScriptRoot 'Measure-DiscordPhase2Attribution.ps1'
$cdp = Join-Path $PSScriptRoot 'Invoke-DiscordPhase2CdpDiagnostics.ps1'
$regions = Join-Path $PSScriptRoot 'Measure-TrackBResidentMemoryTypes.ps1'
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$shell = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-authenticated' -PassThru

function Get-Renderer {
    $shellStart = $shell.StartTime.ToUniversalTime()
    $renderer = @(Get-CimInstance Win32_Process | Where-Object {
        if ($_.Name -ne 'msedgewebview2.exe' -or $_.CommandLine -notmatch '--type=renderer(?:\s|$)') {
            return $false
        }
        if ($_.CommandLine -notmatch '--webview-exe-name=KoroneDiscordShell\.exe') {
            return $false
        }
        if (-not $_.CreationDate) { return $true }
        try {
            return [System.Management.ManagementDateTimeConverter]::ToDateTime([string]$_.CreationDate).ToUniversalTime() -ge $shellStart
        }
        catch {
            return $true
        }
    } | Sort-Object CreationDate -Descending | Select-Object -First 1)
    if ($renderer.Count -eq 0) { throw "Track B WebView2 renderer was not found for diagnostic port $Port." }
    return $renderer[0]
}

function Capture-Stage([string] $Label, [int] $WaitSeconds) {
    Start-Sleep -Seconds $WaitSeconds
    $renderer = Get-Renderer
    $safe = $Label -replace '[^A-Za-z0-9_-]', '-'
    $regionPath = Join-Path $OutputDirectory "$safe-renderer-memory-types.json"
    $processPath = Join-Path $OutputDirectory "$safe-process-attribution.json"
    $cdpPath = Join-Path $OutputDirectory "$safe-cdp.json"
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $regions -ProcessId ([int]$renderer.ProcessId) -Role renderer -OutputPath $regionPath | Out-Null
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $measure -ProcessName KoroneDiscordShell -RootPid $shell.Id -DurationSeconds 5 -IntervalSeconds 5 -Scenario "native-family-$safe" -OutputPath $processPath | Out-Null
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $cdp -Port $Port -DurationSeconds 5 -OutputPath $cdpPath | Out-Null
    [pscustomobject]@{ label = $Label; rendererPid = [int]$renderer.ProcessId; regionPath = $regionPath; processPath = $processPath; cdpPath = $cdpPath }
}

try {
    $stages = @(
        Capture-Stage 'startup-5s' 5
        Capture-Stage 'frontend-15s' 10
    )
    & node (Join-Path $PSScriptRoot 'Navigate-TrackBFriends.mjs') $Port 8000 (Join-Path $OutputDirectory 'route.json') | Out-Null
    $stages += Capture-Stage 'friends-40s' 20
    [pscustomobject]@{
        schemaVersion = 1
        capturedAt = (Get-Date).ToUniversalTime().ToString('o')
        policy = 'Read-only lifecycle attribution. Renderer selection is constrained to msedgewebview2.exe with the exact diagnostic port and renderer role. No page content, URLs, tokens, or heap objects are exported.'
        stages = $stages
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'manifest.json') -Encoding utf8
}
finally {
    if ($shell -and (Get-Process -Id $shell.Id -ErrorAction SilentlyContinue)) { Stop-Process -Id $shell.Id -Force }
}
