# Track B WebView2 media path

Date: 2026-10-07

## Decision context

The Discord desktop preload requests Electron-native `discord_voice`, `discord_utils`, and `discord_zstd` modules during startup. Those modules own native voice processing, device control, screen sharing, and codec/runtime helpers. Track B will not load the official Node/Electron binaries into WebView2 or expose placeholder modules as production capability.

The alternative to evaluate is Discord's browser/WebRTC media path inside WebView2, with native Windows behavior supplied only at the WebView2 host boundary.

## Supported host surface

WebView2 exposes a permission-request event for privileged web capabilities, including microphone and camera access. Track B can observe and, after an explicit user-consent design, handle only requests from the Discord origin.

WebView2 also raises `ScreenCaptureStarting` when page JavaScript calls `navigator.mediaDevices.getDisplayMedia()`. The host can leave the normal picker flow in place, or use a deferral to make a measured decision. Setting `Cancel` rejects the request; Track B must not silently grant capture or replace the picker with an unverified source list.

Sources: [PermissionRequested](https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2.permissionrequested), [CoreWebView2 permission kinds](https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2permissionkind), and [ScreenCaptureStarting](https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2.screencapturestarting).

## Evaluation plan

1. Use the existing authenticated manual checkpoint with the normal shell, which intentionally exposes no `DiscordNative` object.
2. Record `navigator.mediaDevices.enumerateDevices()` as sanitized device-count/kind data only.
3. Run microphone permission, camera permission, voice connection, video call, and screen-share scenarios manually.
4. Leave WebView2's default capture picker and media pipeline intact for the first pass. The host should only record origin, permission kind, and event state.
5. Compare functional behavior, media quality, latency, GPU use, CPU, private working set, and process count with the untouched official reference.

This path is not yet accepted. It must demonstrate normal audio, video, device selection, screen sharing, and cleanup before it can replace any desktop-native capability. A successful browser media path would remove the need to reproduce Discord's Electron-native voice module while preserving the user's visible Discord behavior.

## Security and fidelity boundary

The experiment must not alter authentication, authorization, API permissions, account entitlements, network protocol, or capture consent. It must not disable visible media or lower quality to improve the memory target. Any native bridge remains origin-restricted and independently measurable.
