using System;
using System.Diagnostics;

namespace KoroneDiscordShell;

public sealed class ProcessUtilsHostObject
{
    private readonly Stopwatch uptime = Stopwatch.StartNew();
    private readonly Process process = Process.GetCurrentProcess();

    public int GetCPUCoreCount() => Environment.ProcessorCount;

    public double GetCurrentCPUUsagePercent()
    {
        process.Refresh();
        var elapsedMilliseconds = Math.Max(uptime.Elapsed.TotalMilliseconds, 1d);
        var cpuMilliseconds = process.TotalProcessorTime.TotalMilliseconds;
        return Math.Clamp(cpuMilliseconds / elapsedMilliseconds / Environment.ProcessorCount * 100d, 0d, 100d);
    }

    public double GetProcessUptime() => uptime.Elapsed.TotalMilliseconds;
}
