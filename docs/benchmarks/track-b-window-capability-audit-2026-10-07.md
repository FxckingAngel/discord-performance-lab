# Track B window capability audit

Date: 2026-10-07  
Reference: vanilla Discord PTB preload module 5639

## Audited vanilla surface

The vanilla `DiscordNative.window` module exports these members:

`flashFrame`, `minimize`, `restore`, `maximize`, `focus`, `setAlwaysOnTop`, `openDocumentPip`, `isAlwaysOnTop`, `showInactive`, `blur`, `setProgressBar`, `fullscreen`, `close`, `setMinimumSize`, `setZoomFactor`, `setBackgroundThrottling`, `setFrameRate`, `setDevtoolsCallbacks`, `supportsContentProtection`, `setContentProtection`, `setWindowContentProtection`, `getNativeHandle`, `getMediaSourceId`, and the platform constant `USE_OSX_NATIVE_TRAFFIC_LIGHTS`.

The module uses asynchronous IPC invocation for the window actions except for the local zoom, support-query, callback-registration, and platform-constant paths. The exact IPC event names and module ID are preserved in the sanitized extractor output; values and account data are not collected.

## Track B implementation boundary

A passing isolated capability test authorizes implementation work only. It does not authorize exposing that group to Discord. Activation remains an atomic contract decision and requires genuine behavior for every exposed member plus a fully initialized frontend.

| Capability | Current genuine Track B behavior | Activation status |
| --- | --- | --- |
| minimize, restore, maximize, focus, close | WinForms shell owns these operations | Shell-native; not exposed as partial `DiscordNative.window` |
| fullscreen | Shell can own a window-state transition, but Discord contract behavior is untested | Isolated testing only |
| minimum size | Diagnostic bridge validates dimensions and applies real WinForms `MinimumSize` | Isolated only; not exposed |
| zoom | WebView2 has a real zoom control, but Discord parity and media-quality effects are unverified | Not exposed |
| always-on-top | Diagnostic probe now uses real WinForms `TopMost` state and a readback query | Isolated only; not exposed |
| progress bar | Requires a native taskbar implementation and cancellation/error behavior | Not exposed |
| content protection | Windows has a native display-affinity mechanism, but Discord behavior is untested | Not exposed |
| native handle | Track B owns an HWND, but exposing its return shape and security boundary is untested | Not exposed |
| media source ID | No genuine Track B screen/window capture implementation yet | Not exposed |
| background throttling/frame rate | No validated equivalent preserving Discord behavior | Not exposed |
| document PiP | No validated native equivalent | Not exposed |
| DevTools callbacks | Diagnostic-only CDP exists, but it is not the vanilla callback contract | Not exposed |
| `USE_OSX_NATIVE_TRAFFIC_LIGHTS` | Windows shell has no macOS traffic-light implementation | Not exposed |

## Decision

The group cannot be exposed to Discord merely because the common window actions already work. The official module contains capabilities that affect media capture, window state, content protection, throttling, and desktop UI behavior. Track B keeps its existing shell-native titlebar and actions, while the `DiscordNative` root remains absent until a coherent group can be implemented and tested end to end.

This audit does not change authentication, authorization, network behavior, security state, or the official Discord client.

## Isolated action-sequence verification

The diagnostic-only build was launched with `--diagnostic-window-bridge` on 2026-10-07. The isolated test invoked this sequence through the shell's diagnostic CDP bridge:

`focus → maximize → restore → minimize → restore → focus`

All six calls returned `"called"`. The test intentionally excluded `close` so the diagnostic process could be cleaned up normally. The diagnostic process was then stopped and the normal Release shell was relaunched. No `DiscordNative` object was exposed to the production shell, and the official Discord reference was not touched.

This verifies delivery of the shell actions only. It does not establish the vanilla `DiscordNative.window` method signatures, IPC semantics, event behavior, or a complete desktop preload contract, so the window group remains isolated and not activated in Track B's real Discord frontend.

## Isolated always-on-top verification

The diagnostic-only window bridge now exposes `setAlwaysOnTop` and
`isAlwaysOnTop` only in `--diagnostic-window-bridge`. The test changed the real
WinForms `TopMost` property, read the changed boolean through the WebView
bridge, restored the original state, and verified the restored value. The
test passed on 2026-10-07. The production shell and Discord frontend remain
unchanged.

The same isolated run invoked `setMinimumSize` with validated viewport-sized
dimensions and completed without error. This verifies the native setter path,
not the vanilla preload signature or Discord's expected event semantics, so it
remains isolated and is not exposed to the production frontend.
