# Track B isolated fullscreen capability

Date: 2026-10-07

The diagnostic-only `DiscordNative.window` harness now includes a real native fullscreen transition. It is not exposed by normal Track B launches and was not tested against Discord's frontend.

## Verification

The test launched the Release shell with `--diagnostic-window-bridge` and exercised the actual WinForms window through the WebView bridge:

1. Confirmed the existing window methods were present.
2. Applied `fullscreen(false)` and received `false`.
3. Applied `fullscreen(true)` and received `true` after the native transition.
4. Applied `fullscreen(false)` and received `false`.
5. Restored the normal shell and verified that it was responsive.

Result: `PASS`.

The transition saves and restores the diagnostic window's bounds, border style, titlebar visibility, and prior window state. It does not change Discord authentication, authorization, protocol behavior, media behavior, or security settings.

## Boundary

This proves a native shell transition only. It does not prove that Discord's official `window.fullscreen` method has the same IPC signature, event behavior, or frontend semantics. The capability remains isolated and is not a desktop-parity acceptance result.
