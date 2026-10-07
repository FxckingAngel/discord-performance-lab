[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string] $ExecutablePath,

    [ValidateRange(1024, 65535)]
    [int] $Port = 9230
)

$ErrorActionPreference = 'Stop'
$toolRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
    $ExecutablePath = Join-Path (Split-Path -Parent $toolRoot) 'track-b/discord-shell/bin/Release/net8.0-windows/KoroneDiscordShell.exe'
}
$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$process = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-authenticated-no-bridges' -PassThru
Start-Sleep -Milliseconds 750
if ($process.HasExited) {
    throw "Track B authenticated no-bridge diagnostic exited before the probe could attach (exit code $($process.ExitCode))."
}

[pscustomobject]@{
    result = 'STARTED'
    pid = $process.Id
    port = $Port
    executablePath = $resolvedExecutable
    policy = 'Diagnostic-only launcher. Reuses only the Track B WebView2 profile and does not open or modify official Discord.'
} | ConvertTo-Json -Depth 4
