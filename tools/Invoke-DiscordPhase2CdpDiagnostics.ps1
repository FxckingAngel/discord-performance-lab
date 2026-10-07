[CmdletBinding()]
param(
    [ValidateRange(1, 65535)]
    [int] $Port = 9222,

    [ValidateRange(1, 60)]
    [int] $DurationSeconds = 10,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath
)

$node = Get-Command node.exe -ErrorAction Stop
$script = Join-Path $PSScriptRoot 'Invoke-DiscordPhase2CdpDiagnostics.mjs'
if (-not (Test-Path -LiteralPath $script -PathType Leaf)) {
    throw "CDP diagnostic script was not found: $script"
}
$parent = Split-Path -Parent $OutputPath
if ($parent) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
& $node.Source $script $Port $DurationSeconds $OutputPath
if ($LASTEXITCODE -ne 0) {
    throw "CDP diagnostic process failed with exit code $LASTEXITCODE."
}
[pscustomobject]@{
    port = $Port
    durationSeconds = $DurationSeconds
    outputPath = $OutputPath
}
