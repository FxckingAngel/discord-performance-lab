[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $ProcessId,

    [ValidateRange(5, 60)]
    [int] $SettleSeconds = 10,

    [ValidateNotNullOrEmpty()]
    [string] $OutputDirectory = (Join-Path (Get-Location) ('artifacts/track-b-wpr-heap-snapshot-' + (Get-Date -Format 'yyyyMMdd-HHmmss')))
)

$ErrorActionPreference = 'Stop'
$isAdministrator = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdministrator) { throw 'This diagnostic requires an elevated PowerShell session.' }
$process = Get-Process -Id $ProcessId -ErrorAction Stop
$wpr = (Get-Command wpr.exe -ErrorAction Stop).Source
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$etlPath = Join-Path $OutputDirectory 'track-b-heap-snapshot.etl'
$statusPath = Join-Path $OutputDirectory 'capture-status.json'
$configured = $false
$started = $false
$snapshotCode = $null
$startCode = $null
$stopCode = $null
$errorText = $null

try {
    & $wpr -snapshotconfig heap -pid $ProcessId enable
    if ($LASTEXITCODE -ne 0) { throw "WPR heap snapshot enable failed with exit code $LASTEXITCODE." }
    $configured = $true
    & $wpr -start HeapSnapshot -filemode
    $startCode = $LASTEXITCODE
    if ($startCode -ne 0) { throw "WPR HeapSnapshot start failed with exit code $startCode." }
    $started = $true
    Start-Sleep -Seconds $SettleSeconds
    & $wpr -singlesnapshot heap $ProcessId
    $snapshotCode = $LASTEXITCODE
    if ($snapshotCode -ne 0) { throw "WPR heap snapshot failed with exit code $snapshotCode." }
}
catch {
    $errorText = $_.Exception.Message
}
finally {
    if ($started) {
        & $wpr -stop $etlPath 'Track B renderer heap snapshot' -skipPdbGen
        $stopCode = $LASTEXITCODE
    }
    if ($configured) {
        & $wpr -snapshotconfig heap -pid $ProcessId disable
    }
}

$result = [pscustomobject]@{
    schemaVersion = 1
    capturedAt = (Get-Date).ToUniversalTime().ToString('o')
    elevated = $isAdministrator
    processId = $ProcessId
    processName = $process.ProcessName
    settleSeconds = $SettleSeconds
    profile = 'HeapSnapshot.Verbose.File'
    configured = $configured
    started = $started
    snapshotCode = $snapshotCode
    startCode = $startCode
    stopCode = $stopCode
    etlPath = if (Test-Path -LiteralPath $etlPath) { (Resolve-Path -LiteralPath $etlPath).Path } else { $null }
    error = $errorText
    cleanup = (-not $configured) -or ((& $wpr -snapshotconfig heap -pid $ProcessId 2>&1 | Out-String) -match 'disabled')
}
$result | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $statusPath -Encoding utf8
$result
