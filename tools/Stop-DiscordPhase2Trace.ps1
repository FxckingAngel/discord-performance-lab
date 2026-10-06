[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath,

    [ValidateNotNullOrEmpty()]
    [string] $SessionName = 'KoroneDiscordPhase2',

    [string] $ProblemDescription = 'Korone Discord Phase 2 resource attribution trace'
)

$wpr = Get-Command wpr.exe -ErrorAction SilentlyContinue
if (-not $wpr) {
    throw 'wpr.exe was not found. Install the Windows Performance Toolkit before stopping ETW traces.'
}

$parent = Split-Path -Parent $OutputPath
if ($parent) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
$output = & $wpr.Source '-stop' $OutputPath $ProblemDescription '-skipPdbGen' '-compress' '-instancename' $SessionName 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    throw "WPR failed to stop the Phase 2 trace. $($output.Trim())"
}
[pscustomobject]@{
    status = 'stopped'
    sessionName = $SessionName
    outputPath = $OutputPath
}
