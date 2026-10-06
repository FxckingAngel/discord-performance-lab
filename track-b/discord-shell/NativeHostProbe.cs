using System;
using System.Drawing;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;

namespace KoroneDiscordShell;

internal sealed class NativeHostProbeContext : ApplicationContext
{
    private readonly NativeHostWindow window;

    public NativeHostProbeContext()
    {
        SynchronizationContext.SetSynchronizationContext(new WindowsFormsSynchronizationContext());
        window = new NativeHostWindow(this);
        window.CreateControl();
    }

    public void Exit()
    {
        ExitThread();
    }

    private sealed class NativeHostWindow : NativeWindow
    {
        private const int WmClose = 0x0010;
        private const int WmSize = 0x0005;
        private readonly NativeHostProbeContext owner;
        private CoreWebView2Controller? controller;
        private CoreWebView2? webView;

        public NativeHostWindow(NativeHostProbeContext owner)
        {
            this.owner = owner;
        }

        public void CreateControl()
        {
            var parameters = new CreateParams
            {
                Caption = "Korone's Discord Shell (Native Host Probe)",
                Style = 0x00CF0000,
                X = 100,
                Y = 100,
                Width = 1280,
                Height = 800,
            };
            CreateHandle(parameters);
            _ = InitializeWebViewAsync();
        }

        protected override void WndProc(ref Message message)
        {
            if (message.Msg == WmSize && controller is not null)
            {
                controller.Bounds = GetClientBounds();
            }
            else if (message.Msg == WmClose)
            {
                controller?.Close();
                owner.Exit();
            }
            base.WndProc(ref message);
        }

        private async Task InitializeWebViewAsync()
        {
            try
            {
                var userDataFolder = System.IO.Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    "KoroneDiscordShell",
                    "NativeHostProbeUserData");
                System.IO.Directory.CreateDirectory(userDataFolder);
                var environment = await CoreWebView2Environment.CreateAsync(userDataFolder: userDataFolder);
                controller = await environment.CreateCoreWebView2ControllerAsync(Handle);
                webView = controller.CoreWebView2;
                webView.Settings.IsStatusBarEnabled = false;
                controller.Bounds = GetClientBounds();
                controller.IsVisible = true;
                webView.Navigate("about:blank");
            }
            catch
            {
                owner.Exit();
            }
        }

        private Rectangle GetClientBounds()
        {
            var client = new Rectangle();
            if (Handle != IntPtr.Zero)
            {
                GetClientRect(Handle, out var rectangle);
                client = new Rectangle(0, 0, rectangle.Right - rectangle.Left, rectangle.Bottom - rectangle.Top);
            }
            return client;
        }

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        private static extern bool GetClientRect(IntPtr handle, out NativeRectangle rectangle);

        private struct NativeRectangle
        {
            public int Left;
            public int Top;
            public int Right;
            public int Bottom;
        }
    }
}
