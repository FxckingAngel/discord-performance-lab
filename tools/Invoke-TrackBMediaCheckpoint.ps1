[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('voice-permission', 'voice-call', 'video-call', 'screen-share')]
    [string] $Workload,

    [int] $DurationSeconds = 600,
    [int] $IntervalSeconds = 5,
    [string] $ExecutablePath = (Join-Path $PSScriptRoot '..\track-b\discord-shell\bin\Release\net8.0-windows\KoroneDiscordShell.exe'),
    [string] $OutputPath
)

$ErrorActionPreference = 'Stop'
$measureScript = Join-Path $PSScriptRoot 'Measure-DiscordProcessTree.ps1'
$mediaQualityProbe = Join-Path $PSScriptRoot 'Probe-DiscordMediaQuality.mjs'
$resolvedExecutable = Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop

if (-not (Test-Path -LiteralPath $measureScript)) {
    throw "Missing measurement script: $measureScript"
}
if (-not (Test-Path -LiteralPath $mediaQualityProbe)) {
    throw "Missing media-quality probe: $mediaQualityProbe"
}

if ($DurationSeconds -lt 30) {
    throw 'DurationSeconds must be at least 30 seconds.'
}

if ($IntervalSeconds -lt 1) {
    throw 'IntervalSeconds must be at least 1 second.'
}

if (-not $OutputPath) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $OutputPath = Join-Path $PSScriptRoot "..\artifacts\track-b-media-$Workload-$stamp.jsonl"
}

$outputDirectory = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

$existing = @(Get-Process -Name 'KoroneDiscordShell' -ErrorAction SilentlyContinue)
foreach ($process in $existing) {
    if (-not $process.HasExited) {
        $process.CloseMainWindow() | Out-Null
        if (-not $process.WaitForExit(5000)) {
            Stop-Process -Id $process.Id -Force
        }
    }
}

$diagnostic = $null
try {
    $diagnostic = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-authenticated-capability-events' -PassThru
    Write-Host "Track B media checkpoint: $Workload"
    Write-Host 'Only Track B was restarted. The official Discord reference was not touched.'
    Write-Host ''
    switch ($Workload) {
        'voice-permission' { Write-Host 'In Track B, open a voice channel and grant microphone permission if requested. Do not start a call yet.' }
        'voice-call' { Write-Host 'In Track B, join a voice call and leave normal audio active. Keep the call stable.' }
        'video-call' { Write-Host 'In Track B, join a video call and leave normal camera/video controls active.' }
        'screen-share' { Write-Host 'In Track B, start screen sharing with the normal picker and leave sharing active.' }
    }
    Write-Host 'When the requested state is fully initialized and stable, type READY and press Enter.'
    $confirmation = Read-Host
    if ($confirmation -cne 'READY') {
        throw 'Checkpoint cancelled. Type READY exactly when the requested state is prepared.'
    }

    & $measureScript -RootPid $diagnostic.Id -Scenario "track-b-$Workload" -DurationSeconds $DurationSeconds -IntervalSeconds $IntervalSeconds -OutputPath $OutputPath
    Write-Host "Saved private checkpoint measurements to $OutputPath"
    $mediaQualityPath = "$OutputPath.media-quality.json"
    & node $mediaQualityProbe 9232 $mediaQualityPath
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $mediaQualityPath -PathType Leaf)) {
        throw 'The sanitized media-quality probe did not produce a report.'
    }
    Write-Host "Saved sanitized media-quality measurements to $mediaQualityPath"
    $manifestPath = "$OutputPath.manifest.json"
    [pscustomobject]@{
        schemaVersion = 1
        capturedAt = (Get-Date).ToUniversalTime().ToString('o')
        workload = $Workload
        rootPid = $diagnostic.Id
        durationSeconds = $DurationSeconds
        intervalSeconds = $IntervalSeconds
        readyConfirmed = $true
        processTreePath = (Resolve-Path -LiteralPath $OutputPath).Path
        mediaQualityPath = (Resolve-Path -LiteralPath $mediaQualityPath).Path
        policy = 'Private Track B active-workload checkpoint. Manual READY confirmation is required. The official Discord reference is not stopped, restarted, modified, or included.'
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding utf8
    Write-Host "Saved checkpoint manifest to $manifestPath"
}
finally {
    if ($diagnostic -and -not $diagnostic.HasExited) {
        $diagnostic.CloseMainWindow() | Out-Null
        if (-not $diagnostic.WaitForExit(5000)) {
            Stop-Process -Id $diagnostic.Id -Force
        }
    }

    Start-Process -FilePath $resolvedExecutable | Out-Null
}
