using System;
using System.IO;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Text.Json;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

namespace KoroneDiscordShell;

public sealed class MainForm : Form
{
    private const int WmNclButtonDown = 0x00A1;
    private const int HtCaption = 2;
    private const string DiscordWebApp = "https://discord.com/app";
    private const string DiagnosticOfficialUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) discord/1.0.1223 Chrome/148.0.7778.280 Electron/42.11.10 Safari/537.36";
    private readonly WebView2 webView = new() { Dock = DockStyle.Fill };
    private readonly bool diagnosticBlank;
    private readonly bool diagnosticDiscord;
    private readonly bool diagnosticUserAgent;
    private readonly bool diagnosticWindowBridge;
    private readonly bool diagnosticHardwareBridge;
    private readonly bool diagnosticBridgePair;
    private readonly bool diagnosticAuthenticated;
    private readonly bool diagnosticCapabilityEvents;
    private readonly bool diagnosticAuthenticatedNoBridges;
    private string? capabilityEventLogPath;
    private readonly Panel titleBar = new() { Dock = DockStyle.Top, Height = 32 };
    private readonly Label titleLabel = new() { AutoEllipsis = true, Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleLeft };
    private readonly Button minimizeButton = new() { Dock = DockStyle.Right, FlatStyle = FlatStyle.Flat, Text = "—", Width = 42, TabStop = false, AccessibleName = "Minimize" };
    private readonly Button maximizeButton = new() { Dock = DockStyle.Right, FlatStyle = FlatStyle.Flat, Text = "□", Width = 42, TabStop = false, AccessibleName = "Maximize" };
    private readonly Button closeButton = new() { Dock = DockStyle.Right, FlatStyle = FlatStyle.Flat, Text = "×", Width = 42, TabStop = false, AccessibleName = "Close" };
    private readonly NotifyIcon trayIcon = new() { Icon = SystemIcons.Application, Visible = true, Text = "Discord" };

    public MainForm(bool diagnosticBlank, bool diagnosticDiscord, bool diagnosticUserAgent, bool diagnosticWindowBridge, bool diagnosticHardwareBridge, bool diagnosticBridgePair, bool diagnosticAuthenticated, bool diagnosticCapabilityEvents, bool diagnosticAuthenticatedNoBridges)
    {
        this.diagnosticBlank = diagnosticBlank;
        this.diagnosticDiscord = diagnosticDiscord;
        this.diagnosticUserAgent = diagnosticUserAgent;
        this.diagnosticWindowBridge = diagnosticWindowBridge;
        this.diagnosticHardwareBridge = diagnosticHardwareBridge;
        this.diagnosticBridgePair = diagnosticBridgePair;
        this.diagnosticAuthenticated = diagnosticAuthenticated;
        this.diagnosticCapabilityEvents = diagnosticCapabilityEvents;
        this.diagnosticAuthenticatedNoBridges = diagnosticAuthenticatedNoBridges;
        Text = diagnosticBlank
            ? "Korone's Discord Shell (Runtime Baseline)"
            : diagnosticUserAgent
                ? "Korone's Discord Shell (User-Agent Probe)"
                : diagnosticWindowBridge
                    ? "Korone's Discord Shell (Window Bridge Probe)"
                : diagnosticHardwareBridge
                    ? "Korone's Discord Shell (Hardware Bridge Probe)"
                : diagnosticBridgePair
                    ? "Korone's Discord Shell (Bridge Pair Probe)"
                : diagnosticAuthenticated
                    ? "Korone's Discord Shell (Authenticated Profile Probe)"
                : diagnosticAuthenticatedNoBridges
                    ? "Korone's Discord Shell (Authenticated No-Bridge Probe)"
                : diagnosticCapabilityEvents
                    ? "Korone's Discord Shell (Capability Events Probe)"
                : diagnosticDiscord
                ? "Korone's Discord Shell (Environment Probe)"
                : "Korone's Discord Shell (Prototype)";
        StartPosition = FormStartPosition.CenterScreen;
        Width = 1280;
        Height = 800;
        FormBorderStyle = FormBorderStyle.None;
        MinimizeBox = false;
        MaximizeBox = false;
        titleBar.BackColor = Color.FromArgb(30, 31, 34);
        titleLabel.ForeColor = Color.FromArgb(219, 222, 225);
        titleLabel.Padding = new Padding(12, 0, 0, 0);
        titleLabel.Text = Text;
        foreach (var button in new[] { minimizeButton, maximizeButton, closeButton })
        {
            button.BackColor = titleBar.BackColor;
            button.ForeColor = titleLabel.ForeColor;
            button.FlatAppearance.BorderSize = 0;
            button.FlatAppearance.MouseOverBackColor = Color.FromArgb(64, 66, 71);
        }
        closeButton.FlatAppearance.MouseOverBackColor = Color.FromArgb(237, 66, 69);
        titleBar.Controls.Add(titleLabel);
        titleBar.Controls.Add(minimizeButton);
        titleBar.Controls.Add(maximizeButton);
        titleBar.Controls.Add(closeButton);
        titleBar.MouseDown += BeginWindowDrag;
        titleLabel.MouseDown += BeginWindowDrag;
        minimizeButton.Click += (_, _) => WindowState = FormWindowState.Minimized;
        maximizeButton.Click += (_, _) => ToggleMaximize();
        closeButton.Click += (_, _) => Close();
        Resize += (_, _) => UpdateMaximizeButton();
        var trayMenu = new ContextMenuStrip();
        trayMenu.Items.Add("Show", null, (_, _) => ShowFromTray());
        trayMenu.Items.Add("Exit", null, (_, _) => Close());
        trayIcon.ContextMenuStrip = trayMenu;
        trayIcon.DoubleClick += (_, _) => ShowFromTray();
        FormClosed += (_, _) => trayIcon.Dispose();
        Controls.Add(webView);
        Controls.Add(titleBar);
        Shown += OnShown;
    }

    [DllImport("user32.dll")]
    private static extern bool ReleaseCapture();

    [DllImport("user32.dll")]
    private static extern IntPtr SendMessage(IntPtr handle, int message, IntPtr wParam, IntPtr lParam);

    private void BeginWindowDrag(object? sender, MouseEventArgs e)
    {
        if (e.Button != MouseButtons.Left) return;
        ReleaseCapture();
        SendMessage(Handle, WmNclButtonDown, new IntPtr(HtCaption), IntPtr.Zero);
    }

    private void ToggleMaximize()
    {
        WindowState = WindowState == FormWindowState.Maximized
            ? FormWindowState.Normal
            : FormWindowState.Maximized;
        UpdateMaximizeButton();
    }

    private void UpdateMaximizeButton()
    {
        maximizeButton.Text = WindowState == FormWindowState.Maximized ? "❐" : "□";
        maximizeButton.AccessibleName = WindowState == FormWindowState.Maximized ? "Restore" : "Maximize";
    }

    private void ShowFromTray()
    {
        Show();
        WindowState = WindowState == FormWindowState.Minimized ? FormWindowState.Normal : WindowState;
        Activate();
    }

    private async void OnShown(object? sender, EventArgs e)
    {
        Shown -= OnShown;
        try
        {
            var userDataFolder = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "KoroneDiscordShell",
                diagnosticBlank
                    ? "RuntimeBaselineUserData"
                    : diagnosticUserAgent
                        ? "UserAgentProbeUserData"
                        : diagnosticWindowBridge
                            ? "WindowBridgeProbeUserData"
                        : diagnosticHardwareBridge
                            ? "HardwareBridgeProbeUserData"
                        : diagnosticBridgePair
                            ? "BridgePairProbeUserData"
                        : diagnosticAuthenticated
                            ? "WebView2UserData"
                        : diagnosticAuthenticatedNoBridges
                            ? "WebView2UserData"
                        : diagnosticCapabilityEvents
                            ? "CapabilityEventsProbeUserData"
                        : diagnosticDiscord
                        ? "EnvironmentProbeUserData"
                        : "WebView2UserData");
            Directory.CreateDirectory(userDataFolder);
            var diagnosticPort = diagnosticBlank ? 9223 : diagnosticDiscord ? 9224 : diagnosticUserAgent ? 9225 : diagnosticWindowBridge ? 9226 : diagnosticHardwareBridge ? 9227 : diagnosticBridgePair ? 9229 : diagnosticAuthenticatedNoBridges ? 9230 : diagnosticCapabilityEvents ? 9231 : 9228;
            var options = diagnosticBlank || diagnosticDiscord || diagnosticUserAgent || diagnosticWindowBridge || diagnosticHardwareBridge || diagnosticBridgePair || diagnosticAuthenticated || diagnosticAuthenticatedNoBridges || diagnosticCapabilityEvents
                ? new CoreWebView2EnvironmentOptions { AdditionalBrowserArguments = $"--remote-debugging-port={diagnosticPort}" }
                : null;
            var environment = await CoreWebView2Environment.CreateAsync(
                userDataFolder: userDataFolder,
                options: options);
            await webView.EnsureCoreWebView2Async(environment);
            if (diagnosticCapabilityEvents)
            {
                var diagnosticsDirectory = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    "KoroneDiscordShell",
                    "Diagnostics");
                Directory.CreateDirectory(diagnosticsDirectory);
                capabilityEventLogPath = Path.Combine(diagnosticsDirectory, "capability-events.jsonl");
                webView.CoreWebView2.PermissionRequested += OnPermissionRequested;
                webView.CoreWebView2.NotificationReceived += OnNotificationReceived;
                webView.CoreWebView2.DownloadStarting += OnDownloadStarting;
                webView.CoreWebView2.ScreenCaptureStarting += OnScreenCaptureStarting;
            }
            webView.CoreWebView2.Settings.IsStatusBarEnabled = false;
            webView.CoreWebView2.Settings.AreDefaultContextMenusEnabled = true;
            webView.CoreWebView2.Settings.IsZoomControlEnabled = true;
            var enableWindowBridge = diagnosticWindowBridge || diagnosticBridgePair
                || (!diagnosticBlank && !diagnosticDiscord && !diagnosticUserAgent && !diagnosticHardwareBridge && !diagnosticAuthenticatedNoBridges);
            var enableHardwareBridge = diagnosticHardwareBridge || diagnosticBridgePair
                || (!diagnosticBlank && !diagnosticDiscord && !diagnosticUserAgent && !diagnosticWindowBridge && !diagnosticAuthenticatedNoBridges);
            if (enableWindowBridge || enableHardwareBridge)
            {
                webView.CoreWebView2.WebMessageReceived += OnWebMessageReceived;
            }
            if (diagnosticUserAgent)
            {
                webView.CoreWebView2.Settings.UserAgent = DiagnosticOfficialUserAgent;
            }
            if (enableWindowBridge || enableHardwareBridge)
            {
                var bridgeScript = @"
(() => {
  const native = globalThis.DiscordNative;
  if (native && (typeof native !== 'object' && typeof native !== 'function')) return;
  const target = native ?? {};
  if (native && !Object.isExtensible(target)) return;
  if (!native) Object.defineProperty(globalThis, 'DiscordNative', { configurable: false, enumerable: false, value: target });
@@WINDOW@@
@@HARDWARE@@
})();";
                bridgeScript = bridgeScript.Replace("@@WINDOW@@", enableWindowBridge ? @"
  if (!target.window) {
    const actions = new Set(['minimize', 'maximize', 'restore', 'close', 'focus']);
    const send = (action) => {
      if (actions.has(action)) chrome.webview.postMessage(JSON.stringify({ source: 'track-b-window', action }));
    };
    Object.defineProperty(target, 'window', { configurable: false, enumerable: true, value: Object.freeze(Object.fromEntries([...actions].map((action) => [action, () => send(action)]))) });
  }" : string.Empty);
                bridgeScript = bridgeScript.Replace("@@HARDWARE@@", enableHardwareBridge ? @"
  if (!target.hardware) {
    const pending = new Map();
    let nextId = 1;
    chrome.webview.addEventListener('message', (event) => {
      const message = event.data;
      if (message?.source !== 'track-b-hardware-result' || !pending.has(message.id)) return;
      const request = pending.get(message.id);
      pending.delete(message.id);
      if (message.error) request.reject(new Error(message.error));
      else request.resolve(message.value);
    });
    const getDisplayCount = () => new Promise((resolve, reject) => {
      const id = nextId++;
      pending.set(id, { resolve, reject });
      chrome.webview.postMessage(JSON.stringify({ source: 'track-b-hardware', action: 'getDisplayCount', id }));
    });
    Object.defineProperty(target, 'hardware', { configurable: false, enumerable: true, value: Object.freeze({ getDisplayCount }) });
  }" : string.Empty);
                await webView.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(bridgeScript);
            }
            webView.CoreWebView2.NavigationCompleted += OnNavigationCompleted;
            if (diagnosticHardwareBridge || diagnosticBridgePair)
            {
                webView.NavigateToString("<!doctype html><html><head><title>Hardware Bridge Probe</title></head><body></body></html>");
            }
            else
            {
                webView.Source = new Uri(diagnosticBlank ? "about:blank" : DiscordWebApp);
            }
        }
        catch (Exception error)
        {
            MessageBox.Show(
                this,
                $"The WebView2 shell could not start.\n\n{error.Message}",
                "Korone's Discord Shell",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
        }
    }

    private void OnNavigationCompleted(object? sender, CoreWebView2NavigationCompletedEventArgs e)
    {
        if (!e.IsSuccess)
        {
            Text = $"Korone's Discord Shell (Prototype) - navigation error {e.WebErrorStatus}";
        }
        else
        {
            Text = diagnosticBlank
                    ? "Korone's Discord Shell (Runtime Baseline)"
                    : diagnosticUserAgent
                        ? "Korone's Discord Shell (User-Agent Probe)"
                        : diagnosticWindowBridge
                            ? "Korone's Discord Shell (Window Bridge Probe)"
                        : diagnosticHardwareBridge
                            ? "Korone's Discord Shell (Hardware Bridge Probe)"
                        : diagnosticBridgePair
                            ? "Korone's Discord Shell (Bridge Pair Probe)"
                    : diagnosticAuthenticated
                        ? "Korone's Discord Shell (Authenticated Profile Probe)"
                    : diagnosticAuthenticatedNoBridges
                        ? "Korone's Discord Shell (Authenticated No-Bridge Probe)"
                    : diagnosticCapabilityEvents
                            ? "Korone's Discord Shell (Capability Events Probe)"
                    : diagnosticDiscord
                    ? "Korone's Discord Shell (Environment Probe)"
                    : "Korone's Discord Shell (Prototype)";
            titleLabel.Text = Text;
        }
    }

    private void OnPermissionRequested(object? sender, CoreWebView2PermissionRequestedEventArgs e)
    {
        WriteCapabilityEvent(new
        {
            eventType = "permission-requested",
            origin = e.Uri,
            permissionKind = e.PermissionKind.ToString(),
            isUserInitiated = e.IsUserInitiated,
            state = e.State.ToString(),
        });
    }

    private void OnNotificationReceived(object? sender, CoreWebView2NotificationReceivedEventArgs e)
    {
        WriteCapabilityEvent(new
        {
            eventType = "notification-received",
            origin = e.SenderOrigin,
        });
    }

    private void OnDownloadStarting(object? sender, CoreWebView2DownloadStartingEventArgs e)
    {
        WriteCapabilityEvent(new
        {
            eventType = "download-starting",
            handled = e.Handled,
            cancel = e.Cancel,
        });
    }

    private void OnScreenCaptureStarting(object? sender, CoreWebView2ScreenCaptureStartingEventArgs e)
    {
        WriteCapabilityEvent(new
        {
            eventType = "screen-capture-starting",
            handled = e.Handled,
            cancel = e.Cancel,
        });
    }

    private void WriteCapabilityEvent(object value)
    {
        if (string.IsNullOrEmpty(capabilityEventLogPath)) return;
        try
        {
            File.AppendAllText(
                capabilityEventLogPath,
                JsonSerializer.Serialize(new { timestamp = DateTime.UtcNow, value }) + Environment.NewLine);
        }
        catch
        {
            // Diagnostics must never affect the Discord page or native shell.
        }
    }

    private static bool IsAllowedDiscordOrigin(string source)
    {
        if (!Uri.TryCreate(source, UriKind.Absolute, out var uri)
            || !string.Equals(uri.Scheme, Uri.UriSchemeHttps, StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        return string.Equals(uri.Host, "discord.com", StringComparison.OrdinalIgnoreCase)
            || uri.Host.EndsWith(".discord.com", StringComparison.OrdinalIgnoreCase);
    }

    private void OnWebMessageReceived(object? sender, CoreWebView2WebMessageReceivedEventArgs e)
    {
        if (!diagnosticWindowBridge
            && !diagnosticHardwareBridge
            && !diagnosticBridgePair
            && !IsAllowedDiscordOrigin(e.Source))
        {
            return;
        }

        string message;
        try
        {
            message = e.TryGetWebMessageAsString();
        }
        catch
        {
            return;
        }

        string? action;
        try
        {
            using var document = JsonDocument.Parse(message);
            var root = document.RootElement;
            if (!root.TryGetProperty("source", out var source)
                || !root.TryGetProperty("action", out var actionElement))
            {
                return;
            }

            var sourceName = source.GetString();
            action = actionElement.GetString();
            if (string.Equals(sourceName, "track-b-hardware", StringComparison.Ordinal))
            {
                if (!string.Equals(action, "getDisplayCount", StringComparison.Ordinal)
                    || !root.TryGetProperty("id", out var idElement)
                    || !idElement.TryGetInt32(out var id))
                {
                    return;
                }

                webView.CoreWebView2.PostWebMessageAsJson(JsonSerializer.Serialize(new
                {
                    source = "track-b-hardware-result",
                    id,
                    value = Screen.AllScreens.Length,
                }));
                return;
            }

            if (!string.Equals(sourceName, "track-b-window", StringComparison.Ordinal))
            {
                return;
            }
        }
        catch (JsonException)
        {
            return;
        }

        switch (action)
        {
            case "minimize":
                WindowState = FormWindowState.Minimized;
                break;
            case "maximize":
                WindowState = FormWindowState.Maximized;
                break;
            case "restore":
                WindowState = FormWindowState.Normal;
                break;
            case "close":
                Close();
                break;
            case "focus":
                Activate();
                break;
        }
    }
}
