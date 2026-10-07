[CmdletBinding()]
param(
    [string] $ExecutablePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
    $ExecutablePath = Join-Path $root 'track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe'
}

Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class TrackBWindowBridgeState {
    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr windowHandle);
}
'@

$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$node = (Get-Command node.exe -ErrorAction Stop).Source
$bridgeProbe = Join-Path $PSScriptRoot 'Test-DiscordWindowBridge.mjs'
$probe = $null

function Wait-WindowState {
    param(
        [Parameter(Mandatory = $true)] [int] $ProcessId,
        [Parameter(Mandatory = $true)] [bool] $Minimized,
        [int] $TimeoutMilliseconds = 5000
    )

    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
    do {
        $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
        if ($process -and ([TrackBWindowBridgeState]::IsIconic($process.MainWindowHandle) -eq $Minimized)) {
            return $true
        }
        Start-Sleep -Milliseconds 50
    } while ([DateTime]::UtcNow -lt $deadline)
    return $false
}

try {
    $probe = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-window-bridge' -PassThru
    $targets = @()
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    do {
        try {
            $targets = @(Invoke-RestMethod -Uri 'http://127.0.0.1:9226/json/list' -TimeoutSec 1)
            if (@($targets | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl }).Count -gt 0) { break }
        }
        catch { }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $deadline)
    if (@($targets | Where-Object { $_.type -eq 'page' -and $_.webSocketDebuggerUrl }).Count -eq 0) {
        throw 'Window bridge CDP endpoint did not open.'
    }

    if (-not (Wait-WindowState -ProcessId $probe.Id -Minimized $false)) {
        throw 'Window bridge probe did not start in a non-minimized state.'
    }
    & $node $bridgeProbe 9226 minimize | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Minimize bridge call failed with exit code $LASTEXITCODE." }
    if (-not (Wait-WindowState -ProcessId $probe.Id -Minimized $true)) {
        throw 'Native minimize call did not produce an iconic window.'
    }
    & $node $bridgeProbe 9226 restore | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Restore bridge call failed with exit code $LASTEXITCODE." }
    if (-not (Wait-WindowState -ProcessId $probe.Id -Minimized $false)) {
        throw 'Native restore call did not return the window to a visible state.'
    }

    [pscustomobject]@{
        result = 'PASS'
        capability = 'DiscordNative.window'
        actions = @('minimize', 'restore')
        nativeStateObserved = $true
        officialDiscordTouched = $false
    } | ConvertTo-Json -Depth 4
}
finally {
    if ($probe) {
        $current = Get-Process -Id $probe.Id -ErrorAction SilentlyContinue
        if ($current) {
            [void]$current.CloseMainWindow()
            if (-not $current.WaitForExit(10000)) { throw 'Window bridge probe did not close normally.' }
        }
    }
}
