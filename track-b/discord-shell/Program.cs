using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace KoroneDiscordShell;

internal static class Program
{
    private static readonly IntPtr PerMonitorAwareV2 = new(-4);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool SetProcessDpiAwarenessContext(IntPtr dpiAwarenessContext);

    [DllImport("shcore.dll")]
    private static extern int SetProcessDpiAwareness(int value);

    [DllImport("user32.dll")]
    private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    private static extern bool SetForegroundWindow(IntPtr hWnd);

    [STAThread]
    private static void Main(string[] args)
    {
        // Set the process DPI context before WinForms or WebView2 creates an HWND.
        if (!SetProcessDpiAwarenessContext(PerMonitorAwareV2))
        {
            _ = SetProcessDpiAwareness(2);
        }
        ApplicationConfiguration.Initialize();
        Mutex? normalInstance = null;
        if (args.Length == 0)
        {
            normalInstance = new Mutex(true, "Local\\KoroneDiscordShell.Normal", out var ownsNormalInstance);
            if (!ownsNormalInstance)
            {
                foreach (var process in Process.GetProcessesByName("KoroneDiscordShell"))
                {
                    using (process)
                    {
                        if (process.MainWindowHandle == IntPtr.Zero) continue;
                        ShowWindow(process.MainWindowHandle, 9);
                        SetForegroundWindow(process.MainWindowHandle);
                        break;
                    }
                }
                normalInstance.Dispose();
                return;
            }
        }

        var diagnosticBlank = args.Length == 1 && string.Equals(args[0], "--diagnostic-blank", StringComparison.Ordinal);
        var diagnosticDiscord = args.Length == 1 && string.Equals(args[0], "--diagnostic-discord", StringComparison.Ordinal);
        var diagnosticUserAgent = args.Length == 1 && string.Equals(args[0], "--diagnostic-official-ua", StringComparison.Ordinal);
        var diagnosticDesktopHints = args.Length == 1 && string.Equals(args[0], "--diagnostic-desktop-hints", StringComparison.Ordinal);
        var diagnosticWindowBridge = args.Length == 1 && string.Equals(args[0], "--diagnostic-window-bridge", StringComparison.Ordinal);
        var diagnosticHardwareBridge = args.Length == 1 && string.Equals(args[0], "--diagnostic-hardware-bridge", StringComparison.Ordinal);
        var diagnosticBridgePair = args.Length == 1 && string.Equals(args[0], "--diagnostic-bridge-pair", StringComparison.Ordinal);
        var diagnosticBootContract = args.Length == 1 && string.Equals(args[0], "--diagnostic-boot-contract", StringComparison.Ordinal);
        var diagnosticSafeStorage = args.Length == 1 && string.Equals(args[0], "--diagnostic-safe-storage", StringComparison.Ordinal);
        var diagnosticErlpackBridge = args.Length == 1 && string.Equals(args[0], "--diagnostic-erlpack-bridge", StringComparison.Ordinal);
        var diagnosticBootContractComplete = args.Length == 1 && string.Equals(args[0], "--diagnostic-boot-contract-complete", StringComparison.Ordinal);
        var diagnosticFileDialog = args.Length == 1 && string.Equals(args[0], "--diagnostic-file-dialog", StringComparison.Ordinal);
        var diagnosticClipboard = args.Length == 1 && string.Equals(args[0], "--diagnostic-clipboard", StringComparison.Ordinal);
        var diagnosticPowerMonitor = args.Length == 1 && string.Equals(args[0], "--diagnostic-power-monitor", StringComparison.Ordinal);
        var diagnosticAuthenticated = args.Length == 1 && string.Equals(args[0], "--diagnostic-authenticated", StringComparison.Ordinal);
        var diagnosticAuthenticatedNoBridges = args.Length == 1 && string.Equals(args[0], "--diagnostic-authenticated-no-bridges", StringComparison.Ordinal);
        var diagnosticCapabilityEvents = args.Length == 1 && string.Equals(args[0], "--diagnostic-capability-events", StringComparison.Ordinal);
        var diagnosticAuthenticatedCapabilityEvents = args.Length == 1 && string.Equals(args[0], "--diagnostic-authenticated-capability-events", StringComparison.Ordinal);
        var diagnosticNativeHost = args.Length == 1 && string.Equals(args[0], "--diagnostic-native-host", StringComparison.Ordinal);
        var diagnosticNativeHostAuthenticated = args.Length == 1 && string.Equals(args[0], "--diagnostic-native-host-authenticated", StringComparison.Ordinal);
        if (diagnosticNativeHost || diagnosticNativeHostAuthenticated)
        {
            Application.Run(new NativeHostProbeContext(diagnosticNativeHostAuthenticated));
            return;
        }
        try
        {
            Application.Run(new MainForm(args.Length == 0, diagnosticBlank, diagnosticDiscord, diagnosticUserAgent, diagnosticDesktopHints, diagnosticWindowBridge, diagnosticHardwareBridge, diagnosticBridgePair, diagnosticBootContract, diagnosticSafeStorage, diagnosticErlpackBridge, diagnosticBootContractComplete, diagnosticFileDialog, diagnosticClipboard, diagnosticPowerMonitor, diagnosticAuthenticated, diagnosticCapabilityEvents, diagnosticAuthenticatedCapabilityEvents, diagnosticAuthenticatedNoBridges));
        }
        finally
        {
            normalInstance?.Dispose();
        }
    }
}
