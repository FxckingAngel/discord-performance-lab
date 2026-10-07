# Track B decision 0024: desktop preload boundary

Date: 2026-10-07

## Decision

Track B will not expose a partial `DiscordNative` object in the normal shell. The normal shell may identify itself with the observed Discord Desktop user agent, but desktop capability support is added only when a complete, narrow capability path has a real native owner and a workload test.

## Evidence

The local vanilla Discord PTB package was inspected read-only from its separate diagnostic launch. Its `discord_desktop_core/core.asar` contains `mainScreenPreload.js`. The preload:

1. constructs `DiscordNative` in the preload context;
2. exposes it through Electron `contextBridge.exposeInMainWorld`;
3. builds the object from 33 groups, including `app`, `clipboard`, `desktopCapture`, `fileManager`, `features`, `hardware`, `processUtils`, `safeStorage`, `tracing`, and `window`;
4. routes operations through named renderer IPC calls such as `DESKTOP_CAPTURER_GET_SOURCES`, `FILE_MANAGER_SHOW_OPEN_DIALOG`, `FILE_MANAGER_SHOW_SAVE_DIALOG`, `NOTIFICATION_SHOW`, `PROCESS_UTILS_GET_GPU_PROCESS_ID`, and `WINDOW_SET_TRAFFIC_LIGHT_APPEARANCE`.

This is a native preload contract, not a user-agent string. The sanitized group and method inventory is in [the vanilla capability surface](../benchmarks/track-b-vanilla-capability-surface-2026-10-07.md). The raw package, preload, and process command lines remain local.

## Rejected approach

The diagnostic window/hardware bridge experiment added a small object to the page. The page remained an incomplete state and the app did not establish normal Discord initialization. A later diagnostic app/features extension was also rejected. These experiments do not prove that the individual Windows operations are invalid. They prove that exposing an incomplete desktop contract is not a safe production strategy.

Track B will not add Electron globals, generic IPC, `process`, `require`, `nativeModules`, authentication data, or unsupported feature flags merely to make the frontend choose a desktop branch.

## Implementation order

The first production-capable groups must be selected by an observed workload and implemented end to end:

| Group | Smallest real owner | Required proof before exposure |
| --- | --- | --- |
| `window` | Existing WinForms window state and titlebar actions | Same-route visual comparison plus minimize, maximize, restore, focus, and close behavior |
| `clipboard` | WebView2/Windows clipboard APIs | Copy and paste functional test without reading unrelated clipboard data |
| `fileManager` | Windows open/save dialogs and download destination | Upload, download, and show-in-folder test |
| `desktopCapture` | WebView2 display-capture flow or a native source picker | Screen/window sharing test with source selection, audio, and cleanup |
| `hardware` | Windows display inventory | Display-dependent Discord behavior test |
| `app` | Read-only shell version/channel/build values | Every returned value comes from the Track B build and does not trigger relaunch or updater behavior |

The groups are independent only after the frontend call contract is known. Until then, the normal shell keeps the genuine WebView2 APIs available and leaves `DiscordNative` absent. Existing shell-owned titlebar, tray, permission, download, and capture event paths remain valid native behavior, but they are not reported as Discord-native compatibility until an end-to-end Discord workload uses them successfully.

## Current status

- Desktop identity: user-agent match only; insufficient for parity.
- Native bridge: diagnostic-only; no partial bridge is enabled in normal mode.
- Authenticated parity: manual checkpoint captured; same-route official pairing pending.
- Track B performance goal: active and unchanged.

The next code change must be tied to one observed Discord call path and one measurable workload. A bridge that only changes object names is not an accepted parity change.
