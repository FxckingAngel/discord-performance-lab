# Track B desktop compatibility audit

Date: 2026-10-07  
Scope: read-only audit of the current Track B shell and the sanitized vanilla Discord preload reports. The official Discord client was not restarted, modified, injected into, or reconfigured.

## 1. Current Track B capability surface

### Production shell

The normal shell does not create or expose a `DiscordNative` global. This is intentional. The previous partial bridge exposed only small `window` and `hardware` surfaces and left Discord at an incomplete page with an empty `#app-mount`; the authenticated no-bridge path initialized normally.

| Surface | Current behavior | Production status |
| --- | --- | --- |
| Discord desktop identity | Sets the audited `discord/1.0.1223 Chrome/148.0.7778.280 Electron/42.11.10` user-agent identity. The normal shell also sets matching Windows/Chromium client-hints metadata through WebView2 CDP. | Enabled as an identity signal only |
| `DiscordNative` | No root object, preload object, Electron global, `require`, `process`, or `module` is exposed to Discord's page. | Intentionally absent |
| Native window shell | WinForms owns a custom titlebar, drag region, minimize, maximize/restore, close, tray icon, single-instance behavior, and a separate WebView2 profile. | Implemented by the shell, not exposed through Discord's preload contract |
| DPI initialization | Calls `SetProcessDpiAwarenessContext(PER_MONITOR_AWARE_V2)` before WinForms/WebView2 window creation, with a `SetProcessDpiAwareness(2)` fallback. The project also declares `PerMonitorV2`. | Implemented; parity still requires same-display measurement |
| WebView2 web capabilities | The sanitized environment probe observed notifications, media devices, camera/microphone access, display capture, clipboard, file pickers, downloads, drag/drop, and visual viewport support in the diagnostic environment. | Browser capabilities only; not proof of Discord desktop-contract parity |
| Permission/notification/download/capture events | WebView2 event handlers record sanitized diagnostic metadata only in capability-event modes. They do not approve permissions, implement Discord-native dialogs, or alter behavior. | Diagnostic-only |
| Window bridge | Five actions: `minimize`, `maximize`, `restore`, `close`, and `focus`. Calls are routed to the WinForms window. | Isolated `--diagnostic-window-bridge` and bridge-pair modes only |
| Hardware bridge | `DiscordNative.hardware.getDisplayCount`, backed by `Screen.AllScreens.Length`. | Isolated `--diagnostic-hardware-bridge` and bridge-pair modes only |
| CDP | Loopback CDP is enabled only by diagnostic launch modes for sanitized measurement and probes. | Diagnostic-only |

The isolated window bridge has behavior evidence for minimize/restore and the bridge-pair probe has shape evidence for the five window actions plus display count. No isolated bridge is enabled in the normal shell.

### Vanilla reference surface used for comparison

The sanitized vanilla extraction reports 33 top-level `DiscordNative` groups, including `app`, `clipboard`, `desktopCapture`, `features`, `fileManager`, `hardware`, `powerMonitor`, `safeStorage`, `settings`, `thumbar`, `tracing`, and `window`. Notification behavior was observed separately through WebView2's diagnostic event surface; it is not listed as a `DiscordNative` group in this sanitized preload inventory. The complete sanitized group/property inventory is local at `artifacts/discord-preload-contract-20261007.json` and `artifacts/discord-vanilla-environment-probe-complete-20261007.json`.

The most relevant exact groups for desktop behavior are:

- `app`: identity, release/build information, language direction, badge/relaunch and startup-related operations.
- `window`: 25 members including state transitions, focus, fullscreen, zoom, frame rate/background throttling, content protection, native handle, media-source ID, progress, and DevTools callbacks.
- `clipboard`: seven operations covering copy, paste, cut, image/file handling, and mixed-content checks.
- `fileManager`: dialogs, downloads/path helpers, open/save behavior, and Discord-specific file helpers.
- `desktopCapture`: desktop/window source enumeration.
- `hardware`: display count.
- `features`: capability declaration/query methods.
- `powerMonitor`, `safeStorage`, `settings`, `thumbar`, `spellCheck`, and `webAuthn`: additional behavior with different security or persistence requirements.

The extracted vanilla object also contains unrelated or high-risk groups such as generic IPC, native module loading, process controls, crash reporting, game integrations, WebAuthn helpers, and memory/profiling controls. Their presence is not a reason to reproduce them.

## 2. Smallest coherent boot-contract candidate

### Evidence-backed conclusion

There is currently no proven non-empty `DiscordNative` boot contract. The smallest production contract supported by the evidence is therefore **no exposed `DiscordNative` root**, with the audited desktop identity and genuine WebView2/native shell behavior left active.

The evidence does not establish a runtime call sequence. The vanilla preload's static construction order is source-order evidence only, and the existing probe could not wrap its non-configurable descriptors. The short authenticated capability-event observation recorded zero calls, which is useful only as a limited observation window and does not prove that the groups are unused.

Two negative results rule out the obvious smaller candidates:

1. `window` plus `hardware` exposed as a partial root produced the known incomplete-page/white-page state.
2. Adding small `app` and `features` values to that partial experiment did not restore initialization.

Therefore `app + window + hardware`, `window + hardware + features`, or any similar subset must not be described as a coherent boot contract.

### Isolated implementation boundary, not an activation decision

For implementation and harness work, the smallest **candidate to test**, without activating it in production, is the complete behavior of the desktop-relevant group set:

`app` + `window` + `hardware` + `features` + `clipboard` + `fileManager` + `desktopCapture` + `powerMonitor` + `settings`.

This is a test boundary, not a claim that Discord needs every group at startup. It is the smallest defensible boundary from the current reports that covers the observed desktop identity/window, display, capability-query, clipboard, file, capture, idle-state, and settings surfaces. It must be reduced only after a trustworthy pre-preload call trace or an equivalent vanilla behavior trace identifies groups that are not touched by the tested boot path.

Activation requirements for this candidate are atomic: every exposed member must have the exact vanilla method name, sync/async behavior, argument shape, return shape, event behavior, rejection/error behavior, and a real native owner. If any member remains a stub or an unimplemented capability, the candidate stays isolated and the production root remains absent.

## 3. Missing pieces and isolated-test requirements

### Missing implementation

- No exact runtime call order from pristine Discord has been captured.
- `app`, `clipboard`, `fileManager`, `desktopCapture`, `features`, `powerMonitor`, `settings`, and the remaining candidate groups have no complete Track B contract implementation.
- The window group lacks validated equivalents for fullscreen, always-on-top, progress, content protection, native handle/media source ID, background throttling/frame rate, PiP, zoom contract, and callback/event behavior.
- The hardware bridge has only a display-count behavior test; it is not evidence that Discord's frontend consumes it.
- Permission, notification, download, media-device, and screen-capture events are currently diagnostic logging hooks, not Discord-compatible native implementations.
- No production bridge exists for global shortcuts/push-to-talk, tray semantics expected by Discord, native file dialogs, show-in-folder/download ownership, or screen/window source selection.
- The current shell does not provide a validated Discord-specific settings store, safe storage contract, or desktop feature registry.

### Required isolated tests before any activation

1. Obtain startup behavior evidence from the pristine reference without changing its canonical baseline. Instrument only a separately labeled diagnostic session, or add an equivalent boundary before the preload object is constructed. Record group/method/event names and sanitized type/shape metadata, never values containing account data, tokens, IDs, message text, private URLs, clipboard data, or files.
2. Build a local compatibility harness that tests each candidate group against fixed method calls, including sync/async timing, arguments, return values, errors, cancellation, and events.
3. Test native behavior independently: window state, clipboard, file open/save, downloads, notifications, media permissions, display enumeration, capture-source selection, settings persistence, and power/shortcut behavior where applicable.
4. Enforce origin and security boundaries. Only the Discord HTTPS origin may request a Discord-specific bridge, and no bridge may alter authentication, authorization, entitlements, network protocol, or security state.
5. Expose the candidate groups together in a separate diagnostic build only after all members are implemented. Verify `applicationReady`, populated `#app-mount`, normal Friends/server/DM/settings rendering, voice/media entry points, and absence of the white-page regression.
6. Repeat the same diagnostics with the root absent. Compare startup correctness, visual state, private resident memory, CPU, process count, and media behavior. Do not accept a bridge that fixes identity while increasing resource use or changing visible behavior without evidence.
7. Keep a rollback switch that removes the whole root atomically. Do not expose one newly completed group to the production Discord page while the rest of the contract is incomplete.

## 4. Explicit unknowns

- Which `DiscordNative` methods Discord calls during startup, route navigation, messaging, voice, video, screen sharing, notifications, file operations, and settings.
- Whether the white-page failure is caused by root presence alone, a missing group, a missing member, a return-shape mismatch, an exception, or a startup ordering requirement.
- Whether the static preload order has any relationship to the frontend's first runtime calls.
- Which desktop-only visuals are selected by the user-agent/client hints, by `DiscordNative`, by Electron/WebView behavior, or by a combination.
- Whether WebView2's web-platform implementations match Discord's Electron behavior for media permissions, desktop capture source selection, notifications, downloads, clipboard formats, and device routing.
- The exact vanilla semantics and security requirements for native handles, media-source IDs, safe storage, WebAuthn, settings persistence, content protection, and global shortcuts.
- Whether a complete candidate contract would improve visual parity without adding enough native/runtime overhead to harm the Track B memory target.
- Whether the current same-display DPI/viewport chain is fully equal between the untouched vanilla reference and Track B; this requires sequential measurement on the main monitor and remains separate from the contract audit.

## Decision

Keep the normal shell on its current known-good path: audited desktop identity, real WebView2 web capabilities, native WinForms shell behavior, and no `DiscordNative` root. Continue capability implementation in isolated harnesses. Do not activate a partial root, and do not claim desktop parity until a complete candidate passes boot, feature, security, visual, media-quality, and resource checks.

## Evidence used

- `docs/benchmarks/track-b-preload-contract-2026-10-07.md`
- `docs/benchmarks/track-b-vanilla-preload-module-map-2026-10-07.md`
- `docs/benchmarks/track-b-vanilla-preload-static-order-2026-10-07.md`
- `docs/benchmarks/track-b-vanilla-capability-surface-2026-10-07.md`
- `docs/benchmarks/track-b-vanilla-capability-probe-2026-10-07.md`
- `docs/benchmarks/track-b-window-capability-audit-2026-10-07.md`
- `docs/benchmarks/track-b-authenticated-bridge-activation-fix-2026-10-07.md`
- `docs/benchmarks/track-b-app-features-bridge-rejected-2026-10-07.md`
- `docs/benchmarks/track-b-authenticated-capability-events-2026-10-06.md`
- `docs/benchmarks/track-b-bridge-pair-current-2026-10-06.md`
- `docs/benchmarks/track-b-hardware-bridge-2026-10-06.md`
- `track-b/discord-shell/MainForm.cs`
- `track-b/discord-shell/Program.cs`
- `track-b/discord-shell/KoroneDiscordShell.csproj`
- `artifacts/discord-preload-contract-20261007.json`
- `artifacts/discord-vanilla-environment-probe-complete-20261007.json`
- `artifacts/track-b-official-ua-environment-probe.json`
- `artifacts/track-b-desktop-hints-probe-corrected-20261007.json`
