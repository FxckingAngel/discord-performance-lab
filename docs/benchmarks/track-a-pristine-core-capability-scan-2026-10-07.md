# Pristine official Electron capability scan

Date: 2026-10-07

This is a static, local inspection of the separately installed official stable Discord 1.0.9260 package. It does not execute or modify the package, read account state, or publish the bundle. The active DiscordPTB/Vencord installation was not used.

The scan inspected only the file and symbol structure of:

- `resources\app.asar`
- `modules\discord_desktop_core-2\discord_desktop_core\core.asar`

The extracted files and raw search output remain under the private benchmark directory. This document contains aggregate capability findings only.

## Findings

The desktop capability contract is implemented through the official core preload and its IPC-backed modules. It is not limited to a user-agent string or a page-global Electron object. The static contract includes the following capability families:

| Capability family | Observed official behavior | Track B status | Safe next step |
| --- | --- | --- | --- |
| Clipboard | Text copy/read, cut/paste through native clipboard IPC, image copy, and file-copy handling | Diagnostic-only host contract; no normal Discord bridge | Establish a real user-approved clipboard round trip in an authenticated Track B scenario before exposing any page-world group |
| Desktop capture | A desktop-source query that asks the Electron main process for screen/window sources and returns thumbnails/icons | WebView2 display capture is available, but no native Discord source-list equivalent | Test the WebView2 picker end to end; do not claim `desktopCapture` until selected-source behavior matches |
| Feature registry | A preload `supports`/`declareSupported` surface backed by a main-process feature registry | No Track B feature registry | Implement only after the specific Discord feature identifier is observed and the native behavior exists |
| Window operations | Minimize, maximize, restore, close, focus, fullscreen, frame-rate, always-on-top, and content-protection operations | Shell-owned lifecycle is implemented; page-world bridge remains diagnostic | Validate behavior-level use before exposing any window group |
| File management | Open/save dialogs, show-in-folder, and path/cache helpers | Input validation exists in an isolated probe; no full workflow | Test authenticated upload, download, and show-in-folder behavior using real native paths |
| Notifications | Native notification module is declared as a supported desktop feature | WebView2 default notification path remains unchanged | Verify actual Discord notification delivery before adding a native notification bridge |
| Hardware | Display count and related desktop display integration | Display count exists only in a diagnostic bridge | Add only the exact display operation required by a confirmed Discord flow |
| Power monitor | Suspend, resume, lock, unlock, and system-idle events | No Track B implementation | Defer until a real Discord behavior depends on it |
| Performance tracing | A desktop performance-trace capability exists in the official preload contract | Track B has independent local diagnostics, not a page-world tracing bridge | Keep tracing private and diagnostic; do not expose it to Discord yet |

## Interpretation

The official package confirms that desktop parity depends on a native preload/IPC contract. It does not prove that every listed capability is used in every route, and it does not authorize copying the surface into Track B. The earlier white-page result remains consistent with exposing an incomplete `DiscordNative` object: Discord can stop frontend initialization when the contract is partial.

Track B should therefore continue to use this rule:

`Discord frontend -> minimal audited compatibility API -> real native Windows implementation`

The next capability investigation should be behavior-led. For one authenticated scenario at a time, identify the feature path that Discord actually attempts to use, implement the smallest native equivalent, and measure the full process tree before and after. Unsupported groups stay absent.

## Provenance and limits

- Package: official stable Windows x64, version 1.0.9260
- Track B comparison build: 1.0.1223, so this is a contract-prioritization result rather than a same-build parity result
- Static inspection cannot prove runtime call frequency, feature-flag values, or visual equivalence
- No authentication, authorization, API permissions, network protocol, security setting, or account data was accessed
- No official Discord process was restarted, stopped, or modified
