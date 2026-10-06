[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $RootPid,

    [ValidateNotNullOrEmpty()]
    [string] $OutputDirectory,

    [ValidateNotNullOrEmpty()]
    [string] $SessionName = 'KoroneDiscordPhase2'
)

$wpr = Get-Command wpr.exe -ErrorAction SilentlyContinue
if (-not $wpr) {
    throw 'wpr.exe was not found. Install the Windows Performance Toolkit before recording ETW traces.'
}

$process = Get-Process -Id $RootPid -ErrorAction Stop
$resolvedOutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $resolvedOutputDirectory -Force | Out-Null
$manifestPath = Join-Path $resolvedOutputDirectory "$SessionName.manifest.json"
$profiles = @('CPU', 'DiskIO', 'GPU', 'Handle', 'ResidentSet', 'Heap')
$arguments = @('-start')
foreach ($profile in $profiles) {
    if ($arguments.Count -gt 1) { $arguments += '-start' }
    $arguments += $profile
}
$arguments += @('-filemode', '-instancename', $SessionName)
$output = & $wpr.Source @arguments 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    if ($output -match '0xc5585011') {
        throw "WPR requires the Windows policy to profile system performance. Run this wrapper from an approved performance-recording session, or use the non-ETW attribution sampler. $($output.Trim())"
    }
    throw "WPR failed to start the Phase 2 trace. $($output.Trim())"
}

[pscustomobject]@{
    schemaVersion = 1
    sessionName = $SessionName
    rootPid = $RootPid
    processName = $process.ProcessName
    processStartTime = $process.StartTime.ToUniversalTime()
    startedAt = [DateTime]::UtcNow
    profiles = $profiles
    manifestPath = $manifestPath
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding utf8
[pscustomobject]@{
    status = 'started'
    sessionName = $SessionName
    rootPid = $RootPid
    manifestPath = $manifestPath
    profiles = $profiles
}
