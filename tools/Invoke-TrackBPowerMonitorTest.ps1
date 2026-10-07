[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string] $ExecutablePath,
    [ValidateRange(1, 65535)]
    [int] $Port = 9242
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
    $ExecutablePath = Join-Path $root 'artifacts/track-b-build-verification-20261007/KoroneDiscordShell.exe'
}
$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$node = (Get-Command node.exe -ErrorAction Stop).Source
$probe = $null
try {
    foreach ($process in @(Get-Process -Name KoroneDiscordShell -ErrorAction SilentlyContinue)) {
        [void]$process.CloseMainWindow()
        if (-not $process.WaitForExit(10000)) { throw "Track B process $($process.Id) did not close." }
    }

    $probe = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-power-monitor' -PassThru
    $ready = $false
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    do {
        try {
            $targets = @(Invoke-RestMethod -Uri "http://127.0.0.1:$Port/json/list" -TimeoutSec 1)
            if (@($targets | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl }).Count -gt 0) {
                $ready = $true
                break
            }
        }
        catch { }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $deadline)
    if (-not $ready) { throw "Power-monitor diagnostic endpoint did not open on port $Port." }

    & $node (Join-Path $PSScriptRoot 'Test-TrackBPowerMonitor.mjs') $Port
    if ($LASTEXITCODE -ne 0) { throw "Power-monitor test failed with exit code $LASTEXITCODE." }
    Write-Output 'powerMonitorTest=PASS'
}
finally {
    if ($probe) {
        $current = Get-Process -Id $probe.Id -ErrorAction SilentlyContinue
        if ($current) {
            [void]$current.CloseMainWindow()
            if (-not $current.WaitForExit(10000)) { Stop-Process -Id $probe.Id -Force }
        }
    }
    $verified = Join-Path $root 'track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe'
    $restored = Start-Process -FilePath (Resolve-Path -LiteralPath $verified).Path -PassThru
    Start-Sleep -Seconds 2
    if (-not (Get-Process -Id $restored.Id -ErrorAction SilentlyContinue)) { throw 'Normal Track B shell did not restore.' }
    Write-Output "normalShellRestoredPid=$($restored.Id)"
}
