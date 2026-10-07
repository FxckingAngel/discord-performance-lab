# Track B decision 0027: client-hints diagnostic boundary

Date: 2026-10-07

## Finding

The normal Track B shell applies the locally observed Discord Desktop user-agent string, but WebView2 still reports its own user-agent brands through `navigator.userAgentData`. The vanilla Discord control reported `Not/A)Brand` and `Chromium` brands, while the earlier Track B probe reported WebView2-specific brands. This leaves a measurable environment difference even though Electron globals and `DiscordNative` remain absent in both page worlds.

Microsoft documents that `CoreWebView2Settings.UserAgent` changes the user agent and may clear client-hint headers and `navigator.userAgentData`. Chromium's DevTools Protocol documents `Network.setUserAgentOverride` with `userAgentMetadata`, and WebView2 exposes that protocol through `CallDevToolsProtocolMethodAsync`.

Sources:

- https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2settings.useragent
- https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2.calldevtoolsprotocolmethodasync
- https://chromedevtools.github.io/devtools-protocol/tot/Network/#method-setUserAgentOverride

## Diagnostic mode

`--diagnostic-desktop-hints` uses a separate WebView2 profile and loopback CDP port 9233. It applies the observed Discord Desktop user-agent string together with the observed vanilla brand family and Windows platform metadata before navigation. It adds no `DiscordNative` object, Electron globals, authentication behavior, permission grant, entitlement, request interception, or protocol change.

The mode exists to answer one narrow question: does matching the client-hints surface change Discord's environment classification or visual behavior? It is not enabled in the normal shell. The normal shell remains the known-good no-bridge baseline until the mode has a live environment probe, visual comparison, functional check, and full-tree resource measurement.

## Verification status

| Check | Result |
|---|---|
| Release build | Passed; existing WindowsBase version-conflict warning remains |
| Static tool suite | Passed; 72 tools parsed and benchmark fixture passed |
| Source diff check | Passed |
| Live diagnostic launch | Not verified in this run; shell runner rejected the GUI process launch |
| Normal shell behavior | Unchanged by this diagnostic-only addition |

No production client-hints or desktop capability behavior is claimed from the unverified live run.
