[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ExecutablePath,

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'DiscordPTB'
)

$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath).Path
$rows = @(Get-CimInstance Win32_Process -Filter "Name='$ProcessName.exe'" | Where-Object {
    $_.ExecutablePath -and ((Resolve-Path -LiteralPath $_.ExecutablePath -ErrorAction SilentlyContinue).Path -eq $resolvedExecutable)
})

if ($rows.Count -eq 0) {
    [pscustomobject]@{
        running = $false
        profile = 'not-running'
        processCount = 0
        rootPid = $null
        rootCommandLine = $null
        mainWindowTitle = $null
        mainWindowResponding = $false
    }
    return
}

$root = $rows | Where-Object { $_.CommandLine -notmatch '\s--type=' } | Select-Object -First 1
$rootProcess = if ($root) { Get-Process -Id ([int]$root.ProcessId) -ErrorAction SilentlyContinue } else { $null }
$rootCommandLine = if ($root) { [string]$root.CommandLine } else { '' }
$profile = if ($rootCommandLine -match 'UseEcoQoSForBackgroundProcess') { 'ecoqos' } else { 'stock' }

[pscustomobject]@{
    running = $true
    profile = $profile
    processCount = $rows.Count
    rootPid = if ($root) { [int]$root.ProcessId } else { $null }
    rootCommandLine = $rootCommandLine
    mainWindowTitle = if ($rootProcess) { $rootProcess.MainWindowTitle } else { $null }
    mainWindowResponding = if ($rootProcess) { [bool]$rootProcess.Responding } else { $false }
}
