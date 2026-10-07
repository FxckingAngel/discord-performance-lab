[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'KoroneDiscordShell',

    [string] $OutputPath = (Join-Path (Get-Location) ('benchmarks/raw/track-b-functional-checkpoint-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.json'))
)

function Get-TrackBCheckpointProcess {
    $processes = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    if ($processes.Count -eq 0) {
        throw "Track B process '$ProcessName' is not running. Start the shell and leave it ready before recording the checklist."
    }
    if ($processes.Count -ne 1) {
        throw "Expected exactly one Track B process named '$ProcessName', found $($processes.Count)."
    }
    if (-not $processes[0].Responding) {
        throw "Track B process PID $($processes[0].Id) is not responding. Do not record functional results while the shell is unresponsive."
    }
    return $processes[0]
}

$checkpointProcess = Get-TrackBCheckpointProcess

$checks = @(
    @{ id = 'login-session'; label = 'Login and session persistence' }
    @{ id = 'servers-channels'; label = 'Servers, channels, DMs, threads, and search' }
    @{ id = 'messaging'; label = 'Send, receive, edit, reactions, and attachments' }
    @{ id = 'images-media'; label = 'Images, GIFs, stickers, embeds, and downloads' }
    @{ id = 'notifications'; label = 'Desktop notifications and notification opening' }
    @{ id = 'voice'; label = 'Voice connect, microphone, output, and push-to-talk' }
    @{ id = 'video'; label = 'Camera and video call' }
    @{ id = 'screen-share'; label = 'Screen and window sharing' }
    @{ id = 'file-dialogs'; label = 'File dialogs and downloads' }
    @{ id = 'clipboard-drag-drop'; label = 'Clipboard, drag/drop, and uploads' }
    @{ id = 'window-shell'; label = 'Titlebar, minimize/maximize/close, tray, and startup behavior' }
    @{ id = 'accessibility'; label = 'Keyboard navigation, scaling, themes, and accessibility' }
)

$results = foreach ($check in $checks) {
    Write-Host "`n$($check.label) [$($check.id)]"
    $status = (Read-Host 'Enter PASS, FAIL, or UNTESTED').ToUpperInvariant()
    if ($status -notin @('PASS', 'FAIL', 'UNTESTED')) {
        throw "Invalid status '$status'. Use PASS, FAIL, or UNTESTED."
    }
    $notes = Read-Host 'Short sanitized note (do not enter account data)'
    [pscustomobject]@{
        id = $check.id
        label = $check.label
        status = $status
        notes = $notes
    }
}

$report = [pscustomobject]@{
    schemaVersion = 1
    capturedAt = (Get-Date).ToUniversalTime().ToString('o')
    processName = $checkpointProcess.ProcessName
    rootPid = $checkpointProcess.Id
    windowTitle = $checkpointProcess.MainWindowTitle
    windowResponding = $checkpointProcess.Responding
    policy = 'Manual functional checkpoint. No account identifiers, message content, tokens, screenshots, or raw profile data belong in this report.'
    results = @($results)
    passed = (@($results | Where-Object status -ne 'PASS').Count -eq 0)
}
$parent = Split-Path -Parent $OutputPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
$report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $OutputPath -Encoding utf8
$report | Select-Object capturedAt,passed,@{Name='outputPath';Expression={$OutputPath}}
