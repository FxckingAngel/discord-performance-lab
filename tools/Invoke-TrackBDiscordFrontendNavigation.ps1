[CmdletBinding()]
param(
    [string] $ExecutablePath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe'),
    [ValidateRange(1, 65535)] [int] $Port = 9224,
    [ValidateRange(1, 30)] [int] $SettleSeconds = 5,
    [ValidateNotNullOrEmpty()] [string] $OutputPath = (Join-Path (Get-Location) ('artifacts/track-b-discord-navigation-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json'))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$node = (Get-Command node.exe -ErrorAction Stop).Source
$probe = Join-Path $PSScriptRoot 'Probe-TrackBDiscordFrontendNavigation.mjs'
if (-not (Test-Path -LiteralPath $probe -PathType Leaf)) { throw "Navigation probe was not found: $probe" }
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
$diagnostic = $null
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
    & $node $probe $Port ($SettleSeconds * 1000) $OutputPath
    if ($LASTEXITCODE -ne 0) { throw "Navigation probe failed with exit code $LASTEXITCODE." }
    [pscustomobject]@{ result = 'CAPTURED'; outputPath = (Resolve-Path -LiteralPath $OutputPath).Path; policy = 'The diagnostic profile was isolated; the normal shell was not modified.' } | ConvertTo-Json -Depth 4
}
finally {
    if ($diagnostic) {
        $current = Get-Process -Id $diagnostic.Id -ErrorAction SilentlyContinue
        if ($current) { [void]$current.CloseMainWindow(); if (-not $current.WaitForExit(8000)) { throw "Navigation diagnostic $($diagnostic.Id) did not close normally." } }
    }
}
