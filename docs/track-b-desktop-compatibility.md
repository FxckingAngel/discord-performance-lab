# Track B desktop compatibility layer

Date: 2026-10-06

Desktop compatibility is a hard Track B requirement. The same Discord account, route, call state, window size, display, and workload must render like official Discord Desktop rather than like Discord in a generic embedded browser.

This is an acceptance gate, not a naming or user-agent exercise. Track B must provide the desktop capability signals Discord's frontend actually relies on, and each reported capability must have a working native implementation underneath it. A UA string or an Electron-shaped object without working behavior does not satisfy this requirement.

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
| Window controls and state | Electron BrowserWindow and native window state | WebView2 message bridge to WinForms state/actions, source-restricted in normal mode | Implemented in normal shell; Discord use unverified | No measurable cost in isolated bridge runs |
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

The read-only probe is `tools/Invoke-DiscordEnvironmentProbe.mjs`. It requires a loopback CDP endpoint created for a controlled diagnostic launch. It records only sanitized aggregate environment facts and global-name presence; it does not serialize native object values or page data.

## Measured Track B environment

The isolated `--diagnostic-discord` profile was measured on 2026-10-06 using WebView2 Runtime 154.0.4258.53. The Discord route reported Edge/WebView2 user-agent data, `Win32`, a 1264x761 viewport at device-pixel ratio 1, and normal web capabilities for notifications, media devices, microphone/camera capture, display capture, clipboard, file pickers, downloads, drag/drop, and visual viewport APIs. It did not expose `DiscordNative`, `electron`, `require`, `process`, or `module` globals.

This is evidence about the Track B web route, not proof that Discord Desktop accepts every capability as equivalent. No Electron object is being spoofed based on this result.

## Controlled Electron versus Track B probe

On 2026-10-06, official Discord PTB was restarted once with a localhost-only CDP port, probed, and then restored to its ordinary launch. The probe recorded no page content or account data. The same sanitized probe was run against the isolated Track B Discord route.

| Signal | Official Electron | Track B WebView2 | Consequence |
| --- | --- | --- | --- |
| User agent | Includes `discord/1.0.1223`, `Chrome/148.0.7778.280`, and `Electron/42.11.10` | Edge/WebView2 154 user agent | Environment detection can distinguish the clients |
| Platform | `Win32` | `Win32` | Same base platform signal |
| User-agent data | Chromium brands, Windows, desktop | Edge, WebView2, Chromium brands, Windows, desktop | Runtime brands differ |
| Viewport | 1284x722, DPR 1.5 | 1264x761, DPR 1 | Window/client-area parity is not established |
| Normal web capabilities | Notifications, media devices, user media, display capture, clipboard, file picker, downloads, drag/drop | Same observed availability | These do not explain the missing desktop bridge |
| `DiscordNative` | Present; property names include `desktopCapture`, `fileManager`, `window`, `clipboard`, `features`, `hardware`, `powerMonitor`, `safeStorage`, `settings`, `tracing`, and others | Absent | Primary compatibility-layer investigation target |
| Electron globals | `electron`, `require`, `process`, and `module` absent at page scope | Same absent | Do not add these globals blindly |

The `DiscordNative` property names are capability labels only. Their values, IPC methods, account data, and native object contents were not read. The next implementation step is to determine which named groups the Discord frontend actually calls in each failed or visually different scenario, then provide one narrow native equivalent at a time.

## First native bridge probe

The diagnostic-only `--diagnostic-window-bridge` mode now exposes exactly five window actions through a document-created script: `minimize`, `maximize`, `restore`, `close`, and `focus`. The shell receives only messages with the `track-b-window` source, parses them as JSON, and dispatches the requested action to the WinForms window. In normal mode, messages are also restricted to documents whose source begins with `https://discord.com/`. It does not expose Electron globals, authentication state, API permissions, or a general IPC channel.

On 2026-10-06, the bridge was exercised over loopback CDP with `minimize` and `restore`. Both calls returned `called`; the root process remained responsive with its diagnostic window handle intact after the sequence. This verifies message delivery and native dispatch, not Discord feature compatibility. The bridge remains disabled in normal mode, and no window action has been marked as supported by the Discord frontend yet.

The diagnostic-only `--diagnostic-hardware-bridge` mode exposes `DiscordNative.hardware.getDisplayCount` as a promise-backed call. The native response is the current `Screen.AllScreens.Length` value, with no display names, coordinates, or user data returned to the page. Three local-blank runs measured 368.40 MiB median / 379.47 MiB p95 summed working set, 145.75 MiB median private bytes, and 0.020% median total CPU across seven processes. This was within the previously measured blank runtime floor, so no measurable aggregate cost is attributed to the bridge at this sample length. The two tested capabilities are now enabled in the normal shell, with the same source restriction, but Discord feature use remains unverified.

## Measured Electron API shape

The property-name-only probe also recorded these nested names from the stock client:

| Group | Observed names relevant to a replacement shell | Track B status |
| --- | --- | --- |
| `window` | `minimize`, `maximize`, `restore`, `close`, `fullscreen`, `focus`, `blur`, `getMediaSourceId`, `getNativeHandle`, `setFrameRate`, `setAlwaysOnTop`, `setContentProtection` | Not implemented |
| `desktopCapture` | `getDesktopCaptureSources` | Not implemented |
| `fileManager` | `openFiles`, `showOpenDialog`, `saveWithDialog`, `showItemInFolder`, path/cache helpers | Not implemented |
| `clipboard` | `copy`, `paste`, `copyFile`, `copyImage`, `read`, `cut`, `hasMixedContent` | Not implemented |
| `features` | `declareSupported`, `supports` | Not implemented |
| `app` | version/build data, `relaunch`, `setBadgeCount`, language and startup-related getters | Not implemented |
| `powerMonitor` | `getSystemIdleTimeMs`, `on`, `removeAllListeners` | Not implemented |
| `settings` | `get`, `getSync`, `set` | Not implemented |
| `hardware` | `getDisplayCount` | Promise-backed bridge to the Windows display inventory, source-restricted in normal mode |
| `safeStorage` | encryption availability and string encrypt/decrypt | Not implemented |
| `tracing` | performance capture and save-to-downloads | Not implemented |

These names do not authorize exposing an object with matching methods. Each row requires a behavior-level test, a narrow native implementation, a rollback path, and a full-tree resource measurement before it can be reported to Discord as supported.

`tools/Probe-DiscordFeatureSupport.mjs` is the next sanitized diagnostic. It calls only the official client's local `features.supports` function with a fixed list of capability names and records boolean/error results. It does not invoke window actions, dialogs, clipboard operations, capture, settings, or account/network APIs. The resulting feature names are evidence for prioritization, not permission to expose unsupported methods in Track B.

The 2026-10-06 probe returned `false` for every human-readable candidate tested, including the observed `window`, `hardware`, `desktopCapture`, `fileManager`, `clipboard`, `powerMonitor`, and `safeStorage` method names. This is inconclusive because the feature registry likely uses internal identifiers. It must not be read as proof that the corresponding desktop capabilities are unused or unsupported, and no feature flag was changed.

## UA-only experiment

A diagnostic-only WebView2 run reported the observed official Discord user-agent string, including `discord/1.0.1223` and `Electron/42.11.10`, while leaving the rest of the shell unchanged. The page still had no `DiscordNative` object, retained the WebView2 1264x761 DPR 1 viewport, and exposed the same normal web capabilities. UA identification alone therefore does not satisfy desktop compatibility and is rejected as a Track B implementation. It may only be used in future experiments when paired with genuine native capabilities and a documented reason.

Raw environment dumps, heap snapshots, screenshots, message contents, account identifiers, tokens, and crash dumps remain local and private. Only sanitized capability names, aggregate measurements, and pass/fail outcomes belong in the repository.

## Acceptance

Track B does not pass desktop compatibility until all of the following are true:

1. The authenticated A/B comparison is visually and functionally close to official Discord Desktop for Friends, server/channel, DM, Settings, voice, video, screen sharing, and media-heavy scenarios.
2. The frontend is using genuine desktop-capability paths where those paths differ from the web fallback. This must be shown by behavior-level tests, not only by matching strings or global names.
3. Every exposed bridge has a documented native implementation, source boundary, rollback path, and full-tree resource measurement. Unsupported capabilities remain unavailable.
4. Native compatibility does not move the complete process tree away from approximately 250 MiB total settled idle RAM and 0.2% total idle CPU, or introduce responsiveness, paging, notification, or media regressions.

The compatibility matrix is the source of truth for implementation status. The next comparison must capture the same sanitized signals from the official Electron client and Track B after each capability change, then repeat the relevant screenshot and functional scenario. Discord's server list, channel UI, message UI, call UI, and settings UI must continue to be rendered by Discord's frontend rather than manually recreated by the shell.
