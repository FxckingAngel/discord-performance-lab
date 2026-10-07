using System;
using System.IO;
using System.Drawing;
using System.Globalization;
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
    private const string DesktopIdentityUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) discord/1.0.1223 Chrome/148.0.7778.280 Electron/42.11.10 Safari/537.36";
    private readonly WebView2 webView = new() { Dock = DockStyle.Fill };
    private readonly bool diagnosticBlank;
    private readonly bool normalShell;
    private readonly bool diagnosticDiscord;
    private readonly bool diagnosticUserAgent;
    private readonly bool diagnosticDesktopHints;
    private readonly bool diagnosticWindowBridge;
    private readonly bool diagnosticHardwareBridge;
    private readonly bool diagnosticBridgePair;
    private readonly bool diagnosticBootContract;
    private readonly bool diagnosticSafeStorage;
    private readonly bool diagnosticErlpackBridge;
    private readonly bool diagnosticBootContractComplete;
    private readonly bool diagnosticFileDialog;
    private readonly bool diagnosticClipboard;
    private readonly bool diagnosticPowerMonitor;
    private readonly bool diagnosticAuthenticated;
    private readonly bool diagnosticCapabilityEvents;
    private readonly bool diagnosticAuthenticatedCapabilityEvents;
    private readonly bool diagnosticAuthenticatedNoBridges;
    private CoreWebView2Environment? webViewEnvironment;
    private string? webViewUserDataFolder;
    private bool webViewProcessInfoCaptured;
    private string? capabilityEventLogPath;
    private string? diagnosticNavigationLogPath;
    private readonly Panel titleBar = new() { Dock = DockStyle.Top, Height = 32 };
    private readonly Label titleLabel = new() { AutoEllipsis = true, Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleLeft };
    private readonly Button minimizeButton = new() { Dock = DockStyle.Right, FlatStyle = FlatStyle.Flat, Text = "—", Width = 42, TabStop = false, AccessibleName = "Minimize" };
    private readonly Button maximizeButton = new() { Dock = DockStyle.Right, FlatStyle = FlatStyle.Flat, Text = "□", Width = 42, TabStop = false, AccessibleName = "Maximize" };
    private readonly Button closeButton = new() { Dock = DockStyle.Right, FlatStyle = FlatStyle.Flat, Text = "×", Width = 42, TabStop = false, AccessibleName = "Close" };
    private readonly NotifyIcon trayIcon = new() { Icon = SystemIcons.Application, Visible = true, Text = "Discord" };
    private bool diagnosticFullscreen;
    private FormBorderStyle savedFullscreenBorderStyle;
    private FormWindowState savedFullscreenWindowState;
    private Rectangle savedFullscreenBounds;
    private bool savedFullscreenTitleBarVisible;

    public MainForm(bool normalShell, bool diagnosticBlank, bool diagnosticDiscord, bool diagnosticUserAgent, bool diagnosticDesktopHints, bool diagnosticWindowBridge, bool diagnosticHardwareBridge, bool diagnosticBridgePair, bool diagnosticBootContract, bool diagnosticSafeStorage, bool diagnosticErlpackBridge, bool diagnosticBootContractComplete, bool diagnosticFileDialog, bool diagnosticClipboard, bool diagnosticPowerMonitor, bool diagnosticAuthenticated, bool diagnosticCapabilityEvents, bool diagnosticAuthenticatedCapabilityEvents, bool diagnosticAuthenticatedNoBridges)
    {
        this.normalShell = normalShell;
        this.diagnosticBlank = diagnosticBlank;
        this.diagnosticDiscord = diagnosticDiscord;
        this.diagnosticUserAgent = diagnosticUserAgent;
        this.diagnosticDesktopHints = diagnosticDesktopHints;
        this.diagnosticWindowBridge = diagnosticWindowBridge;
        this.diagnosticHardwareBridge = diagnosticHardwareBridge;
        this.diagnosticBridgePair = diagnosticBridgePair;
        this.diagnosticBootContract = diagnosticBootContract;
        this.diagnosticSafeStorage = diagnosticSafeStorage;
        this.diagnosticErlpackBridge = diagnosticErlpackBridge;
        this.diagnosticBootContractComplete = diagnosticBootContractComplete;
        this.diagnosticFileDialog = diagnosticFileDialog;
        this.diagnosticClipboard = diagnosticClipboard;
        this.diagnosticPowerMonitor = diagnosticPowerMonitor;
        this.diagnosticAuthenticated = diagnosticAuthenticated;
        this.diagnosticCapabilityEvents = diagnosticCapabilityEvents;
        this.diagnosticAuthenticatedCapabilityEvents = diagnosticAuthenticatedCapabilityEvents;
        this.diagnosticAuthenticatedNoBridges = diagnosticAuthenticatedNoBridges;
        Text = diagnosticBlank
            ? "Korone's Discord Shell (Runtime Baseline)"
            : diagnosticUserAgent
                ? "Korone's Discord Shell (User-Agent Probe)"
                : diagnosticDesktopHints
                    ? "Korone's Discord Shell (Desktop Hints Probe)"
                : diagnosticWindowBridge
                    ? "Korone's Discord Shell (Window Bridge Probe)"
                : diagnosticHardwareBridge
                    ? "Korone's Discord Shell (Hardware Bridge Probe)"
                : diagnosticBridgePair
                    ? "Korone's Discord Shell (Bridge Pair Probe)"
                : diagnosticBootContract
                    ? "Korone's Discord Shell (Boot Contract Probe)"
                : diagnosticSafeStorage
                    ? "Korone's Discord Shell (Safe Storage Probe)"
                : diagnosticErlpackBridge
                    ? "Korone's Discord Shell (Erlpack Bridge Probe)"
                : diagnosticBootContractComplete
                    ? "Korone's Discord Shell (Complete Boot Contract Probe)"
                : diagnosticFileDialog
                    ? "Korone's Discord Shell (File Dialog Probe)"
                : diagnosticClipboard
                    ? "Korone's Discord Shell (Clipboard Probe)"
                : diagnosticPowerMonitor
                    ? "Korone's Discord Shell (Power Monitor Probe)"
                : diagnosticAuthenticated
                    ? "Korone's Discord Shell (Authenticated Profile Probe)"
                : diagnosticAuthenticatedCapabilityEvents
                    ? "Korone's Discord Shell (Authenticated Capability Events Probe)"
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
        Resize += (_, _) =>
        {
            UpdateMaximizeButton();
            UpdateWebViewVisibility();
        };
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
                    : diagnosticDesktopHints
                        ? "DesktopHintsProbeUserData"
                        : diagnosticWindowBridge
                            ? "WindowBridgeProbeUserData"
                        : diagnosticHardwareBridge
                            ? "HardwareBridgeProbeUserData"
                        : diagnosticBridgePair
                            ? "BridgePairProbeUserData"
                        : diagnosticBootContract
                            ? "WebView2UserData"
                        : diagnosticSafeStorage
                            ? "SafeStorageProbeUserData"
                        : diagnosticErlpackBridge
                            ? "ErlpackBridgeProbeUserData"
                        : diagnosticBootContractComplete
                            ? "WebView2UserData"
                        : diagnosticFileDialog
                            ? "FileDialogProbeUserData"
                        : diagnosticClipboard
                            ? "ClipboardProbeUserData"
                        : diagnosticPowerMonitor
                            ? "PowerMonitorProbeUserData"
                        // Authenticated capability events intentionally reuse the authenticated profile.
                        // A separate empty profile would not exercise the authenticated frontend path.
                        : diagnosticAuthenticated || diagnosticAuthenticatedCapabilityEvents
                            ? "WebView2UserData"
                        : diagnosticAuthenticatedNoBridges
                            ? "WebView2UserData"
                        : diagnosticCapabilityEvents
                            ? "CapabilityEventsProbeUserData"
                        : diagnosticDiscord
                        ? "EnvironmentProbeUserData"
                        : "WebView2UserData");
            Directory.CreateDirectory(userDataFolder);
            var diagnosticPort = diagnosticBlank ? 9223 : diagnosticDiscord ? 9224 : diagnosticUserAgent ? 9225 : diagnosticDesktopHints ? 9233 : diagnosticWindowBridge ? 9226 : diagnosticHardwareBridge ? 9227 : diagnosticBridgePair ? 9229 : diagnosticBootContract ? 9236 : diagnosticSafeStorage ? 9237 : diagnosticErlpackBridge ? 9238 : diagnosticBootContractComplete ? 9239 : diagnosticFileDialog ? 9240 : diagnosticClipboard ? 9241 : diagnosticPowerMonitor ? 9242 : diagnosticAuthenticatedNoBridges ? 9230 : diagnosticCapabilityEvents ? 9231 : diagnosticAuthenticatedCapabilityEvents ? 9232 : 9228;
            var options = diagnosticBlank || diagnosticDiscord || diagnosticUserAgent || diagnosticDesktopHints || diagnosticWindowBridge || diagnosticHardwareBridge || diagnosticBridgePair || diagnosticBootContract || diagnosticSafeStorage || diagnosticErlpackBridge || diagnosticBootContractComplete || diagnosticFileDialog || diagnosticClipboard || diagnosticPowerMonitor || diagnosticAuthenticated || diagnosticAuthenticatedNoBridges || diagnosticCapabilityEvents || diagnosticAuthenticatedCapabilityEvents
                ? new CoreWebView2EnvironmentOptions { AdditionalBrowserArguments = $"--remote-debugging-port={diagnosticPort}" }
                : null;
            if (options is not null)
            {
                var diagnosticsDirectory = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    "KoroneDiscordShell",
                    "Diagnostics");
                Directory.CreateDirectory(diagnosticsDirectory);
                diagnosticNavigationLogPath = Path.Combine(
                    diagnosticsDirectory,
                    $"navigation-events-{diagnosticPort}-{DateTime.UtcNow:yyyyMMdd-HHmmssfff}.jsonl");
            }
            var environment = await CoreWebView2Environment.CreateAsync(
                userDataFolder: userDataFolder,
                options: options);
            webViewEnvironment = environment;
            webViewUserDataFolder = userDataFolder;
            environment.ProcessInfosChanged += OnWebViewProcessInfosChanged;
            await webView.EnsureCoreWebView2Async(environment);
            UpdateWebViewVisibility();
            if (diagnosticSafeStorage)
            {
                webView.CoreWebView2.AddHostObjectToScript("trackBSafeStorage", new SafeStorageHostObject());
                await webView.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(@"
(() => {
  const host = chrome.webview.hostObjects.sync.trackBSafeStorage;
  Object.defineProperty(globalThis, 'DiscordNative', {
    configurable: false,
    enumerable: false,
    value: Object.freeze({
      safeStorage: Object.freeze({
        isEncryptionAvailable: () => host.IsEncryptionAvailable(),
        encryptString: (plainText) => host.EncryptString(plainText),
        decryptString: (encrypted) => host.DecryptString(encrypted),
      }),
    }),
  });
})();");
            }
            if (diagnosticFileDialog)
            {
                webView.CoreWebView2.AddHostObjectToScript("trackBFileDialog", new FileDialogHostObject());
                await webView.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(@"
(() => {
  const host = chrome.webview.hostObjects.trackBFileDialog;
              const fileManager = Object.freeze({
    showOpenDialog: (options = {}) => host.ShowOpenDialog(JSON.stringify(options)).then(result => JSON.parse(result).filePaths),
    showItemInFolder: (path) => host.ShowItemInFolder(path),
    saveWithDialog: (fileContents, fileName, defaultDirectory) => JSON.parse(host.SaveWithDialog2(fileContents, fileName, defaultDirectory, true)).directory || null,
    saveWithDialog2: (fileContents, fileName, defaultDirectory, throwOnCancel = false) => JSON.parse(host.SaveWithDialog2(fileContents, fileName, defaultDirectory, throwOnCancel)),
  });
  Object.defineProperty(globalThis, 'DiscordNative', {
    configurable: false,
    enumerable: false,
    value: Object.freeze({ fileManager }),
  });
})();");
            }
            if (diagnosticErlpackBridge)
            {
                var wetfPath = Path.Combine(AppContext.BaseDirectory, "web", "vendor", "wetf", "wetf.js");
                var wetfBundle = await File.ReadAllTextAsync(wetfPath);
                var erlpackScript = wetfBundle + @"
(() => {
  const packer = new globalThis.Wetf.Packer({ useLegacyAtoms: true, encoding: { key: 'binary', string: 'binary', array: 'list' } });
  const unpacker = new globalThis.Wetf.Unpacker({ decoding: { binary: 'utf8', string: 'utf8', nil: 'null' } });
  const module = Object.freeze({
    pack: (value) => packer.pack(value),
    unpack: (value) => unpacker.unpack(value),
  });
  Object.defineProperty(globalThis, 'DiscordNative', {
    configurable: false,
    enumerable: false,
    value: Object.freeze({
      nativeModules: Object.freeze({
        requireModule: (name) => {
          if (name !== 'discord_erlpack') throw new Error('Unsupported native module.');
          return module;
        },
      }),
    }),
  });
})();";
                await webView.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(erlpackScript);
            }
            if (diagnosticBootContractComplete)
            {
                webView.CoreWebView2.AddHostObjectToScript("trackBSafeStorage", new SafeStorageHostObject());
                webView.CoreWebView2.AddHostObjectToScript("trackBProcessUtils", new ProcessUtilsHostObject());
                var wetfPath = Path.Combine(AppContext.BaseDirectory, "web", "vendor", "wetf", "wetf.js");
                var wetfBundle = await File.ReadAllTextAsync(wetfPath);
                var metadata = JsonSerializer.Serialize(new
                {
                    process = new
                    {
                        env = new { },
                        arch = RuntimeInformation.ProcessArchitecture.ToString().ToLowerInvariant(),
                        platform = "win32",
                        pid = Environment.ProcessId,
                    },
                    os = new
                    {
                        buildRevision = (string?)null,
                        release = Environment.OSVersion.VersionString,
                        arch = RuntimeInformation.OSArchitecture.ToString().ToLowerInvariant(),
                        appArch = RuntimeInformation.ProcessArchitecture.ToString().ToLowerInvariant(),
                    },
                    app = new
                    {
                        version = "1.0.1223",
                        buildNumber = (string?)null,
                        releaseChannel = "ptb",
                        appArch = RuntimeInformation.ProcessArchitecture.ToString().ToLowerInvariant(),
                        preferredSystemLanguages = new[] { CultureInfo.CurrentUICulture.Name },
                    },
                    cpuCoreCount = Environment.ProcessorCount,
                });
                var completeBootScript = wetfBundle + @"
(() => {
  const metadata = @@BOOT_METADATA@@;
  const moduleRequests = [];
  globalThis.__trackBModuleRequests = moduleRequests;
   const safeStorageHost = chrome.webview.hostObjects.sync.trackBSafeStorage;
   const processUtilsHost = chrome.webview.hostObjects.sync.trackBProcessUtils;
  const packer = new globalThis.Wetf.Packer({ useLegacyAtoms: true, encoding: { key: 'binary', string: 'binary', array: 'list' } });
  const unpacker = new globalThis.Wetf.Unpacker({ decoding: { binary: 'utf8', string: 'utf8', nil: 'null' } });
  const erlpack = { pack: (value) => packer.pack(value), unpack: (value) => unpacker.unpack(value) };
   const nativeModules = {
     requireModule: (name) => {
       moduleRequests.push(typeof name === 'string' && /^(?:discord_[a-z0-9_-]+|erlpack)$/.test(name) ? name : `<${typeof name}>`);
       if (name !== 'discord_erlpack' && name !== 'erlpack') throw new Error('Unsupported native module.');
       return erlpack;
     },
  };
  const app = {
    getVersion: () => metadata.app.version,
    getBuildNumber: () => metadata.app.buildNumber,
    getReleaseChannel: () => metadata.app.releaseChannel,
    getModuleVersions: () => ({}),
    getPreferredSystemLanguages: () => Promise.resolve(metadata.app.preferredSystemLanguages),
    getAppArch: () => metadata.app.appArch,
  };
   const safeStorage = {
    isEncryptionAvailable: () => safeStorageHost.IsEncryptionAvailable(),
    encryptString: (plainText) => safeStorageHost.EncryptString(plainText),
     decryptString: (encrypted) => safeStorageHost.DecryptString(encrypted),
   };
   const processUtils = {
     getCPUCoreCount: () => processUtilsHost.GetCPUCoreCount(),
     getCurrentCPUUsagePercent: () => processUtilsHost.GetCurrentCPUUsagePercent(),
     getProcessUptime: () => processUtilsHost.GetProcessUptime(),
     setMemoryInformation: (...args) => {
       access.calls.push('processUtils.setMemoryInformation');
       access.argumentShapes.push({ path: 'processUtils.setMemoryInformation', shapes: args.map((value) => value === null ? 'null' : Array.isArray(value) ? 'array' : typeof value) });
       return undefined;
     },
   };
   const stringFingerprint = (value) => {
     let hash = 2166136261;
     for (let index = 0; index < value.length; index += 1) {
       hash ^= value.charCodeAt(index);
       hash = Math.imul(hash, 16777619);
     }
     return `${value.length}:${hash >>> 0}`;
   };
   const ipc = {
     send: (...args) => {
       access.calls.push('ipc.send');
       access.argumentShapes.push({ path: 'ipc.send', shapes: args.map((value) => value === null ? 'null' : Array.isArray(value) ? 'array' : typeof value) });
       if (typeof args[0] === 'string') access.stringFingerprints.push({ path: 'ipc.send', fingerprint: stringFingerprint(args[0]) });
       return undefined;
     },
     invoke: (...args) => {
       access.calls.push('ipc.invoke');
       access.argumentShapes.push({ path: 'ipc.invoke', shapes: args.map((value) => value === null ? 'null' : Array.isArray(value) ? 'array' : typeof value) });
       return Promise.resolve(undefined);
     },
     on: (...args) => {
       access.calls.push('ipc.on');
       access.argumentShapes.push({ path: 'ipc.on', shapes: args.map((value) => value === null ? 'null' : Array.isArray(value) ? 'array' : typeof value) });
       return () => undefined;
     },
   };
  let uncaughtExceptionHandler = null;
  const setUncaughtExceptionHandler = (handler) => {
    uncaughtExceptionHandler = typeof handler === 'function' ? handler : null;
  };
  globalThis.addEventListener('error', (event) => {
    if (uncaughtExceptionHandler) uncaughtExceptionHandler(event.error, 'uncaughtException');
  });
  globalThis.addEventListener('unhandledrejection', (event) => {
    if (uncaughtExceptionHandler) uncaughtExceptionHandler(event.reason, 'unhandledRejection');
  });
   const access = { missing: [], calls: [], errors: [], argumentShapes: [], stringFingerprints: [], returnShapes: [] };
  globalThis.__trackBBootContractAccess = access;
  const valueShape = (value) => value === null ? 'null' : Array.isArray(value) ? 'array' : typeof value;
  const recordReturn = (path, value, promise) => {
    access.returnShapes.push({ path, shape: valueShape(value), promise });
    return value;
  };
  const observeGroup = (name, value) => new Proxy(value, {
    get(target, property, receiver) {
      if (typeof property === 'string' && !(property in target)) access.missing.push(`${name}.${property}`);
      const result = Reflect.get(target, property, receiver);
      if (typeof property !== 'string' || typeof result !== 'function') return result;
      return (...args) => {
        access.calls.push(`${name}.${property}`);
        try {
          const returned = result(...args);
          if (returned && typeof returned.then === 'function') {
            return Promise.resolve(returned).then(
              (resolved) => recordReturn(`${name}.${property}`, resolved, true),
              (error) => {
                access.errors.push(`${name}.${property}:${error?.name ?? 'Error'}`);
                throw error;
              });
          }
          return recordReturn(`${name}.${property}`, returned, false);
        }
        catch (error) {
          access.errors.push(`${name}.${property}:${error?.name ?? 'Error'}`);
          throw error;
        }
      };
    },
  });
  const contract = {
    isRenderer: true,
    setUncaughtExceptionHandler,
    nativeModules: observeGroup('nativeModules', nativeModules),
    process: observeGroup('process', metadata.process),
    os: observeGroup('os', metadata.os),
    app: observeGroup('app', app),
    safeStorage: observeGroup('safeStorage', safeStorage),
    processUtils: observeGroup('processUtils', processUtils),
    ipc: observeGroup('ipc', ipc),
  };
  globalThis.__trackBBootContractActivation = Object.freeze({
    mode: 'diagnostic-only',
    shape: 'atomic-candidate',
    bootContractVersion: 1,
    implementation: 'isolated-capabilities-composed-for-diagnostic-activation',
    activation: 'atomic-only',
    groups: Object.freeze(['process', 'os', 'app', 'safeStorage', 'nativeModules', 'processUtils', 'ipc']),
    unsupportedModules: Object.freeze(['discord_voice', 'discord_utils', 'discord_zstd']),
    placeholderPaths: Object.freeze([
      'processUtils.setMemoryInformation',
      'ipc.send',
      'ipc.invoke',
      'ipc.on',
    ]),
  });
  const exposed = new Proxy(contract, {
    get(target, property, receiver) {
      if (typeof property === 'string' && !(property in target)) access.missing.push(property);
      return Reflect.get(target, property, receiver);
    },
  });
  Object.defineProperty(globalThis, 'DiscordNative', {
    configurable: false,
    enumerable: false,
    value: Object.freeze(exposed),
  });
})();".Replace("@@BOOT_METADATA@@", metadata, StringComparison.Ordinal);
                await webView.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(completeBootScript);
            }
            if (diagnosticCapabilityEvents || diagnosticAuthenticatedCapabilityEvents || diagnosticBootContract)
            {
                var diagnosticsDirectory = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    "KoroneDiscordShell",
                    "Diagnostics");
                Directory.CreateDirectory(diagnosticsDirectory);
                capabilityEventLogPath = Path.Combine(
                    diagnosticsDirectory,
                    $"capability-events-{Environment.ProcessId}-{DateTime.UtcNow:yyyyMMdd-HHmmssfff}.jsonl");
                webView.CoreWebView2.PermissionRequested += OnPermissionRequested;
                webView.CoreWebView2.NotificationReceived += OnNotificationReceived;
                webView.CoreWebView2.DownloadStarting += OnDownloadStarting;
                webView.CoreWebView2.ScreenCaptureStarting += OnScreenCaptureStarting;
            }
            webView.CoreWebView2.Settings.IsStatusBarEnabled = false;
            webView.CoreWebView2.Settings.AreDefaultContextMenusEnabled = true;
            webView.CoreWebView2.Settings.IsZoomControlEnabled = true;
            webView.CoreWebView2.NavigationStarting += OnNavigationStarting;
            // Discord aborts frontend initialization when a partial DiscordNative object is present.
            // Keep the audited bridge behind explicit diagnostic modes until its full capability set is implemented.
            // Keep partial bridge experiments out of authenticated diagnostics. The
            // Discord frontend treats a partial DiscordNative root as a boot contract.
            var enableWindowBridge = diagnosticWindowBridge || diagnosticBridgePair;
            var enableHardwareBridge = diagnosticHardwareBridge || diagnosticBridgePair;
            if (enableWindowBridge || enableHardwareBridge || diagnosticBootContract)
            {
                webView.CoreWebView2.WebMessageReceived += OnWebMessageReceived;
            }
            // Identify the shell as Discord Desktop without claiming unsupported native capabilities.
            // This changes the client runtime identity only; it does not alter auth, permissions, or protocol behavior.
            webView.CoreWebView2.Settings.UserAgent = DesktopIdentityUserAgent;
            if (normalShell || diagnosticDesktopHints)
            {
                var userAgentOverride = JsonSerializer.Serialize(new
                {
                    userAgent = DesktopIdentityUserAgent,
                    acceptLanguage = "en-US,en",
                    platform = "Win32",
                    userAgentMetadata = new
                    {
                        brands = new[]
                        {
                            new { brand = "Not/A)Brand", version = "99" },
                            new { brand = "Chromium", version = "148" },
                        },
                        fullVersionList = new[]
                        {
                            new { brand = "Not/A)Brand", version = "99.0.0.0" },
                            new { brand = "Chromium", version = "148.0.7778.280" },
                        },
                        platform = "Windows",
                        platformVersion = "10.0.0",
                        architecture = "x86",
                        model = "",
                        mobile = false,
                        bitness = "64",
                        wow64 = false,
                    },
                });
                await webView.CoreWebView2.CallDevToolsProtocolMethodAsync("Network.setUserAgentOverride", userAgentOverride);
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
    const actions = new Set(['minimize', 'maximize', 'restore', 'close', 'focus', 'setAlwaysOnTop', 'fullscreen']);
    const pending = new Map();
    let nextId = 1;
    chrome.webview.addEventListener('message', (event) => {
      const message = event.data;
      if (message?.source !== 'track-b-window-result' || !pending.has(message.id)) return;
      const request = pending.get(message.id);
      pending.delete(message.id);
      if (message.error) request.reject(new Error(message.error));
      else request.resolve(message.value);
    });
    const send = (action, value) => {
      if (!actions.has(action)) return;
      chrome.webview.postMessage(JSON.stringify({ source: 'track-b-window', action, value }));
    };
    const isAlwaysOnTop = () => new Promise((resolve, reject) => {
      const id = nextId++;
      pending.set(id, { resolve, reject });
      chrome.webview.postMessage(JSON.stringify({ source: 'track-b-window', action: 'isAlwaysOnTop', id }));
    });
    const fullscreen = (value) => new Promise((resolve, reject) => {
      const id = nextId++;
      pending.set(id, { resolve, reject });
      chrome.webview.postMessage(JSON.stringify({ source: 'track-b-window', action: 'fullscreen', id, value: Boolean(value) }));
    });
    const windowBridge = Object.fromEntries([...actions].map((action) => [action, (value) => send(action, value)]));
    windowBridge.setMinimumSize = (width, height) => send('setMinimumSize', { width, height });
    windowBridge.isAlwaysOnTop = isAlwaysOnTop;
    windowBridge.fullscreen = fullscreen;
    Object.defineProperty(target, 'window', { configurable: false, enumerable: true, value: Object.freeze(windowBridge) });
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
            if (diagnosticBootContract)
            {
                var bootMetadata = JsonSerializer.Serialize(new
                {
                    process = new
                    {
                        env = new { },
                        arch = RuntimeInformation.ProcessArchitecture.ToString().ToLowerInvariant(),
                        platform = "win32",
                        pid = Environment.ProcessId,
                    },
                    os = new
                    {
                        buildRevision = (string?)null,
                        release = Environment.OSVersion.VersionString,
                        arch = RuntimeInformation.OSArchitecture.ToString().ToLowerInvariant(),
                        appArch = RuntimeInformation.ProcessArchitecture.ToString().ToLowerInvariant(),
                    },
                    app = new
                    {
                        version = Application.ProductVersion,
                        buildNumber = (string?)null,
                        releaseChannel = "local",
                        appArch = RuntimeInformation.ProcessArchitecture.ToString().ToLowerInvariant(),
                    },
                });
                var bootContractScript = @"
(() => {
  const shape = (value) => value === null ? 'null' : Array.isArray(value) ? 'array' : typeof value;
  const record = (eventType, path, args = []) => {
    try {
      const safeArgumentValues = path.endsWith('.nativeModules.requireModule')
        ? args.map((value) => typeof value === 'string' && (/^discord_[a-z0-9_-]+$/.test(value) || value === 'erlpack') ? value : null)
        : [];
      chrome.webview.postMessage(JSON.stringify({ source: 'track-b-boot-contract', eventType, path, argumentCount: args.length, argumentShapes: args.map(shape), safeArgumentValues }));
    } catch {}
  };
  const make = (path) => new Proxy(function () {}, {
    get(target, property) {
      if (typeof property === 'symbol') return undefined;
      const next = `${path}.${String(property)}`;
      record('get', next);
      return make(next);
    },
    apply(target, thisArg, args) {
      record('call', path, args);
      return undefined;
    },
    has() { return false; },
    ownKeys() { return []; },
    getOwnPropertyDescriptor() { return undefined; }
  });
  const metadata = @@BOOT_METADATA@@;
  const target = {
    process: metadata.process,
    os: metadata.os,
    app: {
      getVersion: () => metadata.app.version,
      getBuildNumber: () => metadata.app.buildNumber,
      getReleaseChannel: () => metadata.app.releaseChannel,
      getAppArch: () => metadata.app.appArch,
    },
  };
  for (const name of ['safeStorage', 'nativeModules']) target[name] = make(`DiscordNative.${name}`);
  Object.defineProperty(globalThis, 'DiscordNative', { configurable: false, enumerable: false, value: new Proxy(target, {
    get(object, property) {
      if (property in object) { record('get', `DiscordNative.${String(property)}`); return object[property]; }
      return make(`DiscordNative.${String(property)}`);
    }
  }) });
})();".Replace("@@BOOT_METADATA@@", bootMetadata, StringComparison.Ordinal);
                await webView.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(bootContractScript);
            }
            if (diagnosticSafeStorage)
            {
                webView.NavigateToString("<!doctype html><html><head><title>Safe Storage Probe</title></head><body></body></html>");
                return;
            }
            if (diagnosticClipboard)
            {
                webView.CoreWebView2.AddHostObjectToScript("trackBClipboard", new ClipboardHostObject(new SyntheticClipboardBackend()));
                await webView.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(@"
(() => {
  const host = chrome.webview.hostObjects.sync.trackBClipboard;
  const clipboard = Object.freeze({
    copy: (text) => host.Copy(text),
    copyImage: (imageArrayBuffer, imageSource) => host.CopyImage(imageArrayBuffer, imageSource),
    copyFile: (filePath) => host.CopyFile(filePath),
    cut: () => host.Cut(),
    paste: () => host.Paste(),
    read: () => host.Read(),
    hasMixedContent: () => host.HasMixedContent(),
  });
  Object.defineProperty(globalThis, 'DiscordNative', {
    configurable: false,
    enumerable: false,
    value: Object.freeze({ clipboard }),
  });
})();");
                webView.NavigateToString("<!doctype html><html><head><title>Clipboard Probe</title></head><body></body></html>");
                return;
            }
            if (diagnosticPowerMonitor)
            {
                webView.CoreWebView2.AddHostObjectToScript("trackBPowerMonitor", new PowerMonitorHostObject());
                await webView.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(@"
(() => {
  const host = chrome.webview.hostObjects.sync.trackBPowerMonitor;
  const powerMonitor = Object.freeze({
    getSystemIdleTimeMs: () => host.GetSystemIdleTimeMs(),
  });
  Object.defineProperty(globalThis, 'DiscordNative', {
    configurable: false,
    enumerable: false,
    value: Object.freeze({ powerMonitor }),
  });
})();");
                webView.NavigateToString("<!doctype html><html><head><title>Power Monitor Probe</title></head><body></body></html>");
                return;
            }
            if (diagnosticFileDialog)
            {
                webView.NavigateToString("<!doctype html><html><head><title>File Dialog Probe</title></head><body></body></html>");
                return;
            }
            if (diagnosticErlpackBridge)
            {
                webView.NavigateToString("<!doctype html><html><head><title>Erlpack Bridge Probe</title></head><body></body></html>");
                return;
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
            WriteDiagnosticEvent("startup-error", new
            {
                exceptionType = error.GetType().FullName,
                hResult = error.HResult,
            });
            MessageBox.Show(
                this,
                $"The WebView2 shell could not start.\n\n{error.Message}",
                "Korone's Discord Shell",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
        }
    }

    private void UpdateWebViewVisibility()
    {
        webView.Visible = WindowState != FormWindowState.Minimized;
    }

    private async void OnNavigationCompleted(object? sender, CoreWebView2NavigationCompletedEventArgs e)
    {
        WriteDiagnosticEvent("navigation-completed", new
        {
            isSuccess = e.IsSuccess,
            webErrorStatus = e.WebErrorStatus.ToString(),
        });
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
                    : diagnosticBootContract
                        ? "Korone's Discord Shell (Boot Contract Probe)"
                : diagnosticSafeStorage
                        ? "Korone's Discord Shell (Safe Storage Probe)"
                    : diagnosticBootContractComplete
                        ? "Korone's Discord Shell (Complete Boot Contract Probe)"
                    : diagnosticAuthenticated
                        ? "Korone's Discord Shell (Authenticated Profile Probe)"
                    : diagnosticAuthenticatedCapabilityEvents
                            ? "Korone's Discord Shell (Authenticated Capability Events Probe)"
                    : diagnosticAuthenticatedNoBridges
                        ? "Korone's Discord Shell (Authenticated No-Bridge Probe)"
                    : diagnosticCapabilityEvents
                            ? "Korone's Discord Shell (Capability Events Probe)"
                    : diagnosticDiscord
                    ? "Korone's Discord Shell (Environment Probe)"
                    : "Korone's Discord Shell (Prototype)";
            titleLabel.Text = Text;
        }
        if (e.IsSuccess && webViewEnvironment is not null && webViewUserDataFolder is not null && !webViewProcessInfoCaptured)
        {
            webViewProcessInfoCaptured = true;
            await WriteWebViewProcessInfoAsync(webViewEnvironment, webViewUserDataFolder);
        }
    }

    private void OnNavigationStarting(object? sender, CoreWebView2NavigationStartingEventArgs e)
    {
        WriteDiagnosticEvent("navigation-starting", new { });
    }

    private void WriteDiagnosticEvent(string eventType, object details)
    {
        if (diagnosticNavigationLogPath is null) return;
        try
        {
            var payload = JsonSerializer.Serialize(new
            {
                capturedAt = DateTime.UtcNow.ToString("O"),
                eventType,
                details,
            });
            File.AppendAllText(diagnosticNavigationLogPath, payload + Environment.NewLine);
        }
        catch
        {
            // Diagnostics must never interfere with the shell.
        }
    }

    private void OnWebViewProcessInfosChanged(object? sender, object e)
    {
        if (webViewEnvironment is not null && webViewUserDataFolder is not null)
        {
            _ = WriteWebViewProcessInfoAsync(webViewEnvironment, webViewUserDataFolder);
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

    private static async Task WriteWebViewProcessInfoAsync(CoreWebView2Environment environment, string userDataFolder)
    {
        try
        {
            var diagnosticsDirectory = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "KoroneDiscordShell",
                "Diagnostics");
            Directory.CreateDirectory(diagnosticsDirectory);
            var processes = environment.GetProcessInfos();
            var extendedProcesses = await environment.GetProcessExtendedInfosAsync();
            var rows = new List<object>();
            foreach (var process in processes)
            {
                var extended = extendedProcesses.FirstOrDefault(item => item.ProcessInfo.ProcessId == process.ProcessId);
                var activeFrameCount = 0;
                if (extended is not null)
                {
                    activeFrameCount = extended.AssociatedFrameInfos.Count;
                }
                rows.Add(new
                {
                    processId = process.ProcessId,
                    kind = process.Kind.ToString(),
                    activeFrameCount,
                });
            }
            File.WriteAllText(
                Path.Combine(diagnosticsDirectory, "webview-process-info.json"),
                JsonSerializer.Serialize(new
                {
                    capturedAt = DateTime.UtcNow,
                    processCount = rows.Count,
                    userDataFolderName = Path.GetFileName(userDataFolder),
                    processes = rows,
                }));
            var profileName = Path.GetFileName(userDataFolder);
            if (!string.IsNullOrWhiteSpace(profileName))
            {
                File.WriteAllText(
                    Path.Combine(diagnosticsDirectory, $"webview-process-info-{profileName}.json"),
                    JsonSerializer.Serialize(new
                    {
                        capturedAt = DateTime.UtcNow,
                        processCount = rows.Count,
                        userDataFolderName = profileName,
                        processes = rows,
                    }));
            }
        }
        catch
        {
            // Diagnostic process metadata must never affect page startup.
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

    private void SetDiagnosticFullscreen(bool enabled, int requestId)
    {
        if (enabled && !diagnosticFullscreen)
        {
            savedFullscreenBorderStyle = FormBorderStyle;
            savedFullscreenWindowState = WindowState;
            savedFullscreenBounds = Bounds;
            savedFullscreenTitleBarVisible = titleBar.Visible;
            WindowState = FormWindowState.Normal;
            FormBorderStyle = FormBorderStyle.None;
            titleBar.Visible = false;
            Bounds = Screen.FromHandle(Handle).Bounds;
            diagnosticFullscreen = true;
        }
        else if (!enabled && diagnosticFullscreen)
        {
            titleBar.Visible = savedFullscreenTitleBarVisible;
            FormBorderStyle = savedFullscreenBorderStyle;
            Bounds = savedFullscreenBounds;
            WindowState = savedFullscreenWindowState;
            diagnosticFullscreen = false;
        }

        UpdateWebViewVisibility();
        webView.CoreWebView2.PostWebMessageAsJson(JsonSerializer.Serialize(new
        {
            source = "track-b-window-result",
            id = requestId,
            value = diagnosticFullscreen,
        }));
    }

    private void OnWebMessageReceived(object? sender, CoreWebView2WebMessageReceivedEventArgs e)
    {
        if (!diagnosticWindowBridge
            && !diagnosticHardwareBridge
            && !diagnosticBridgePair
            && !diagnosticBootContract
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
        bool? requestedTopMost = null;
        bool? requestedFullscreen = null;
        Size? requestedMinimumSize = null;
        try
        {
            using var document = JsonDocument.Parse(message);
            var root = document.RootElement;
            if (!root.TryGetProperty("source", out var source))
            {
                return;
            }

            var sourceName = source.GetString();
            if (string.Equals(sourceName, "track-b-boot-contract", StringComparison.Ordinal))
            {
                WriteCapabilityEvent(new
                {
                    eventType = root.TryGetProperty("eventType", out var eventType) ? eventType.GetString() : null,
                    path = root.TryGetProperty("path", out var path) ? path.GetString() : null,
                    argumentCount = root.TryGetProperty("argumentCount", out var count) && count.TryGetInt32(out var value) ? value : 0,
                    argumentShapes = root.TryGetProperty("argumentShapes", out var shapes) ? shapes.EnumerateArray().Select(item => item.GetString()).ToArray() : Array.Empty<string?>(),
                    safeArgumentValues = root.TryGetProperty("safeArgumentValues", out var safeValues) ? safeValues.EnumerateArray().Select(item => item.ValueKind == JsonValueKind.String ? item.GetString() : null).ToArray() : Array.Empty<string?>(),
                });
                return;
            }
            if (!root.TryGetProperty("action", out var actionElement))
            {
                return;
            }

            action = actionElement.GetString();
            if (string.Equals(sourceName, "track-b-hardware", StringComparison.Ordinal))
            {
                if (!string.Equals(action, "getDisplayCount", StringComparison.Ordinal)
                    || !root.TryGetProperty("id", out var idElement)
                    || !idElement.TryGetInt32(out var id))
                {
                    return;
                }

                if (diagnosticCapabilityEvents || diagnosticAuthenticatedCapabilityEvents)
                {
                    WriteCapabilityEvent(new
                    {
                        eventType = "capability-call",
                        group = "hardware",
                        action = "getDisplayCount",
                    });
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

            if (root.TryGetProperty("value", out var topMostValue)
                && (topMostValue.ValueKind == JsonValueKind.True || topMostValue.ValueKind == JsonValueKind.False))
            {
                requestedTopMost = topMostValue.GetBoolean();
            }
            if (root.TryGetProperty("value", out var fullscreenValue)
                && (fullscreenValue.ValueKind == JsonValueKind.True || fullscreenValue.ValueKind == JsonValueKind.False))
            {
                requestedFullscreen = fullscreenValue.GetBoolean();
            }
            if (root.TryGetProperty("value", out var minimumSizeValue)
                && minimumSizeValue.ValueKind == JsonValueKind.Object
                && minimumSizeValue.TryGetProperty("width", out var widthValue)
                && minimumSizeValue.TryGetProperty("height", out var heightValue)
                && widthValue.TryGetInt32(out var width)
                && heightValue.TryGetInt32(out var height)
                && width >= 160 && width <= 10000
                && height >= 120 && height <= 10000)
            {
                requestedMinimumSize = new Size(width, height);
            }

            if (string.Equals(action, "isAlwaysOnTop", StringComparison.Ordinal))
            {
                if (!root.TryGetProperty("id", out var queryId) || !queryId.TryGetInt32(out var queryIdValue))
                {
                    return;
                }

                if (diagnosticCapabilityEvents || diagnosticAuthenticatedCapabilityEvents)
                {
                    WriteCapabilityEvent(new
                    {
                        eventType = "capability-call",
                        group = "window",
                        action,
                    });
                }

                webView.CoreWebView2.PostWebMessageAsJson(JsonSerializer.Serialize(new
                {
                    source = "track-b-window-result",
                    id = queryIdValue,
                    value = TopMost,
                }));
                return;
            }

            if (string.Equals(action, "fullscreen", StringComparison.Ordinal))
            {
                if (!root.TryGetProperty("id", out var fullscreenId)
                    || !fullscreenId.TryGetInt32(out var fullscreenIdValue)
                    || !requestedFullscreen.HasValue)
                {
                    return;
                }

                if (diagnosticCapabilityEvents || diagnosticAuthenticatedCapabilityEvents)
                {
                    WriteCapabilityEvent(new
                    {
                        eventType = "capability-call",
                        group = "window",
                        action,
                    });
                }

                SetDiagnosticFullscreen(requestedFullscreen.Value, fullscreenIdValue);
                return;
            }

            if (diagnosticCapabilityEvents || diagnosticAuthenticatedCapabilityEvents)
            {
                WriteCapabilityEvent(new
                {
                    eventType = "capability-call",
                    group = "window",
                    action,
                });
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
            case "setAlwaysOnTop":
                if (requestedTopMost.HasValue) TopMost = requestedTopMost.Value;
                break;
            case "setMinimumSize":
                if (requestedMinimumSize.HasValue) MinimumSize = requestedMinimumSize.Value;
                break;
        }
    }
}
