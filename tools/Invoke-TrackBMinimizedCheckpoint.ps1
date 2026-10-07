[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'KoroneDiscordShell',

    [ValidateRange(5, 3600)]
    [int] $DurationSeconds = 60,

    [ValidateRange(1, 60)]
    [int] $IntervalSeconds = 5,

    [ValidateNotNullOrEmpty()]
    [string] $Scenario = 'authenticated-minimized',

    [ValidateNotNullOrEmpty()]
    [string] $OutputPath = (Join-Path (Get-Location) ('artifacts/track-b-minimized-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '/process-tree.json'))
)

$ErrorActionPreference = 'Stop'
$measureTool = Join-Path $PSScriptRoot 'Measure-DiscordProcessTree.ps1'
if (-not (Test-Path -LiteralPath $measureTool -PathType Leaf)) { throw "Process-tree measurement tool was not found: $measureTool" }

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class TrackBMinimizedCheckpointWindow {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr handle, int command);
}
'@

$roots = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
if ($roots.Count -ne 1) { throw "Expected exactly one $ProcessName process; found $($roots.Count)." }
$root = $roots[0]
if ($root.MainWindowHandle -eq [IntPtr]::Zero) { throw 'Track B has no main window handle.' }
$parent = Split-Path -Parent $OutputPath
if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
$minimized = $false
try {
    [TrackBMinimizedCheckpointWindow]::ShowWindow($root.MainWindowHandle, 6) | Out-Null
    $minimized = $true
    Start-Sleep -Seconds 3
    & $measureTool -ProcessName $ProcessName -RootPid $root.Id -DurationSeconds $DurationSeconds -IntervalSeconds $IntervalSeconds -Scenario $Scenario -OutputPath $OutputPath | Out-Null
    if (-not $?) { throw 'Minimized process-tree capture failed.' }
    [pscustomobject]@{
        result = 'CAPTURED'
        scenario = $Scenario
        rootPid = $root.Id
        minimized = $true
        outputPath = (Resolve-Path -LiteralPath $OutputPath).Path
    } | ConvertTo-Json -Depth 4
}
finally {
    if ($minimized) {
        [TrackBMinimizedCheckpointWindow]::ShowWindow($root.MainWindowHandle, 9) | Out-Null
        Start-Sleep -Seconds 2
    }
    $restored = Get-Process -Id $root.Id -ErrorAction SilentlyContinue
    if (-not $restored -or -not $restored.Responding) { throw "Track B did not return to a responsive restored state. PID $($root.Id)." }
}
