using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace KoroneDiscordShell;

public sealed class PowerMonitorHostObject
{
    [StructLayout(LayoutKind.Sequential)]
    private struct LastInputInfo
    {
        public uint Size;
        public uint Time;
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool GetLastInputInfo(ref LastInputInfo lastInputInfo);

    public long GetSystemIdleTimeMs()
    {
        var info = new LastInputInfo { Size = (uint)Marshal.SizeOf<LastInputInfo>() };
        if (!GetLastInputInfo(ref info))
        {
            throw new Win32Exception(Marshal.GetLastWin32Error(), "GetLastInputInfo failed.");
        }

        var now = Environment.TickCount64;
        var lastInput = (long)info.Time;
        var elapsed = (uint)now >= info.Time
            ? (long)(uint)now - lastInput
            : (long)uint.MaxValue - lastInput + (uint)now + 1L;
        return Math.Max(0L, elapsed);
    }
}
