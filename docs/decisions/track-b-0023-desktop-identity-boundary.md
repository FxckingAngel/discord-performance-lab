# Track B decision 0023: desktop identity boundary

Track B now sends the same Discord desktop user-agent identity observed in the local Discord PTB installation:

`discord/1.0.1223 Chrome/148.0.7778.280 Electron/42.11.10`

That is only one environment signal. The sanitized WebView2 probe also showed that `navigator.userAgentData` continues to describe the embedded WebView2 browser, while `DiscordNative`, `electron`, `require`, `process`, and `module` remain absent. The shell therefore has a desktop-looking user-agent string but is not yet a desktop-capability-compatible Discord client.

The previous partial `DiscordNative` experiment caused Discord's frontend to stop after script loading and left a blank page. The normal shell must not expose another guessed Electron object or claim an unsupported native capability. Each future group must be added only after the official-side expectation is observed, the native Windows implementation exists, and the Discord workload is tested with a rollback path.

WebView2's documented `CoreWebView2.Settings.UserAgent` changes the user-agent string. Microsoft's documentation for `AddScriptToExecuteOnDocumentCreatedAsync` describes document-start script injection, but that mechanism is not evidence that a Discord desktop API is safe to emulate. It remains diagnostic-only until the expected API and behavior are known.

Current status:

- Desktop user-agent identity: implemented in the normal shell.
- WebView2 browser identity in user-agent data: still present and not overridden.
- `DiscordNative` compatibility surface: not implemented in the normal shell.
- Native titlebar/window controls: implemented by the shell itself, not exposed as a Discord API.
- Desktop parity gate: open.

Sources: [WebView2 UserAgent](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2settings2?view=webview2-1.0.2277.86) and [CoreWebView2 document-start scripts](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/winrt/microsoft.web.webview2.core/corewebview2?view=webview2-winrt-1.0.4129.50).
