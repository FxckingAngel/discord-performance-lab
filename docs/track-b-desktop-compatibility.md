# Track B desktop compatibility layer

Date: 2026-10-06

Desktop compatibility is a hard Track B requirement. The same Discord account, route, call state, window size, display, and workload must render like official Discord Desktop rather than like Discord in a generic embedded browser.

This is an acceptance gate, not a naming or user-agent exercise. Track B must provide the desktop capability signals Discord's frontend actually relies on, and each reported capability must have a working native implementation underneath it. A UA string or an Electron-shaped object without working behavior does not satisfy this requirement.

Discord's frontend remains responsible for rendering Discord UI. The shell provides only the desktop environment and native capabilities that have been observed, implemented, and tested. This layer must not change authentication, authorization, entitlements, API responses, the network protocol, or security state.

## Design rule

Expose the smallest audited API surface:

`Discord frontend -> Track B desktop compatibility API -> native Windows implementation`

An API is not reported as available until its native implementation works in the relevant scenario. There is no blanket Electron-object spoofing and no general-purpose native bridge exposed to page JavaScript.

## Current promotion decision: 2026-10-07

No new DiscordNative group is promoted in this workstream. The normal shell's audited Discord Desktop identity is verified, but the page still receives no DiscordNative object. That is intentional: the earlier partial object stopped Discord after script loading and left an empty application root. The existing isolated window, hardware, clipboard, and file-dialog probes demonstrate message plumbing or host validation, not Discord feature compatibility, so they remain diagnostic-only.

| Capability boundary | Current evidence | Decision | Smallest next step |
| --- | --- | --- | --- |
| Desktop identity | `Test-TrackBDesktopIdentity.ps1` passes against the `--diagnostic-discord` environment report: Discord/Electron-shaped UA, `Win32`, no Electron globals, no DiscordNative groups | Keep in the normal shell | None; do not add globals from identity alone |
| Shell window/titlebar | WinForms titlebar, drag region, minimize, maximize/restore, close, tray restore, and single-instance behavior exist in the host | Keep shell-owned; do not expose `DiscordNative.window` yet | Observe a real official-client window capability use before designing the contract |
| Clipboard | Isolated synthetic round-trip only; no real system clipboard backend is exposed to Discord | Do not promote | Implement and test a real origin-scoped backend only after a supported Discord call contract is established |
| File dialogs/downloads | Input validation and WebView2 default download behavior are tested; no Discord file-manager contract is complete | Do not promote | Start with an authenticated upload/download behavior test, then implement only the called method |
| Notifications/media permissions | WebView2 standard APIs are present; host diagnostic handlers are metadata-only and do not change permission state | Do not promote a fake native group | Verify normal WebView2 notification and permission behavior in a real Discord workload |
| Screen/window capture | WebView2 `getDisplayMedia()` and `ScreenCaptureStarting` provide a real native host path without a fabricated source list | Next candidate | Run one authenticated end-to-end capture test, including picker, selected source, audio choice, cleanup, and failure handling |

Focused verification for this decision: `dotnet build track-b/discord-shell/KoroneDiscordShell.csproj --no-restore` passed with zero errors and the existing WindowsBase version-conflict warning. `Test-TrackBShellSmoke.ps1` failed because its helper-process cleanup assertion observed descendants after close; the reported PIDs were gone on immediate follow-up, so this is a harness/lifecycle failure rather than a capability pass. The child-build `--diagnostic-discord` probe also failed its normal-close assertion and was terminated as a Track B diagnostic process; no official Discord process was touched. No production bridge was changed.

The next implementation boundary is therefore a real WebView2-backed screen/window-capture path, not a DiscordNative shim. It can be promoted only after the authenticated behavior test passes and the shell's cleanup, permission, and resource-cost results are recorded.

## Compatibility matrix

The official Electron environment must be observed locally with read-only diagnostics and compared with the WebView2 environment before implementation. A separate vanilla control on 2026-10-07 confirmed the current `DiscordNative` group names; it did not establish which groups the tested route calls. Public documentation describes platform behavior, but it does not prove which current Discord frontend checks are active, so unknown cells remain unknown until measured.

| Discord desktop capability | Official Electron environment | Track B equivalent | Implemented? | Performance cost |
| --- | --- | --- | --- | --- |
| Runtime and platform identification | Electron 42.11.10 with Discord desktop UA and `DiscordNative` | Native WebView2 runtime plus the matching UA; WebView2 user-agent data remains distinct | UA only; no native surface | Measured in probe |
| Preload-exposed globals | `DiscordNative` groups observed in the vanilla control; Electron globals absent at page scope | No preload bridge in the prototype | No | Not measured |
| Window controls and state | Electron BrowserWindow and native window state | Diagnostic-only WebView2 message bridge to WinForms state/actions, source-restricted | Implemented diagnostically; not exposed in normal shell; Discord use unverified | No measurable cost in isolated bridge runs |
| Custom titlebar and drag region | Electron frame/titlebar configuration | Native WinForms titlebar, drag region, and window buttons | Implemented in shell; visual parity unverified | Included in shell process; measurement pending |
| Desktop notifications | Electron/OS notification integration | WebView2 permission and Windows notification integration, subject to supported behavior | No | Not measured |
| Media devices and permissions | Chromium media APIs with Electron permission handling | WebView2 media permissions and native device selection | No | Not measured |
| Native file dialogs and downloads | Electron dialog and session/download APIs | File-dialog input validation exists in an isolated probe; no normal-shell file manager or download bridge | No | Not measured |
| Clipboard | Chromium plus Electron integration | Synthetic clipboard contract exists only in an isolated probe; no real system backend is exposed to Discord | No | Not measured |
| Drag and drop | Browser events plus Electron window behavior | WebView2 events plus native shell handling where required | No | Not measured |
| Global keybinds and push-to-talk | Electron globalShortcut or Discord-supported desktop path | Native Windows registration with explicit cleanup and conflict handling | No | Not measured |
| Screen/window capture | Electron/Chromium capture path and desktop capture picker | WebView2 capture support plus native picker only after an end-to-end test | No | Not measured |
| Tray and startup | Electron Tray and startup integration | Native tray icon with show/restore and exit actions; startup registration not implemented | Shell behavior only; Discord use and startup behavior unverified | Not isolated |
| Rich Presence/game integration | Electron/Discord-supported desktop integration | Only a supported, separately tested native equivalent | No | Not measured |
| Session persistence | Electron profile and storage | Isolated WebView2 user-data folder with normal interactive login | Prototype only | Included in tree |

## WebView2 host-event boundary

The installed WebView2 SDK exposes `CoreWebView2.PermissionRequested` for privileged resources and `CoreWebView2.NotificationReceived` for non-persistent web notifications. The permission event includes the requesting origin, permission kind, user-gesture state, and a grant/deny state. The notification event includes the sender origin and allows the host to leave WebView2's default notification UI in place or take over the notification lifecycle.

Track B does not currently override either event. This preserves the existing WebView2 permission and notification behavior while voice/video and notification behavior are still being verified. The eventual native layer must restrict decisions to the Discord origin, preserve explicit user consent for microphone and camera, and measure any host notification path across the complete process tree. It must not auto-grant media access or replace notification behavior merely because the API exists.

Sources: [WebView2 PermissionRequested](https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2.permissionrequested), [WebView2 permission kinds](https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2permissionkind), and [WebView2 NotificationReceived](https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2.notificationreceived).

The shell now has a diagnostic-only `--diagnostic-capability-events` mode on loopback port 9231. It records only event type, origin, permission kind, user-gesture state, and the pre-existing permission state to a local JSONL file. It does not set `Handled` or change `State`, so the probe cannot grant, deny, or replace a capability. The normal shell does not register these diagnostic handlers.

The normal WebView2 message boundary parses `e.Source` as a URI and accepts only HTTPS `discord.com` or a subdomain of `discord.com`. This preserves the intended Discord-origin bridge path while rejecting non-HTTPS and lookalike hosts before any native action is dispatched. The change was rebuilt and followed by a full settled process-tree capture; see `docs/benchmarks/track-b-origin-guard-build-2026-10-06.md`.

The same diagnostic mode also observes WebView2 `DownloadStarting` and `ScreenCaptureStarting` events. It records only the event type and the pre-existing `Handled`/`Cancel` values; it never changes either value, reads a download path or source name, or takes a deferral. A rebuilt capability-events probe started, remained responsive, and closed normally after these handlers were added. No event was emitted during the blank probe because no download or display-capture operation was initiated. Microsoft documents that leaving these events unhandled preserves WebView2's default download and capture flows: [DownloadStarting](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/winrt/microsoft_web_webview2_core/corewebview2?view=webview2-winrt-1.0.3719.77) and [ScreenCaptureStarting](https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2.screencapturestarting?view=webview2-dotnet-1.0.3856.49). The normal shell still does not register these diagnostic handlers.

## Investigation order

1. Capture sanitized, non-secret environment facts from official Electron and Track B: user agent, platform, runtime version, viewport, display scale, media-device availability, notification permission state, clipboard and drag/drop behavior, window APIs, and exposed global names.
2. Compare the same route and state visually and functionally.
3. For each difference, identify the exact capability check or missing native behavior before adding a bridge.
4. Implement one narrow capability, measure its process, memory, CPU, startup, and wakeup cost, then run the relevant functional scenario.
5. Keep unsupported capabilities unavailable rather than claiming they work.

The read-only probe is `tools/Invoke-DiscordEnvironmentProbe.mjs`. It requires a loopback CDP endpoint created for a controlled diagnostic launch. It records only sanitized aggregate environment facts and global-name presence; it does not serialize native object values or page data.

The installed PTB package on the test machine is Vencord-patched. For a separate environment-only control, `tools/Launch-DiscordVanillaDiagnostic.ps1` launches the original package path with the locally supported `--vanilla` and `--multi-instance` switches, a separate user-data directory, and a loopback CDP port. It refuses to proceed when the executable is not already present and never stops or reuses the active Discord profile. This control is for desktop-capability inspection only; it is not a pristine performance baseline until the loaded package and version are independently verified. The observed capability surface is recorded in [the vanilla capability probe](benchmarks/track-b-vanilla-capability-probe-2026-10-07.md).

The complete 33-group, method-count inventory is recorded in [the vanilla capability surface](benchmarks/track-b-vanilla-capability-surface-2026-10-07.md). It is the current source for deciding which native groups can be implemented safely; it is not a list of APIs that Track B should blindly reproduce.

`tools/Extract-DiscordPreloadContract.mjs` provides a repeatable static check against a locally extracted `mainScreenPreload.js`. It emits only the `DiscordNative` group names and IPC event names, plus source size. It is intended to keep the implementation matrix tied to the actual desktop preload while keeping the installed package, arguments, and account state out of the repository.

For a controlled official-client capability-use trace, use `tools/Probe-DiscordNativeMethodCalls.mjs <port> <seconds> <output>`. It reloads the diagnostic page, wraps only callable properties under `DiscordNative`, and records unique method names plus counts. It never records arguments, return values, page content, URLs, cookies, tokens, or native object values. Run it only against a disposable controlled diagnostic session, not the ordinary live client.

The 2026-10-06 controlled trace found every observed `DiscordNative` group to be non-configurable and non-writable in the page world. The probe therefore recorded zero wrapped groups and zero calls. It did not bypass those descriptors, replace the native object, or inject an alternate implementation. This is a diagnostic limitation, not evidence that the groups are unused. Future capability-use evidence must come from behavior-level tests or a supported host-side diagnostic boundary.

## Measured Track B environment

The reusable wrapper `tools/Invoke-TrackBEnvironmentProbe.ps1` was run against the rebuilt `--diagnostic-discord` shell on 2026-10-07. It recorded the audited Discord Desktop user-agent string and `Win32` platform, a 1280x768 viewport at device-pixel ratio 1, and normal WebView2 capabilities for notifications, media devices, microphone/camera capture, display capture, clipboard, file pickers, downloads, drag/drop, and visual viewport APIs. `DiscordNative`, Electron globals, and the listed native capability groups were absent in this normal diagnostic mode. This confirms the shell's desktop-style identity signal but does not prove desktop parity; no partial native object is being exposed based on the UA alone.

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

The `DiscordNative` property names are capability labels only. Their values, IPC methods, account data, and native object contents were not read by the page probe. A read-only inspection of the separate vanilla package's `mainScreenPreload.js` now confirms that the official object is constructed in an Electron preload and routes named operations through renderer IPC. The exact boundary and rejected partial-bridge experiments are recorded in [decision 0024](decisions/track-b-0024-desktop-preload-boundary.md). The next implementation step is to determine which named groups the Discord frontend actually calls in each failed or visually different scenario, then provide one narrow native equivalent at a time.

## First native bridge probe

The diagnostic-only `--diagnostic-window-bridge` mode now exposes exactly five window actions through a document-created script: `minimize`, `maximize`, `restore`, `close`, and `focus`. The shell receives only messages with the `track-b-window` source, parses them as JSON, and dispatches the requested action to the WinForms window. In normal mode, messages are also restricted to documents whose source begins with `https://discord.com/`. It does not expose Electron globals, authentication state, API permissions, or a general IPC channel.

On 2026-10-06, the bridge was exercised over loopback CDP with `minimize` and `restore`. Both calls returned `called`; the root process remained responsive with its diagnostic window handle intact after the sequence. This verifies message delivery and native dispatch, not Discord feature compatibility. The bridge remains disabled in normal mode, and no window action has been marked as supported by the Discord frontend yet.

The diagnostic-only `--diagnostic-hardware-bridge` mode exposes `DiscordNative.hardware.getDisplayCount` as a promise-backed call. The native response is the current `Screen.AllScreens.Length` value, with no display names, coordinates, or user data returned to the page. Three local-blank runs measured 368.40 MiB median / 379.47 MiB p95 summed working set, 145.75 MiB median private bytes, and 0.020% median total CPU across seven processes. This was within the previously measured blank runtime floor, so no measurable aggregate cost is attributed to the bridge at this sample length. The window and hardware bridges remain diagnostic-only; they are not exposed in the normal shell, and Discord feature use remains unverified.

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

## WebView2 capture finding

Microsoft documents a `CoreWebView2.ScreenCaptureStarting` event for page calls to `navigator.mediaDevices.getDisplayMedia()`. The event can be canceled or deferred by the host; if Track B leaves it unhandled, WebView2 retains its own capture flow rather than receiving a fabricated Discord-native source list. This gives Track B a safe path to test screen/window sharing without changing Discord's protocol or exposing an unimplemented `DiscordNative.desktopCapture` object. The capability remains unmarked until an authenticated end-to-end screen-share test confirms the selected source, permission flow, audio behavior, and cleanup.

Source: https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2.screencapturestarting

## Launch-flag boundary

A read-only inspection of the live PTB process tree on 2026-10-06 showed Electron-specific renderer flags for device scale, media capture, H.264 handling, raster threads, and autoplay. It also showed `--no-sandbox` and `--enable-node-leakage-in-renderers`. These are observations about the official client, not Track B requirements. Track B does not copy the unsafe flags, disable WebView2 security protections, or enable renderer node leakage. Any media or display behavior needed for parity must be provided through a genuine, separately tested WebView2/native capability.

## UA-only experiment

A diagnostic-only WebView2 run reported the observed official Discord user-agent string, including `discord/1.0.1223` and `Electron/42.11.10`, while leaving the rest of the shell unchanged. The page still had no `DiscordNative` object, retained the WebView2 1264x761 DPR 1 viewport, and exposed the same normal web capabilities. UA identification alone therefore does not satisfy desktop compatibility and is rejected as a Track B implementation. It may only be used in future experiments when paired with genuine native capabilities and a documented reason.

Raw environment dumps, heap snapshots, screenshots, message contents, account identifiers, tokens, and crash dumps remain local and private. Only sanitized capability names, aggregate measurements, and pass/fail outcomes belong in the repository.

## PTB provenance boundary

The installed Discord PTB is not a pristine Electron reference on this machine. Its `resources/app.asar` is a 219-byte loader that requires the local Vencord patcher. A read-only inspection of the Vencord renderer found these `DiscordNative` call sites: `app.getVersion`, `app.relaunch`, `clipboard.copy`, `fileManager.openFiles`, `fileManager.saveWithDialog`, `nativeModules.requireModule`, and `processUtils.getLastCrash`.

Those names are evidence about the locally patched client, not proof of Discord's unmodified frontend contract. They must not be copied into Track B as a compatibility requirement, and the Vencord renderer, patcher, account state, and local paths must not be published. The existing Electron property-name probe is therefore retained as a patched-client observation and is not sufficient to close the desktop capability matrix.

Before the final desktop-parity decision, obtain a pristine Discord Electron reference or explicitly label every remaining Electron comparison as Vencord-contaminated. Track B continues to expose only audited native capabilities that it genuinely implements.

## Acceptance

Track B does not pass desktop compatibility until all of the following are true:

1. The authenticated A/B comparison is visually and functionally close to official Discord Desktop for Friends, server/channel, DM, Settings, voice, video, screen sharing, and media-heavy scenarios.
2. The frontend is using genuine desktop-capability paths where those paths differ from the web fallback. This must be shown by behavior-level tests, not only by matching strings or global names.
3. Every exposed bridge has a documented native implementation, source boundary, rollback path, and full-tree resource measurement. Unsupported capabilities remain unavailable.
4. Native compatibility does not move the complete process tree away from approximately 250 MiB total settled idle RAM and 0.2% total idle CPU, or introduce responsiveness, paging, notification, or media regressions.

The compatibility matrix is the source of truth for implementation status. The next comparison must capture the same sanitized signals from the official Electron client and Track B after each capability change, then repeat the relevant screenshot and functional scenario. Discord's server list, channel UI, message UI, call UI, and settings UI must continue to be rendered by Discord's frontend rather than manually recreated by the shell.
