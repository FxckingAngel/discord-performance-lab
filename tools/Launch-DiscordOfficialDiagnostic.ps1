[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ExecutablePath,

    [ValidateRange(1024, 65535)]
    [int] $Port = 9230,

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'DiscordPTB'
)

$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath).Path
$existing = @(Get-CimInstance Win32_Process -Filter "Name='$ProcessName.exe'" | Where-Object {
    $_.ExecutablePath -and ((Resolve-Path -LiteralPath $_.ExecutablePath -ErrorAction SilentlyContinue).Path -eq $resolvedExecutable)
})
if ($existing.Count -gt 0) {
    throw "A matching $ProcessName process is already running. Close it manually before starting a diagnostic session."
}

$process = Start-Process -FilePath $resolvedExecutable -ArgumentList @("--remote-debugging-port=$Port") -PassThru
[pscustomobject]@{
    processName = $ProcessName
    pid = $process.Id
    port = $Port
    executablePath = $resolvedExecutable
    policy = 'Diagnostic launcher only. Uses the existing profile, performs no login automation, and exposes CDP on loopback only.'
}
