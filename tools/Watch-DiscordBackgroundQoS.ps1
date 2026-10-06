[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $RootPid,

    [ValidateRange(1, 60)]
    [int] $PollIntervalSeconds = 2,

    [switch] $Once,

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'DiscordPTB'
)

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class DiscordWindowStateNative
{
    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr windowHandle);
}
'@

$qosScript = Join-Path $PSScriptRoot 'Set-DiscordProcessQoS.ps1'
if (-not (Test-Path -LiteralPath $qosScript -PathType Leaf)) {
    throw "QoS utility not found: $qosScript"
}

$lastMode = $null
do {
    $process = Get-Process -Id $RootPid -ErrorAction SilentlyContinue
    if (-not $process) {
        [pscustomobject]@{
            rootPid = $RootPid
            status = 'stopped'
        } | ConvertTo-Json
        break
    }

    $windowHandle = [IntPtr] $process.MainWindowHandle
    $minimized = $windowHandle -eq [IntPtr]::Zero -or [DiscordWindowStateNative]::IsIconic($windowHandle)
    $desiredMode = if ($minimized) { 'ecoqos' } else { 'system-managed' }
    if ($desiredMode -ne $lastMode) {
        $qosOutput = & $qosScript -RootPid $RootPid -ProcessName $ProcessName -Mode $desiredMode | Out-String
        [pscustomobject]@{
            rootPid = $RootPid
            windowHandle = $windowHandle.ToInt64()
            minimizedOrHidden = [bool] $minimized
            mode = $desiredMode
            status = 'applied'
            qosResult = $qosOutput.Trim()
        } | ConvertTo-Json -Depth 5
        $lastMode = $desiredMode
    }

    if (-not $Once) {
        Start-Sleep -Seconds $PollIntervalSeconds
    }
} while (-not $Once)
