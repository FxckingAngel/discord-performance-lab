using System;
using System.IO;
using System.Threading.Tasks;
using System.Windows.Forms;
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

    public MainForm(bool diagnosticBlank, bool diagnosticDiscord, bool diagnosticUserAgent)
    {
        this.diagnosticBlank = diagnosticBlank;
        this.diagnosticDiscord = diagnosticDiscord;
        this.diagnosticUserAgent = diagnosticUserAgent;
        Text = diagnosticBlank
            ? "Korone's Discord Shell (Runtime Baseline)"
            : diagnosticUserAgent
                ? "Korone's Discord Shell (User-Agent Probe)"
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
                        : diagnosticDiscord
                        ? "EnvironmentProbeUserData"
                        : "WebView2UserData");
            Directory.CreateDirectory(userDataFolder);
            var diagnosticPort = diagnosticBlank ? 9223 : diagnosticDiscord ? 9224 : 9225;
            var options = diagnosticBlank || diagnosticDiscord || diagnosticUserAgent
                ? new CoreWebView2EnvironmentOptions { AdditionalBrowserArguments = $"--remote-debugging-port={diagnosticPort}" }
                : null;
            var environment = await CoreWebView2Environment.CreateAsync(
                userDataFolder: userDataFolder,
                options: options);
            await webView.EnsureCoreWebView2Async(environment);
            webView.CoreWebView2.Settings.IsStatusBarEnabled = false;
            webView.CoreWebView2.Settings.AreDefaultContextMenusEnabled = true;
            webView.CoreWebView2.Settings.IsZoomControlEnabled = true;
            if (diagnosticUserAgent)
            {
                webView.CoreWebView2.Settings.UserAgent = DiagnosticOfficialUserAgent;
            }
            webView.CoreWebView2.NavigationCompleted += OnNavigationCompleted;
            webView.Source = new Uri(diagnosticBlank ? "about:blank" : DiscordWebApp);
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
                    : diagnosticDiscord
                    ? "Korone's Discord Shell (Environment Probe)"
                    : "Korone's Discord Shell (Prototype)";
        }
    }
}
