using System;
using System.IO;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Text.Json;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

namespace KoroneDiscordShell;

public sealed class MainForm : Form
{
    private const string DiscordWebApp = "https://discord.com/app";
    private const string DiagnosticOfficialUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) discord/1.0.1223 Chrome/148.0.7778.280 Electron/42.11.10 Safari/537.36";
    private readonly WebView2 webView = new() { Dock = DockStyle.Fill };
    private readonly bool diagnosticBlank;
    private readonly bool diagnosticDiscord;
    private readonly bool diagnosticUserAgent;
    private readonly bool diagnosticWindowBridge;
    private readonly bool diagnosticHardwareBridge;
    private readonly bool diagnosticAuthenticated;

    public MainForm(bool diagnosticBlank, bool diagnosticDiscord, bool diagnosticUserAgent, bool diagnosticWindowBridge, bool diagnosticHardwareBridge, bool diagnosticAuthenticated)
    {
        this.diagnosticBlank = diagnosticBlank;
        this.diagnosticDiscord = diagnosticDiscord;
        this.diagnosticUserAgent = diagnosticUserAgent;
        this.diagnosticWindowBridge = diagnosticWindowBridge;
        this.diagnosticHardwareBridge = diagnosticHardwareBridge;
        this.diagnosticAuthenticated = diagnosticAuthenticated;
        Text = diagnosticBlank
            ? "Korone's Discord Shell (Runtime Baseline)"
            : diagnosticUserAgent
                ? "Korone's Discord Shell (User-Agent Probe)"
                : diagnosticWindowBridge
                    ? "Korone's Discord Shell (Window Bridge Probe)"
                : diagnosticHardwareBridge
                    ? "Korone's Discord Shell (Hardware Bridge Probe)"
                : diagnosticAuthenticated
                    ? "Korone's Discord Shell (Authenticated Profile Probe)"
                : diagnosticDiscord
                ? "Korone's Discord Shell (Environment Probe)"
                : "Korone's Discord Shell (Prototype)";
        StartPosition = FormStartPosition.CenterScreen;
        Width = 1280;
        Height = 800;
        MinimizeBox = true;
        MaximizeBox = true;
        Controls.Add(webView);
        Shown += OnShown;
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
                        : diagnosticAuthenticated
                            ? "WebView2UserData"
                        : diagnosticDiscord
                        ? "EnvironmentProbeUserData"
                        : "WebView2UserData");
            Directory.CreateDirectory(userDataFolder);
            var diagnosticPort = diagnosticBlank ? 9223 : diagnosticDiscord ? 9224 : diagnosticUserAgent ? 9225 : diagnosticWindowBridge ? 9226 : diagnosticHardwareBridge ? 9227 : 9228;
            var options = diagnosticBlank || diagnosticDiscord || diagnosticUserAgent || diagnosticWindowBridge || diagnosticHardwareBridge || diagnosticAuthenticated
                ? new CoreWebView2EnvironmentOptions { AdditionalBrowserArguments = $"--remote-debugging-port={diagnosticPort}" }
                : null;
            var environment = await CoreWebView2Environment.CreateAsync(
                userDataFolder: userDataFolder,
                options: options);
            await webView.EnsureCoreWebView2Async(environment);
            webView.CoreWebView2.Settings.IsStatusBarEnabled = false;
            webView.CoreWebView2.Settings.AreDefaultContextMenusEnabled = true;
            webView.CoreWebView2.Settings.IsZoomControlEnabled = true;
            var enableWindowBridge = diagnosticWindowBridge
                || (!diagnosticBlank && !diagnosticDiscord && !diagnosticUserAgent && !diagnosticHardwareBridge);
            var enableHardwareBridge = diagnosticHardwareBridge
                || (!diagnosticBlank && !diagnosticDiscord && !diagnosticUserAgent && !diagnosticWindowBridge);
            if (enableWindowBridge || enableHardwareBridge)
            {
                webView.CoreWebView2.WebMessageReceived += OnWebMessageReceived;
            }
            if (diagnosticUserAgent)
            {
                webView.CoreWebView2.Settings.UserAgent = DiagnosticOfficialUserAgent;
            }
            if (enableWindowBridge)
            {
                await webView.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(@"
(() => {
  const actions = new Set(['minimize', 'maximize', 'restore', 'close', 'focus']);
  const send = (action) => {
    if (actions.has(action)) chrome.webview.postMessage(JSON.stringify({ source: 'track-b-window', action }));
  };
  const windowApi = Object.freeze(Object.fromEntries([...actions].map((action) => [action, () => send(action)])));
  if (!globalThis.DiscordNative) {
    Object.defineProperty(globalThis, 'DiscordNative', { configurable: false, enumerable: false, value: Object.freeze({ window: windowApi }) });
  }
})();");
            }
            if (enableHardwareBridge)
            {
                await webView.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(@"
(() => {
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
  const hardware = Object.freeze({ getDisplayCount });
  if (!globalThis.DiscordNative) {
    Object.defineProperty(globalThis, 'DiscordNative', { configurable: false, enumerable: false, value: Object.freeze({ hardware }) });
  }
})();");
            }
            webView.CoreWebView2.NavigationCompleted += OnNavigationCompleted;
            if (diagnosticHardwareBridge)
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
                        : diagnosticAuthenticated
                            ? "Korone's Discord Shell (Authenticated Profile Probe)"
                    : diagnosticDiscord
                    ? "Korone's Discord Shell (Environment Probe)"
                    : "Korone's Discord Shell (Prototype)";
        }
    }

    private void OnWebMessageReceived(object? sender, CoreWebView2WebMessageReceivedEventArgs e)
    {
        if (!diagnosticWindowBridge
            && !diagnosticHardwareBridge
            && !e.Source.StartsWith("https://discord.com/", StringComparison.OrdinalIgnoreCase))
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
