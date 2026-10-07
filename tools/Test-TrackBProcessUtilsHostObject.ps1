Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'Run this isolated C# harness with pwsh 7 or newer.'
}

$sourcePath = Join-Path $PSScriptRoot '..\track-b\discord-shell\ProcessUtilsHostObject.cs'
Add-Type -Path ([IO.Path]::GetFullPath($sourcePath))

$processUtils = [KoroneDiscordShell.ProcessUtilsHostObject]::new()
$coreCount = $processUtils.GetCPUCoreCount()
$firstUptime = $processUtils.GetProcessUptime()
Start-Sleep -Milliseconds 25
$secondUptime = $processUtils.GetProcessUptime()
$cpuPercent = $processUtils.GetCurrentCPUUsagePercent()

if ($coreCount -lt 1) { throw "CPU core count was invalid: $coreCount." }
if ($secondUptime -le $firstUptime) { throw "Process uptime did not increase: $firstUptime -> $secondUptime." }
if ($cpuPercent -lt 0 -or $cpuPercent -gt 100) { throw "CPU percentage was outside 0..100: $cpuPercent." }

[ordered]@{
    nativeImplementation = $true
    cpuCoreCount = $coreCount
    uptimeIncreased = $true
    cpuPercentRangeValid = $true
    userProcessDataRead = $false
    userAccountDataRead = $false
} | ConvertTo-Json -Compress
