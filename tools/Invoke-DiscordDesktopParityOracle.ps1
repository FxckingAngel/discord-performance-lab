[CmdletBinding()]
param(
    [ValidateRange(1024, 65535)] [int] $OfficialPort = 9235,
    [ValidateRange(1024, 65535)] [int] $TrackBPort = 9230,
    [ValidateNotNullOrEmpty()] [int] $OfficialPid,
    [ValidateNotNullOrEmpty()] [int] $TrackBPid,
    [ValidateNotNullOrEmpty()] [string] $OutputPath
)

$ErrorActionPreference = 'Stop'
$source = @'
using System;
using System.Runtime.InteropServices;
public static class DesktopParityNativeProbe {
  [DllImport("user32.dll")] public static extern uint GetDpiForWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern uint GetDpiForSystem();
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT rect);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT point);
  [DllImport("user32.dll")] public static extern bool GetWindowPlacement(IntPtr hWnd, ref WINDOWPLACEMENT placement);
  [DllImport("user32.dll")] public static extern IntPtr GetWindowDpiAwarenessContext(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern int GetAwarenessFromDpiAwarenessContext(IntPtr value);
  [DllImport("user32.dll")] public static extern IntPtr MonitorFromWindow(IntPtr hWnd, uint flags);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern bool GetMonitorInfo(IntPtr hMonitor, ref MONITORINFOEX info);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern bool EnumDisplaySettingsEx(string deviceName, int modeNum, ref DEVMODE mode, uint flags);
  public struct RECT { public int Left, Top, Right, Bottom; }
  public struct POINT { public int X, Y; }
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)] public struct MONITORINFOEX { public int CbSize; public RECT Monitor; public RECT Work; public uint Flags; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName; }
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)] public struct DEVMODE {
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName;
    public short SpecVersion, DriverVersion, Size, DriverExtra;
    public int Fields, PositionX, PositionY, DisplayOrientation, DisplayFixedOutput;
    public short Color, Duplex, YResolution, TTOption, Collate;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string FormName;
    public short LogPixels;
    public int BitsPerPel, PelsWidth, PelsHeight, DisplayFlags, DisplayFrequency;
    public int ICMMethod, ICMIntent, MediaType, DitherType, Reserved1, Reserved2, PanningWidth, PanningHeight;
  }
  public struct WINDOWPLACEMENT { public int Length, Flags, ShowCmd; public POINT MinPosition, MaxPosition; public RECT NormalPosition; }
}
'@
Add-Type $source

function Get-NativeWindow($processId) {
    $process = Get-Process -Id $processId
    if ($process.MainWindowHandle -eq [IntPtr]::Zero) { throw "PID $processId has no main window handle." }
    $window = New-Object DesktopParityNativeProbe+RECT
    $client = New-Object DesktopParityNativeProbe+RECT
    $clientOrigin = New-Object DesktopParityNativeProbe+POINT
    $placement = New-Object DesktopParityNativeProbe+WINDOWPLACEMENT
    $placement.Length = [Runtime.InteropServices.Marshal]::SizeOf([type]'DesktopParityNativeProbe+WINDOWPLACEMENT')
    [DesktopParityNativeProbe]::GetWindowRect($process.MainWindowHandle, [ref]$window) | Out-Null
    [DesktopParityNativeProbe]::GetClientRect($process.MainWindowHandle, [ref]$client) | Out-Null
    [DesktopParityNativeProbe]::ClientToScreen($process.MainWindowHandle, [ref]$clientOrigin) | Out-Null
    [DesktopParityNativeProbe]::GetWindowPlacement($process.MainWindowHandle, [ref]$placement) | Out-Null
    $monitorHandle = [DesktopParityNativeProbe]::MonitorFromWindow($process.MainWindowHandle, 2)
    $monitorInfo = New-Object DesktopParityNativeProbe+MONITORINFOEX
    $monitorInfo.CbSize = [Runtime.InteropServices.Marshal]::SizeOf([type]'DesktopParityNativeProbe+MONITORINFOEX')
    [DesktopParityNativeProbe]::GetMonitorInfo($monitorHandle, [ref]$monitorInfo) | Out-Null
    $displayMode = New-Object DesktopParityNativeProbe+DEVMODE
    $displayMode.Size = [Runtime.InteropServices.Marshal]::SizeOf([type]'DesktopParityNativeProbe+DEVMODE')
    $refreshRate = $null
    if ([DesktopParityNativeProbe]::EnumDisplaySettingsEx($monitorInfo.DeviceName, -1, [ref]$displayMode, 0)) {
        $refreshRate = $displayMode.DisplayFrequency
    }
    $windowWidth = $window.Right - $window.Left
    $windowHeight = $window.Bottom - $window.Top
    $clientWidth = $client.Right - $client.Left
    $clientHeight = $client.Bottom - $client.Top
    [pscustomobject]@{
        pid = $processId
        dpi = [DesktopParityNativeProbe]::GetDpiForWindow($process.MainWindowHandle)
        systemDpi = [DesktopParityNativeProbe]::GetDpiForSystem()
        dpiAwareness = [DesktopParityNativeProbe]::GetAwarenessFromDpiAwarenessContext([DesktopParityNativeProbe]::GetWindowDpiAwarenessContext($process.MainWindowHandle))
        windowsScalePercent = [math]::Round(([DesktopParityNativeProbe]::GetDpiForWindow($process.MainWindowHandle) / 96.0) * 100, 2)
        window = [pscustomobject]@{ left = $window.Left; top = $window.Top; width = $windowWidth; height = $windowHeight }
        client = [pscustomobject]@{ width = $clientWidth; height = $clientHeight }
        clientOrigin = [pscustomobject]@{ x = $clientOrigin.X; y = $clientOrigin.Y }
        nonClient = [pscustomobject]@{ width = $windowWidth - $clientWidth; height = $windowHeight - $clientHeight }
        titlebarClientOffset = [pscustomobject]@{ x = $clientOrigin.X - $window.Left; y = $clientOrigin.Y - $window.Top }
        monitor = [pscustomobject]@{
            left = $monitorInfo.Monitor.Left
            top = $monitorInfo.Monitor.Top
            width = $monitorInfo.Monitor.Right - $monitorInfo.Monitor.Left
            height = $monitorInfo.Monitor.Bottom - $monitorInfo.Monitor.Top
            workWidth = $monitorInfo.Work.Right - $monitorInfo.Work.Left
            workHeight = $monitorInfo.Work.Bottom - $monitorInfo.Work.Top
            refreshRateHz = $refreshRate
        }
        showCommand = $placement.ShowCmd
    }
}

$nativePath = Join-Path ([IO.Path]::GetTempPath()) ('discord-parity-native-' + [guid]::NewGuid().ToString('N') + '.json')
try {
    [pscustomobject]@{ official = Get-NativeWindow $OfficialPid; trackB = Get-NativeWindow $TrackBPid } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $nativePath -Encoding utf8
    & node (Join-Path $PSScriptRoot 'Probe-DiscordDesktopParityOracle.mjs') $OfficialPort $TrackBPort $nativePath $OutputPath
    if ($LASTEXITCODE -ne 0) { throw 'Desktop parity oracle failed.' }
} finally {
    Remove-Item -LiteralPath $nativePath -Force -ErrorAction SilentlyContinue
}
