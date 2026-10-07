[CmdletBinding()]
param(
    [string] $ExecutablePath,
    [ValidateRange(1, 65535)]
    [int] $Port = 9227
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ExecutablePath)) {
    $ExecutablePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe'
}
$resolvedExecutable = (Resolve-Path -LiteralPath $ExecutablePath -ErrorAction Stop).Path
$node = (Get-Command node.exe -ErrorAction Stop).Source
$probe = $null
try {
    $probe = Start-Process -FilePath $resolvedExecutable -ArgumentList '--diagnostic-hardware-bridge' -PassThru
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
    if (-not $ready) { throw "Hardware bridge endpoint did not open on port $Port." }

    $bridge = (& $node (Join-Path $PSScriptRoot 'Test-DiscordHardwareBridge.mjs') $Port | ConvertFrom-Json)
    if ($LASTEXITCODE -ne 0) { throw 'Hardware bridge CDP call failed.' }
    Add-Type -AssemblyName System.Windows.Forms
    $nativeDisplayCount = [System.Windows.Forms.Screen]::AllScreens.Count
    $bridgeDisplayCount = [int]$bridge.displayCount
    if ($bridgeDisplayCount -ne $nativeDisplayCount -or $bridgeDisplayCount -lt 1 -or $bridge.displayMetricsExposed) {
        throw "Display count mismatch: bridge=$bridgeDisplayCount native=$nativeDisplayCount."
    }
    [pscustomobject]@{
        result = 'PASS'
        capability = 'DiscordNative.hardware.getDisplayCount'
        bridgeDisplayCount = $bridgeDisplayCount
        nativeDisplayCount = $nativeDisplayCount
        exposedMethods = @($bridge.methodNames)
        displayMetricsExposed = [bool]$bridge.displayMetricsExposed
        nativeStateObserved = $true
        officialDiscordTouched = $false
    } | ConvertTo-Json -Depth 4
}
finally {
    if ($probe) {
        $current = Get-Process -Id $probe.Id -ErrorAction SilentlyContinue
        if ($current) {
            [void]$current.CloseMainWindow()
            if (-not $current.WaitForExit(10000)) { throw 'Hardware bridge probe did not close normally.' }
        }
    }
}
