[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string] $ExecutablePath,

    [ValidateRange(1024, 65535)]
    [int] $Port = 9233
)

$ErrorActionPreference = 'Stop'
$toolRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
    $ExecutablePath = Join-Path (Split-Path -Parent $toolRoot) 'track-b/discord-shell/bin/Release/net8.0-windows/KoroneDiscordShell.exe'
}
$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$process = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-desktop-hints' -PassThru
Start-Sleep -Milliseconds 750
if ($process.HasExited) {
    throw "Track B desktop-hints diagnostic exited before the probe could attach (exit code $($process.ExitCode))."
}

[pscustomobject]@{
    result = 'STARTED'
    pid = $process.Id
    port = $Port
    executablePath = $resolvedExecutable
    policy = 'Diagnostic-only launcher. Uses the isolated DesktopHintsProbeUserData profile and does not open or modify official Discord.'
} | ConvertTo-Json -Depth 4
