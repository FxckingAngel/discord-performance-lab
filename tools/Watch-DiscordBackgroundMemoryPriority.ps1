[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $RootPid,

    [ValidateSet('low', 'very-low')]
    [string] $Priority = 'low',

    [ValidateRange(1, 60)]
    [int] $PollIntervalSeconds = 2,

    [switch] $Once,

    [switch] $BackgroundIdleConfirmed,

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'DiscordPTB'
)

if (-not $BackgroundIdleConfirmed) {
    throw 'Background memory-priority watching requires -BackgroundIdleConfirmed after active voice, video, and media work has ended.'
}

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class DiscordMemoryWindowStateNative
{
    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr windowHandle);
}
'@

$memoryScript = Join-Path $PSScriptRoot 'Set-DiscordProcessMemoryPriority.ps1'
if (-not (Test-Path -LiteralPath $memoryScript -PathType Leaf)) {
    throw "Memory-priority utility not found: $memoryScript"
}

$lastMode = $null
$seenWindow = $false
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
    if ($windowHandle -ne [IntPtr]::Zero) {
        $seenWindow = $true
    }
    $minimized = $seenWindow -and ([DiscordMemoryWindowStateNative]::IsIconic($windowHandle) -or $windowHandle -eq [IntPtr]::Zero)
    $desiredMode = if ($minimized) { $Priority } else { 'normal' }
    if ($desiredMode -ne $lastMode) {
        $excludedRoles = if ($minimized) { @('gpu-process', 'utility/audio.mojom.AudioService') } else { @() }
        $memoryOutput = & $memoryScript -RootPid $RootPid -ProcessName $ProcessName -Priority $desiredMode -ExcludeRole $excludedRoles | Out-String
        if (-not $?) {
            throw "Memory-priority transition to $desiredMode failed for root PID $RootPid. $($memoryOutput.Trim())"
        }
        [pscustomobject]@{
            rootPid = $RootPid
            windowHandle = $windowHandle.ToInt64()
            minimizedOrHidden = [bool] $minimized
            mode = $desiredMode
            status = 'applied'
            memoryPriorityResult = $memoryOutput.Trim()
        } | ConvertTo-Json -Depth 5
        $lastMode = $desiredMode
    }

    if (-not $Once) {
        Start-Sleep -Seconds $PollIntervalSeconds
    }
} while (-not $Once)
