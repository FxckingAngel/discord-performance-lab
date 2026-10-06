using System;
using System.Windows.Forms;

namespace KoroneDiscordShell;

internal static class Program
{
    [STAThread]
    private static void Main(string[] args)
    {
        ApplicationConfiguration.Initialize();
        var diagnosticBlank = args.Length == 1 && string.Equals(args[0], "--diagnostic-blank", StringComparison.Ordinal);
        var diagnosticDiscord = args.Length == 1 && string.Equals(args[0], "--diagnostic-discord", StringComparison.Ordinal);
        var diagnosticUserAgent = args.Length == 1 && string.Equals(args[0], "--diagnostic-official-ua", StringComparison.Ordinal);
        var diagnosticWindowBridge = args.Length == 1 && string.Equals(args[0], "--diagnostic-window-bridge", StringComparison.Ordinal);
        var diagnosticHardwareBridge = args.Length == 1 && string.Equals(args[0], "--diagnostic-hardware-bridge", StringComparison.Ordinal);
        Application.Run(new MainForm(diagnosticBlank, diagnosticDiscord, diagnosticUserAgent, diagnosticWindowBridge, diagnosticHardwareBridge));
    }
}
