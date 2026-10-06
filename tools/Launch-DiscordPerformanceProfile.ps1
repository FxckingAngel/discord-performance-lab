[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ExecutablePath,

    [ValidateSet('stock', 'ecoqos')]
    [string] $Profile = 'stock',

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'DiscordPTB'
)

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
}

$process = Start-Process -FilePath $resolvedExecutable -ArgumentList $arguments -PassThru
[pscustomobject] @{
    profile = $Profile
    processName = $ProcessName
    pid = $process.Id
    executablePath = $resolvedExecutable
    arguments = @($arguments)
}
