[CmdletBinding()]
param(
    [string] $ExecutablePath = (Join-Path $env:LOCALAPPDATA 'Discord\app-1.0.9260\Discord.exe'),

    [string] $ProfileDirectory = (Join-Path (Get-Location) 'benchmarks/private/TrackB-DiscordVanillaDiagnostic/Profile'),

    [ValidateRange(1, 65535)]
    [int] $Port = 9242,

    [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-a-pristine-diagnostic-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$packageDirectory = Split-Path -Parent $resolvedExecutable
$moduleDirectory = Join-Path $packageDirectory 'modules'
$desktopCoreCandidates = @(
    Get-ChildItem -LiteralPath $moduleDirectory -Directory -Filter 'discord_desktop_core-*' -ErrorAction SilentlyContinue |
        ForEach-Object {
            $payload = Join-Path $_.FullName 'discord_desktop_core'
            if (Test-Path -LiteralPath (Join-Path $payload 'core.asar') -PathType Leaf) {
                $payload
            }
        }
)
if ($desktopCoreCandidates.Count -eq 0) {
    throw "The selected Discord package is incomplete for a pristine diagnostic: no modules\discord_desktop_core-*\discord_desktop_core\core.asar was found beside '$resolvedExecutable'. Use the complete installed package; do not copy native modules from another Discord installation."
}
$probe = Join-Path $PSScriptRoot 'Invoke-DiscordEnvironmentProbe.mjs'
$node = (Get-Command node.exe -ErrorAction Stop).Source
if (-not (Test-Path -LiteralPath $probe -PathType Leaf)) { throw "Environment probe was not found: $probe" }
New-Item -ItemType Directory -Path $ProfileDirectory, $OutputDirectory -Force | Out-Null
$process = $null

try {
    $existing = @(Get-CimInstance Win32_Process | Where-Object {
        ($_.CommandLine -match [regex]::Escape($resolvedExecutable)) -and ($_.CommandLine -match [regex]::Escape($ProfileDirectory))
    })
    if ($existing.Count -gt 0) { throw 'The isolated pristine diagnostic is already running for this profile.' }

    $process = Start-Process -FilePath $resolvedExecutable -ArgumentList @(
        "--user-data-dir=$ProfileDirectory",
        "--remote-debugging-port=$Port"
    ) -PassThru
    $ready = $false
    $targets = @()
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    do {
        try {
            $targets = @(Invoke-RestMethod -Uri "http://127.0.0.1:$Port/json/list" -TimeoutSec 1)
            if (@($targets | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl }).Count -gt 0) {
                $ready = $true
                break
            }
        }
        catch { }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $deadline)
    if (-not $ready) { throw "Stable isolated CDP endpoint did not open on port $Port." }

    $environmentPath = Join-Path $OutputDirectory 'environment.json'
    & $node $probe $Port $environmentPath
    if ($LASTEXITCODE -ne 0) { throw 'Sanitized environment probe failed.' }

    [pscustomobject]@{
        result = 'LAUNCHED_UNAUTHENTICATED'
        rootPid = [int]$process.Id
        executablePath = $resolvedExecutable
        profileDirectory = (Resolve-Path -LiteralPath $ProfileDirectory).Path
        port = $Port
        environmentReport = (Resolve-Path -LiteralPath $environmentPath).Path
        loginAutomation = $false
        activePtbTouched = $false
        leaveRunning = $true
    } | ConvertTo-Json -Depth 4
}
catch {
    if ($process) {
        $current = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
        if ($current) { [void]$current.CloseMainWindow(); [void]$current.WaitForExit(8000) }
    }
    throw
}
