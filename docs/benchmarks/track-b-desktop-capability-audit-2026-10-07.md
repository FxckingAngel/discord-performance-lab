# Track B desktop capability audit

Date: 2026-10-07

This audit covers the current isolated Track B shell. It is an implementation boundary, not a desktop-parity result. The normal shell keeps Discord's frontend in charge of rendering and exposes no partial `DiscordNative` object. The desktop-style user-agent string is an identity signal only.

Promotion decision: no page-world `DiscordNative` capability group is safe to promote yet. The only complete capability already underneath the normal shell is the shell-owned titlebar/window-state group. It is implemented by WinForms and does not require Discord's frontend to receive an Electron-shaped object. `DiscordNative.window`, `DiscordNative.hardware`, and every other page-world group remain diagnostic-only until Discord behavior is verified against a complete contract.

## Smallest safe capability group

The smallest coherent group that is already implemented end to end is shell-owned window behavior:

| Capability | Native implementation | Normal shell | Evidence | Decision |
| --- | --- | --- | --- | --- |
| Custom titlebar | WinForms borderless form with native minimize, maximize/restore, close, and drag handling | Enabled | `MainForm.cs` owns the titlebar and `track-b-titlebar-diagnostic-2026-10-06.md` records a responsive build | Keep enabled as shell behavior; this does not claim Discord frontend parity |
| Window state | WinForms `WindowState`, tray restore, and single-instance restore | Enabled | `Test-TrackBShellSmoke.ps1` covers responsive startup, minimize, duplicate launch, restore, and normal close | Keep enabled as shell behavior |
| `DiscordNative.window` | Loopback WebView2 message bridge with five actions | Diagnostic only | `Invoke-TrackBWindowBridgeStateTest.ps1` verifies minimize and restore in an isolated profile | Do not expose in normal mode until Discord's complete window contract is implemented |

This group does not require Electron spoofing or a page-world native object. It is therefore safe to retain in production, but it does not by itself make Discord's frontend recognize a full desktop environment.

## Current boundary for the requested capabilities

| Area | Current evidence | Exposed to normal Discord? | Status |
| --- | --- | --- | --- |
| Desktop identity | `MainForm.cs` sets the audited Discord Desktop user-agent string. WebView2 still reports its own runtime through user-agent data. | Identity only | Implemented as a signal; not desktop parity |
| Clipboard | `ClipboardHostObject` has seven methods, but the tested backend is `SyntheticClipboardBackend`. The isolated test reports no real system clipboard access. | No | Not ready; no real end-to-end backend |
| File open dialog | `FileDialogHostObject` validates `openFile`, `multiSelections`, and filters. The isolated test intentionally rejects invalid input and opens no dialog. | No | Not ready; no authenticated upload test |
| Downloads/show-in-folder | The diagnostic event observer records `DownloadStarting` without changing `Handled` or `Cancel`. The normal shell leaves WebView2's default flow untouched. | No Track B bridge | Not ready; no native download lifecycle or show-in-folder implementation |
| Notifications | The diagnostic observer records origin metadata only and leaves WebView2 behavior unchanged. | No Track B bridge | Not ready; no end-to-end Discord notification test |
| Permissions/media | The diagnostic observer records permission metadata only and does not grant or deny access. | WebView2 web capabilities only | Not ready for a Discord desktop bridge |
| Power monitor / system idle time | No Track B host object or native implementation exists in this isolated checkout. The official-client property name is retained as an observation only. | None | Not ready; no bridge is exposed |

## Why no bridge was promoted

The current page script creates a `DiscordNative` object only in explicit diagnostic modes. It can add isolated `window`, `hardware`, clipboard, or file-dialog groups, but these are partial slices of the property surface observed in the patched official client. Earlier evidence showed that a partial native object can leave Discord's application mount empty. Promoting any one of these groups would therefore risk changing frontend initialization without proving desktop behavior.

The current code has no real end-to-end implementation for clipboard, downloads, notifications, permissions, power monitoring, or file uploads. The file-dialog and clipboard tests are contract harnesses, not production functionality. No production capability is claimed from them.

## Next implementation gate

The next safe bridge candidate is not a new page-world object. It is a complete, origin-restricted native file/download workflow with:

1. a real file picker and returned paths;
2. Discord upload behavior verified manually in the Track B shell;
3. download destination and completion behavior verified without account or protocol changes;
4. show-in-folder behavior implemented and tested;
5. a documented rollback switch and complete-tree resource measurement.

Until that exists, keep file-manager, clipboard, and download groups unavailable to normal Discord. Do not infer support from the user-agent string or from the property names observed in the locally patched client.

## Validation boundary

- Focused source audit: `track-b/discord-shell/MainForm.cs`, `ClipboardHostObject.cs`, `FileDialogHostObject.cs`, and `Program.cs`.
- Shell smoke coverage: `tools/Test-TrackBShellSmoke.ps1`.
- Window bridge diagnostic: `tools/Invoke-TrackBWindowBridgeStateTest.ps1`.
- Hardware/display-count diagnostic: `tools/Invoke-TrackBHardwareBridgeTest.ps1`.
- Clipboard contract diagnostic: `tools/Invoke-TrackBClipboardBridgeTest.ps1`.
- File-dialog contract diagnostic: `tools/Invoke-TrackBFileDialogTest.ps1`.
- The active official Discord installation was not restarted, stopped, or modified.
