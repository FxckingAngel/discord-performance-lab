[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ExecutablePath,

    [ValidateSet('stock', 'ecoqos', 'adaptive')]
    [string] $Profile = 'stock',

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'DiscordPTB',

    [switch] $BackgroundIdleConfirmed
)

if ($Profile -eq 'adaptive' -and -not $BackgroundIdleConfirmed) {
    throw 'Adaptive mode requires -BackgroundIdleConfirmed after active voice, video, and media work has ended.'
}

$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath).Path
$existing = @(Get-CimInstance Win32_Process -Filter "Name='$ProcessName.exe'" | Where-Object {
    $_.ExecutablePath -and ((Resolve-Path -LiteralPath $_.ExecutablePath -ErrorAction SilentlyContinue).Path -eq $resolvedExecutable)
})
if ($existing.Count -gt 0) {
    throw "An instance of $ProcessName is already running. Close it manually before launching a profile."
}

$arguments = switch ($Profile) {
    'stock' { @() }
    'ecoqos' { @('--enable-features=UseEcoQoSForBackgroundProcess') }
    'adaptive' { @() }
}

$process = Start-Process -FilePath $resolvedExecutable -ArgumentList $arguments -PassThru
$watcher = $null
if ($Profile -eq 'adaptive') {
    $watcherScript = Join-Path $PSScriptRoot 'Watch-DiscordBackgroundQoS.ps1'
    if (-not (Test-Path -LiteralPath $watcherScript -PathType Leaf)) {
        throw "Adaptive watcher not found: $watcherScript"
    }
    $watcher = Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $watcherScript,
        '-RootPid', $process.Id,
        '-ProcessName', $ProcessName,
        '-PollIntervalSeconds', '2'
    ) -PassThru
}
[pscustomobject] @{
    profile = $Profile
    processName = $ProcessName
    pid = $process.Id
    watcherPid = if ($watcher) { $watcher.Id } else { $null }
    executablePath = $resolvedExecutable
    arguments = @($arguments)
}
