[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $RootPid,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Scenario,

    [ValidateRange(5, 3600)]
    [int] $DurationSeconds = 600,

    [ValidateRange(1, 60)]
    [int] $IntervalSeconds = 5,

    [ValidateRange(1, 10)]
    [int] $Repetitions = 3,

    [ValidateNotNullOrEmpty()]
    [string] $OutputDirectory,

    [ValidateNotNullOrEmpty()]
    [string] $ProcessName = 'DiscordPTB'
)

$attributionTool = Join-Path $PSScriptRoot 'Measure-DiscordPhase2Attribution.ps1'
$counterTool = Join-Path $PSScriptRoot 'Measure-DiscordPhase2WindowsCounters.ps1'
$roleMapTool = Join-Path $PSScriptRoot 'Get-DiscordPhase2RoleMap.ps1'
foreach ($tool in @($attributionTool, $counterTool, $roleMapTool)) {
    if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) {
        throw "Required tool was not found: $tool"
    }
}

function Get-WindowMetadata {
    param([int] $ProcessId)

    $process = Get-Process -Id $ProcessId -ErrorAction Stop
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class DiscordPhase21WindowState {
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
}
'@ -ErrorAction SilentlyContinue
    [pscustomobject]@{
        mainWindowHandle = $process.MainWindowHandle.ToInt64()
        mainWindowTitlePresent = -not [string]::IsNullOrWhiteSpace($process.MainWindowTitle)
        visible = if ($process.MainWindowHandle -ne 0) { [DiscordPhase21WindowState]::IsWindowVisible($process.MainWindowHandle) } else { $false }
        minimized = if ($process.MainWindowHandle -ne 0) { [DiscordPhase21WindowState]::IsIconic($process.MainWindowHandle) } else { $false }
    }
}

function Get-DisplayMetadata {
    $controllers = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Where-Object CurrentRefreshRate)
    [pscustomobject]@{
        adapters = @($controllers | ForEach-Object {
            [pscustomobject]@{
                name = $_.Name
                currentRefreshRateHz = [int] $_.CurrentRefreshRate
                videoModeDescription = $_.VideoModeDescription
            }
        })
    }
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$rootProcess = Get-Process -Id $RootPid -ErrorAction Stop
$manifest = [System.Collections.Generic.List[object]]::new()
for ($repetition = 1; $repetition -le $Repetitions; $repetition++) {
    $repeatDirectory = Join-Path $OutputDirectory ("repeat-{0:D2}" -f $repetition)
    New-Item -ItemType Directory -Path $repeatDirectory -Force | Out-Null
    $window = Get-WindowMetadata -ProcessId $RootPid
    $display = Get-DisplayMetadata
    $roleMapPath = Join-Path $repeatDirectory 'role-map-local.json'
    & $roleMapTool -RootPid $RootPid -ProcessName $ProcessName -OutputPath $roleMapPath | Out-Null
    $attributionPath = Join-Path $repeatDirectory 'attribution.json'
    $counterPath = Join-Path $repeatDirectory 'windows-counters.json'
    & $attributionTool -RootPid $RootPid -DurationSeconds $DurationSeconds -IntervalSeconds $IntervalSeconds -Scenario $Scenario -ProcessName $ProcessName -OutputPath $attributionPath | Out-Null
    & $counterTool -RootPid $RootPid -DurationSeconds $DurationSeconds -IntervalSeconds $IntervalSeconds -Scenario $Scenario -ProcessName $ProcessName -OutputPath $counterPath | Out-Null
    $manifest.Add([pscustomobject]@{
        repetition = $repetition
        scenario = $Scenario
        rootPid = $RootPid
        window = $window
        display = $display
        attributionPath = $attributionPath
        windowsCountersPath = $counterPath
        roleMapPath = $roleMapPath
    })
}
$manifestPath = Join-Path $OutputDirectory 'manifest.json'
[pscustomobject]@{
    schemaVersion = 1
    scenario = $Scenario
    repetitions = $Repetitions
    durationSeconds = $DurationSeconds
    intervalSeconds = $IntervalSeconds
    rootPid = $RootPid
    warning = 'Scenario state is supplied by the operator. Confirm the channel, call, media, and window state before starting each repetition.'
    repetitionsData = @($manifest)
} | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -Encoding utf8
[pscustomobject]@{
    scenario = $Scenario
    repetitions = $Repetitions
    outputDirectory = $OutputDirectory
    manifestPath = $manifestPath
}
