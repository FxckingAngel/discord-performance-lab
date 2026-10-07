[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $ProcessId,

    [ValidateRange(5, 120)]
    [int] $DurationSeconds = 20,

    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $ProfilePath,

    [ValidateNotNullOrEmpty()]
    [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-b-wpr-virtualalloc-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$isAdministrator = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdministrator) { throw 'This WPR virtual-allocation capture requires an elevated PowerShell session.' }
$process = Get-Process -Id $ProcessId -ErrorAction Stop
$wpr = (Get-Command wpr.exe -ErrorAction Stop).Source
$profile = if ([string]::IsNullOrWhiteSpace($ProfilePath)) { 'VirtualAllocation' } else { "$(Resolve-Path -LiteralPath $ProfilePath)!VirtualAllocation.Verbose.File" }
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$etlPath = Join-Path $OutputDirectory 'track-b-virtualalloc.etl'
$statusPath = Join-Path $OutputDirectory 'capture-status.json'
$started = $false
$startCode = $null
$stopCode = $null
$errorText = $null
try {
    & $wpr -start $profile -filemode
    $startCode = $LASTEXITCODE
    if ($startCode -ne 0) { throw "WPR VirtualAllocation start failed with exit code $startCode." }
    $started = $true
    Start-Sleep -Seconds $DurationSeconds
}
catch {
    $errorText = $_.Exception.Message
}
finally {
    if ($started) {
        & $wpr -stop $etlPath 'Track B renderer virtual-allocation diagnostic' -skipPdbGen
        $stopCode = $LASTEXITCODE
    }
}
$result = [pscustomobject]@{
    schemaVersion = 1
    capturedAt = (Get-Date).ToUniversalTime().ToString('o')
    elevated = $isAdministrator
    processId = $ProcessId
    processName = $process.ProcessName
    durationSeconds = $DurationSeconds
    profile = $profile
    started = $started
    startCode = $startCode
    stopCode = $stopCode
    etlPath = if (Test-Path -LiteralPath $etlPath) { (Resolve-Path -LiteralPath $etlPath).Path } else { $null }
    error = $errorText
    rawTraceRetainedPrivate = $true
}
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $statusPath -Encoding utf8
$result
