# Research: possible WebView2 shell architecture

## Status

Research only. This is not an implementation plan or a claim that a WebView2 shell can replace Discord's current desktop client.

## Why investigate it

Discord PTB currently embeds Electron 42.11.10. Electron inherits Chromium's multi-process model, including a browser process, renderer processes, utility services, GPU work, and audio services. A future lightweight shell could use a native Windows host plus the shared Evergreen WebView2 Runtime instead of shipping an independent Electron/Chromium runtime.

WebView2's shared runtime and Evergreen servicing could reduce duplicated browser binaries and may change the host's baseline footprint. That is a hypothesis only. Runtime sharing does not imply that a Discord page would use less memory, and WebView2 still creates browser, renderer, GPU, audio, and other helper processes.

## Likely preserved web functionality

If Discord's web application and authentication flow were compatible with the host, a WebView2 control could provide:

- HTML/CSS/JavaScript rendering and normal channel navigation;
- Web storage, cookies, permissions, and cached resources through a persistent user-data folder;
- microphone and camera permission requests through host-controlled WebView2 permission events;
- ordinary web media and WebRTC capabilities where the runtime and host expose the required permissions;
- notifications only when the host implements the WebView2 permission and notification integration.

These are platform capabilities, not proof that Discord would support or behave correctly inside a replacement shell.

## Desktop functionality that would need native replacement

A WebView2 shell would need to implement or preserve outside the web page:

- tray behavior, global shortcuts, deep links, and protocol registration;
- update, crash recovery, diagnostics, and clean uninstall;
- native window controls, multi-window behavior, overlays, and screen-sharing capture;
- audio-device selection, camera routing, permission persistence, and call lifecycle;
- OS notifications, badge counts, accessibility integration, and settings persistence;
- Discord's desktop-specific IPC, preload bridges, and any features tied to Electron APIs;
- secure storage and migration of the existing user profile without exposing credentials or tokens.

WebView2 permissions are host-mediated. Microsoft documents microphone, camera, and notifications as permission kinds, but also documents that push notifications are currently unavailable through WebView2's permission model. That is a material risk for a Discord shell.

## Runtime and data risks

WebView2 requires a runtime on the machine. Evergreen uses a shared, automatically updated runtime, while Fixed Version ships a private runtime. Either choice changes update and compatibility obligations. WebView2 stores cookies, permissions, cached resources, and other browser data in a user-data folder, so a replacement shell would need a deliberate migration and rollback plan. It must not copy or expose Discord tokens, private messages, encrypted transport state, or other account data.

The shell would also need to preserve Chromium sandboxing and least-privilege host bridges. Disabling the sandbox or adding broad native script access would violate the Phase 2 boundary.

## Research decision

Do not implement the shell yet. First build a feature matrix against the current Discord client and a disposable test account, then compare WebView2 and Electron using the Phase 2 scenario matrix. A viable result would need equal or better voice, video, screen sharing, notifications, accessibility, updates, profile persistence, and cleanup, with a measured reduction large enough to justify the new native host and migration risk.

## Sources

- [Electron process model](https://www.electronjs.org/docs/latest/tutorial/process-model)
- [WebView2 process model](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/process-model)
- [WebView2 platform components](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/platform-components)
- [WebView2 user-data folders](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/user-data-folder)
- [WebView2 distribution](https://learn.microsoft.com/microsoft-edge/webview2/concepts/distribution)
- [WebView2 permission kinds](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/winrt/microsoft_web_webview2_core/corewebview2permissionkind)
- [Electron process sandboxing](https://www.electronjs.org/docs/latest/tutorial/sandbox)
