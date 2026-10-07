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

The mode answered the environment-identification question. The live probe matched the official `userAgentData` brands and Windows platform, but initially exposed `navigator.platform` as `Windows` instead of the official `Win32`. The corrected client-hints call keeps those values separate: the CDP top-level platform override is `Win32`, while `userAgentMetadata.platform` remains `Windows`. This corrected call is now used by the normal shell. The normal shell still exposes no `DiscordNative` object; visual and functional parity remain unverified.

## Verification status

| Check | Result |
|---|---|
| Release build | Passed; existing WindowsBase version-conflict warning remains |
| Static tool suite | Passed; 73 tools parsed and benchmark fixture passed |
| Source diff check | Passed |
| Live diagnostic launch | Passed through the controlled launcher; sanitized probe attached on port 9233 |
| Corrected environment result | `navigator.platform` = `Win32`; `userAgentData.platform` = `Windows`; brands = `Not/A)Brand`, `Chromium`; `DiscordNative` absent |
| Visual or functional parity | Not tested; client-hints verification was environment-only |
| Normal shell behavior | Client-hints metadata enabled; native capability bridges remain disabled |

No production desktop capability behavior is claimed. Client-hints promotion is limited to the verified environment-identification call.
