# Track B desktop compatibility layer

Date: 2026-10-06

Desktop compatibility is a hard Track B requirement. The same Discord account, route, call state, window size, display, and workload must render like official Discord Desktop rather than like Discord in a generic embedded browser.

Discord's frontend remains responsible for rendering Discord UI. The shell provides only the desktop environment and native capabilities that have been observed, implemented, and tested. This layer must not change authentication, authorization, entitlements, API responses, the network protocol, or security state.

## Design rule

Expose the smallest audited API surface:

`Discord frontend -> Track B desktop compatibility API -> native Windows implementation`

An API is not reported as available until its native implementation works in the relevant scenario. There is no blanket Electron-object spoofing and no general-purpose native bridge exposed to page JavaScript.

## Compatibility matrix

The official Electron environment must be observed locally with read-only diagnostics and compared with the WebView2 environment before implementation. Public documentation describes platform behavior, but it does not prove which current Discord frontend checks are active, so unknown cells remain unknown until measured.

| Discord desktop capability | Official Electron environment | Track B equivalent | Implemented? | Performance cost |
| --- | --- | --- | --- | --- |
| Runtime and platform identification | Electron 42.11.10 with Chromium and Electron runtime signals | Native WebView2 runtime plus an explicitly documented, minimal environment surface | No | Not measured |
| Preload-exposed globals | Must be enumerated from the stock client under a disposable diagnostic launch | No preload bridge in the prototype | No | Not measured |
| Window controls and state | Electron BrowserWindow and native window state | WinForms window state and native controls | Prototype only | Host-only, to measure |
| Custom titlebar and drag region | Electron frame/titlebar configuration | Native WinForms titlebar or documented custom frame | No | Not measured |
| Desktop notifications | Electron/OS notification integration | WebView2 permission and Windows notification integration, subject to supported behavior | No | Not measured |
| Media devices and permissions | Chromium media APIs with Electron permission handling | WebView2 media permissions and native device selection | No | Not measured |
| Native file dialogs and downloads | Electron dialog and session/download APIs | WebView2 download events plus native Windows dialogs | No | Not measured |
| Clipboard | Chromium plus Electron integration | WebView2 clipboard plus narrowly scoped host fallback if required | No | Not measured |
| Drag and drop | Browser events plus Electron window behavior | WebView2 events plus native shell handling where required | No | Not measured |
| Global keybinds and push-to-talk | Electron globalShortcut or Discord-supported desktop path | Native Windows registration with explicit cleanup and conflict handling | No | Not measured |
| Screen/window capture | Electron/Chromium capture path and desktop capture picker | WebView2 capture support plus native picker only after an end-to-end test | No | Not measured |
| Tray and startup | Electron Tray and startup integration | Native Windows tray and startup registration | No | Not measured |
| Rich Presence/game integration | Electron/Discord-supported desktop integration | Only a supported, separately tested native equivalent | No | Not measured |
| Session persistence | Electron profile and storage | Isolated WebView2 user-data folder with normal interactive login | Prototype only | Included in tree |

## Investigation order

1. Capture sanitized, non-secret environment facts from official Electron and Track B: user agent, platform, runtime version, viewport, display scale, media-device availability, notification permission state, clipboard and drag/drop behavior, window APIs, and exposed global names.
2. Compare the same route and state visually and functionally.
3. For each difference, identify the exact capability check or missing native behavior before adding a bridge.
4. Implement one narrow capability, measure its process, memory, CPU, startup, and wakeup cost, then run the relevant functional scenario.
5. Keep unsupported capabilities unavailable rather than claiming they work.

Raw environment dumps, heap snapshots, screenshots, message contents, account identifiers, tokens, and crash dumps remain local and private. Only sanitized capability names, aggregate measurements, and pass/fail outcomes belong in the repository.

## Acceptance

Track B does not pass desktop compatibility until the authenticated A/B comparison is visually and functionally close to official Discord Desktop for Friends, server/channel, DM, Settings, voice, video, screen sharing, and media-heavy scenarios. Every implemented bridge must preserve the main performance target of approximately 250 MiB total settled idle RAM and 0.2% total idle CPU across the complete process tree.
