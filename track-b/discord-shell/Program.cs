using System;
using System.Windows.Forms;

namespace KoroneDiscordShell;

internal static class Program
{
    [STAThread]
    private static void Main(string[] args)
    {
        ApplicationConfiguration.Initialize();
        Mutex? normalInstance = null;
        if (args.Length == 0)
        {
            normalInstance = new Mutex(true, "Local\\KoroneDiscordShell.Normal", out var ownsNormalInstance);
            if (!ownsNormalInstance)
            {
                normalInstance.Dispose();
                return;
            }
        }

        var diagnosticBlank = args.Length == 1 && string.Equals(args[0], "--diagnostic-blank", StringComparison.Ordinal);
        var diagnosticDiscord = args.Length == 1 && string.Equals(args[0], "--diagnostic-discord", StringComparison.Ordinal);
        var diagnosticUserAgent = args.Length == 1 && string.Equals(args[0], "--diagnostic-official-ua", StringComparison.Ordinal);
        var diagnosticWindowBridge = args.Length == 1 && string.Equals(args[0], "--diagnostic-window-bridge", StringComparison.Ordinal);
        var diagnosticHardwareBridge = args.Length == 1 && string.Equals(args[0], "--diagnostic-hardware-bridge", StringComparison.Ordinal);
        var diagnosticBridgePair = args.Length == 1 && string.Equals(args[0], "--diagnostic-bridge-pair", StringComparison.Ordinal);
        var diagnosticAuthenticated = args.Length == 1 && string.Equals(args[0], "--diagnostic-authenticated", StringComparison.Ordinal);
        var diagnosticCapabilityEvents = args.Length == 1 && string.Equals(args[0], "--diagnostic-capability-events", StringComparison.Ordinal);
        try
        {
            Application.Run(new MainForm(diagnosticBlank, diagnosticDiscord, diagnosticUserAgent, diagnosticWindowBridge, diagnosticHardwareBridge, diagnosticBridgePair, diagnosticAuthenticated, diagnosticCapabilityEvents));
        }
        finally
        {
            normalInstance?.Dispose();
        }
    }
}
