[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ExecutablePath,

    [ValidateSet('stock', 'ecoqos', 'adaptive', 'memory-low')]
    [string] $Profile = 'stock',

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'DiscordPTB',

    [switch] $BackgroundIdleConfirmed
)

if ($Profile -in @('adaptive', 'memory-low') -and -not $BackgroundIdleConfirmed) {
    throw "$Profile mode requires -BackgroundIdleConfirmed after active voice, video, and media work has ended."
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
    'memory-low' { @() }
}

$process = Start-Process -FilePath $resolvedExecutable -ArgumentList $arguments -PassThru
$watcher = $null
if ($Profile -in @('adaptive', 'memory-low')) {
    $watcherScript = if ($Profile -eq 'adaptive') {
        Join-Path $PSScriptRoot 'Watch-DiscordBackgroundQoS.ps1'
    }
    else {
        Join-Path $PSScriptRoot 'Watch-DiscordBackgroundMemoryPriority.ps1'
    }
    if (-not (Test-Path -LiteralPath $watcherScript -PathType Leaf)) {
        throw "$Profile watcher not found: $watcherScript"
    }
    $watcherArguments = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $watcherScript,
        '-RootPid', $process.Id,
        '-ProcessName', $ProcessName,
        '-BackgroundIdleConfirmed',
        '-PollIntervalSeconds', '2'
    )
    if ($Profile -eq 'memory-low') {
        $watcherArguments += @('-Priority', 'low')
    }
    $watcher = Start-Process -FilePath 'powershell.exe' -WindowStyle Hidden -ArgumentList $watcherArguments -PassThru
}
[pscustomobject] @{
    profile = $Profile
    processName = $ProcessName
    pid = $process.Id
    watcherPid = if ($watcher) { $watcher.Id } else { $null }
    executablePath = $resolvedExecutable
    arguments = @($arguments)
}
