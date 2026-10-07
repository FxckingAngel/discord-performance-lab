[CmdletBinding()]
param(
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ExecutablePath = (Join-Path $env:LOCALAPPDATA 'Discord\app-1.0.9260\Discord.exe'),

    [ValidateRange(1024, 65535)]
    [int] $Port = 9235,

    [ValidateNotNullOrEmpty()]
    [string] $UserDataDirectory = (Join-Path $env:TEMP 'TrackB-DiscordVanillaDiagnostic')
)

$ErrorActionPreference = 'Stop'
$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath).Path
$resolvedProfile = [System.IO.Path]::GetFullPath($UserDataDirectory)
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
    throw "The selected Discord package is incomplete for a vanilla diagnostic: no modules\discord_desktop_core-*\discord_desktop_core\core.asar was found beside '$resolvedExecutable'. Do not copy native modules from another Discord installation; use a complete official package instead."
}
# Installation validation is sufficient; this launcher does not require an active process.

New-Item -ItemType Directory -Path $resolvedProfile -Force | Out-Null
$arguments = @(
    '--vanilla'
    '--multi-instance'
    '--start-inactive'
    "--user-data-dir=$resolvedProfile"
    "--remote-debugging-port=$Port"
)
$process = Start-Process -FilePath $resolvedExecutable -ArgumentList $arguments -PassThru
Start-Sleep -Milliseconds 750
if ($process.HasExited) {
    throw "The isolated vanilla diagnostic process exited before the probe could attach (exit code $($process.ExitCode)). The active Discord process was not changed."
}

[pscustomobject]@{
    result = 'STARTED'
    pid = $process.Id
    port = $Port
    executablePath = $resolvedExecutable
    userDataDirectory = $resolvedProfile
    policy = 'Read-only diagnostic launcher. Uses --vanilla and a separate profile; it does not stop, modify, or reuse the active Discord profile.'
} | ConvertTo-Json -Depth 4
