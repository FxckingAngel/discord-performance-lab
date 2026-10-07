[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string] $ExecutablePath
)

$ErrorActionPreference = 'Stop'
$toolRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
    $ExecutablePath = Join-Path (Split-Path -Parent $toolRoot) 'track-b/discord-shell/bin/Release/net8.0-windows/KoroneDiscordShell.exe'
}
$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$process = Start-Process -FilePath $resolvedExecutable -PassThru
Start-Sleep -Milliseconds 750
if ($process.HasExited) {
    throw "Track B normal shell exited before it became ready (exit code $($process.ExitCode))."
}

[pscustomobject]@{
    result = 'STARTED'
    pid = $process.Id
    executablePath = $resolvedExecutable
    policy = 'Starts only the Track B shell. It does not stop, modify, or reuse official Discord.'
} | ConvertTo-Json -Depth 4
