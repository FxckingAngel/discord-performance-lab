[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ExecutablePath,

    [ValidateRange(1024, 65535)]
    [int] $Port = 9235,

    [ValidateNotNullOrEmpty()]
    [string] $UserDataDirectory = (Join-Path $env:TEMP 'TrackB-DiscordVanillaDiagnostic')
)

$ErrorActionPreference = 'Stop'
$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath).Path
$resolvedProfile = [System.IO.Path]::GetFullPath($UserDataDirectory)
$active = @(Get-CimInstance Win32_Process | Where-Object {
    $_.ExecutablePath -and
    ((Resolve-Path -LiteralPath $_.ExecutablePath -ErrorAction SilentlyContinue).Path -eq $resolvedExecutable)
})

if ($active.Count -eq 0) {
    throw 'The requested executable is not currently installed/running as an active Discord build; verify the path before starting a diagnostic.'
}

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
