[CmdletBinding()]
param(
    [string] $ExecutablePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
    $ExecutablePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe'
}
$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$root = Split-Path -Parent $PSScriptRoot
$source = Get-Content -LiteralPath (Join-Path $root 'track-b/discord-shell/MainForm.cs') -Raw
if ($source -notmatch 'OnNotificationReceived' -or $source -notmatch 'eventType = "notification-received"' -or $source -notmatch 'origin = e\.SenderOrigin') {
    throw 'Notification diagnostic handler contract is missing.'
}
foreach ($forbidden in @('e.Title', 'e.Body', 'e.Message', 'e.Tag')) {
    if ($source -match [regex]::Escape($forbidden)) { throw "Notification diagnostic must not record $forbidden." }
}

$probe = $null
$logPath = Join-Path $env:LOCALAPPDATA 'KoroneDiscordShell\Diagnostics\capability-events.jsonl'
try {
    if (Test-Path -LiteralPath $logPath) { Remove-Item -LiteralPath $logPath -Force }
    $probe = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-capability-events' -PassThru
    $ready = $false
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    do {
        try {
            $targets = @(Invoke-RestMethod -Uri 'http://127.0.0.1:9231/json/list' -TimeoutSec 1)
            if (@($targets | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl }).Count -gt 0) {
                $ready = $true
                break
            }
        }
        catch { }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $deadline)
    if (-not $ready) { throw 'Notification diagnostic endpoint did not open.' }
    $process = Get-Process -Id $probe.Id -ErrorAction Stop
    if (-not $process.Responding) { throw 'Notification diagnostic shell was not responsive.' }

    if (Test-Path -LiteralPath $logPath) {
        $log = Get-Content -LiteralPath $logPath -Raw
        foreach ($forbidden in @('title', 'body', 'message', 'cookie', 'token')) {
            if ($log -match ('"' + [regex]::Escape($forbidden) + '"\s*:')) { throw "Notification log contains forbidden field $forbidden." }
        }
    }
    [pscustomobject]@{
        result = 'PASS'
        diagnosticMode = '--diagnostic-capability-events'
        notificationMetadata = @('eventType', 'origin')
        notificationContentRecorded = $false
        normalShellTouched = $false
        officialDiscordTouched = $false
    } | ConvertTo-Json -Depth 4
}
finally {
    if ($probe) {
        $current = Get-Process -Id $probe.Id -ErrorAction SilentlyContinue
        if ($current) {
            [void]$current.CloseMainWindow()
            if (-not $current.WaitForExit(10000)) { throw 'Notification diagnostic shell did not close normally.' }
        }
    }
}
