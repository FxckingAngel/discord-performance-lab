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
    private readonly WebView2 webView = new() { Dock = DockStyle.Fill };

    public MainForm()
    {
        Text = "Korone's Discord Shell (Prototype)";
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
                "WebView2UserData");
            Directory.CreateDirectory(userDataFolder);
            var environment = await CoreWebView2Environment.CreateAsync(userDataFolder: userDataFolder);
            await webView.EnsureCoreWebView2Async(environment);
            webView.CoreWebView2.Settings.IsStatusBarEnabled = false;
            webView.CoreWebView2.Settings.AreDefaultContextMenusEnabled = true;
            webView.CoreWebView2.Settings.IsZoomControlEnabled = true;
            webView.CoreWebView2.NavigationCompleted += OnNavigationCompleted;
            webView.Source = new Uri(DiscordWebApp);
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
            Text = "Korone's Discord Shell (Prototype)";
        }
    }
}
