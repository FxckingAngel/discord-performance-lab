[CmdletBinding()]
param(
    [string] $ExecutablePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
    $ExecutablePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'track-b/discord-shell/bin/Release/net8.0-windows/KoroneDiscordShell.exe'
}
$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$probe = $null
try {
    foreach ($process in @(Get-Process -Name KoroneDiscordShell -ErrorAction SilentlyContinue)) {
        [void]$process.CloseMainWindow()
        if (-not $process.WaitForExit(10000)) { throw "Normal shell $($process.Id) did not close." }
    }

    $probe = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-window-bridge' -PassThru
    $ready = $false
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    do {
        try {
            $targets = @(Invoke-RestMethod -Uri 'http://127.0.0.1:9226/json/list' -TimeoutSec 1)
            if (@($targets | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl }).Count -gt 0) {
                $ready = $true
                break
            }
        }
        catch { }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $deadline)
    if (-not $ready) { throw 'Window probe endpoint did not open.' }

    & (Get-Command node.exe -ErrorAction Stop).Source (Join-Path $PSScriptRoot 'Test-TrackBWindowBridge.mjs') 9226
    if ($LASTEXITCODE -ne 0) { throw "Window bridge test failed with exit code $LASTEXITCODE." }
    Write-Output 'windowBridgeTest=PASS'
}
finally {
    if ($probe) {
        $current = Get-Process -Id $probe.Id -ErrorAction SilentlyContinue
        if ($current) {
            [void]$current.CloseMainWindow()
            if (-not $current.WaitForExit(10000)) { throw 'Window probe did not close.' }
        }
    }
    $restored = Start-Process -FilePath $resolvedExecutable -PassThru
    Start-Sleep -Seconds 3
    $observed = Get-Process -Id $restored.Id -ErrorAction SilentlyContinue
    if (-not $observed -or -not $observed.Responding) { throw 'Normal shell did not restore responsively.' }
    Write-Output "normalShellRestoredPid=$($restored.Id)"
}
