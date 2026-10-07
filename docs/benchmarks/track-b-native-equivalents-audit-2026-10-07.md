# Track B native-equivalent audit

Date: 2026-10-07

This is a source-level audit of the current Track B shell and the installed
Microsoft.Web.WebView2 1.0.4258.31 SDK documentation. It does not expose a
partial `DiscordNative` object, automate authentication, open the official
Discord client, or use account content. It is a capability boundary, not a
desktop-parity result.

## Finding

WebView2 already supplies browser-level equivalents for clipboard APIs, HTML
file selection, downloads, web notifications, microphone/camera permission
requests, and `getDisplayMedia()`. The normal shell can retain those flows
without a Discord-specific bridge. WinForms supplies the host-side primitives
for a real clipboard backend and `OpenFileDialog`, but those primitives are
not connected to the normal page.

Native host handling is required only when Track B intentionally replaces or
extends the browser flow: an Electron-shaped clipboard contract, a native file
manager/save dialog, a chosen download path or show-in-folder command, custom
Windows notification lifecycle, an explicit permission policy, or a custom
capture-source picker. None of those extensions is ready for the normal shell.

## Capability matrix

| Behavior | Standard WebView2/browser behavior already available | Native host work needed for an equivalent desktop behavior | Current shell decision |
| --- | --- | --- | --- |
| Clipboard | `navigator.clipboard` and browser clipboard permissions cover web text read/write under the browser's gesture and permission rules. The SDK documents `ClipboardRead` and related permission kinds. | WinForms `Clipboard` can implement text, image, and file-drop operations, but an Electron-style `copy`, `paste`, `copyFile`, `copyImage`, `read`, `cut`, and mixed-content contract would need a complete, origin-restricted API and behavior tests. | No normal-shell bridge. The existing clipboard object uses a synthetic backend only in `--diagnostic-clipboard`. |
| File picker/uploads | HTML file inputs and the Web File System Access picker APIs are browser-owned. WebView2 also documents file-system handles and picker permission requests. | A host replacement needs a real `OpenFileDialog`/save dialog, path validation, cancellation and multi-select semantics, upload handoff, and a complete contract. WinForms `OpenFileDialog` exists only in the isolated probe. | Leave browser file selection available; do not expose `DiscordNative.fileManager`. |
| Downloads/show-in-folder | WebView2 owns ordinary download UI and lifecycle. `DownloadStarting` is an observation/interception point; leaving it untouched preserves the default flow. | Setting a destination, tracking completion, opening Explorer, or matching Electron's show-item behavior needs host code, safe path handling, and a completion test. WinForms does not provide this as a WebView2 desktop bridge automatically. | No host override in normal mode. Diagnostic logging observes only `Handled` and `Cancel`. |
| Notifications | Web Notifications and WebView2's default notification UI are available. `NotificationReceived` can remain unhandled so WebView2 displays the notification. | A custom OS notification path needs a host notification object, click/close reporting, activation routing, and content/privacy policy. | Preserve the default WebView2 path. The diagnostic handler records origin metadata only. |
| Microphone/camera permission flow | `getUserMedia()` and WebView2's `PermissionRequested` cover the browser permission boundary. The SDK exposes `Microphone`, `Camera`, origin, user-initiated state, current state, and deferral. | Host code is needed only for an explicit consent/policy UI, persistence, device routing, or a decision different from WebView2's default. It must not auto-grant access. | Keep default WebView2 permission behavior. The diagnostic handler does not change state. |
| Display capture | `getDisplayMedia()` and `ScreenCaptureStarting` provide the supported browser capture path. Leaving the event unhandled leaves source selection and capture ownership with WebView2. | A custom source list, audio-selection policy, capture picker, or Electron desktop-capture contract needs host implementation and separate cleanup/error tests. | Keep the WebView2 path. The current event observer is diagnostic-only; no `DiscordNative.desktopCapture` object is added. |

## Evidence in this checkout

The normal `MainForm` registers no capability-event handlers and does not add
host objects. The handlers for `PermissionRequested`,
`NotificationReceived`, `DownloadStarting`, and `ScreenCaptureStarting` are
installed only by the explicit capability-events diagnostic modes. The
document-created bridge and `AddHostObjectToScript` calls are also gated by
diagnostic flags. The source comment records the observed failure mode: a
partial `DiscordNative` object can stop Discord during initialization.

The current diagnostic implementations are intentionally narrower than the
desktop behaviors they resemble:

- `ClipboardHostObject` is backed by `SyntheticClipboardBackend` in the
  clipboard probe; its Windows backend is not exposed to Discord.
- `FileDialogHostObject` uses WinForms `OpenFileDialog`, but only in the file
  dialog probe and without an authenticated upload workflow.
- The capability-event handlers record only sanitized metadata. They do not
  read notification text, download paths, capture source names, cookies,
  tokens, message content, or account data.

No capability in this matrix should be promoted through a partial page-world
object. A future native equivalent should first prove the browser behavior or
host behavior in isolation, then prove the same Discord behavior manually,
then measure the complete Track B process tree.

## One narrow behavior-level test to add

Add an isolated download test using a local static `NavigateToString` page in a
fresh diagnostic profile. The page should contain one user-activated link to a
small deterministic `Blob` payload. The test should:

1. assert that `window.DiscordNative` is absent;
2. click the link with a real page gesture;
3. observe `DownloadStarting` without setting `Handled` or `Cancel`;
4. verify that the default WebView2 download completes in a test-owned
   temporary directory; and
5. close the diagnostic shell and verify that no Track B process remains.

This tests one real browser-level behavior without authentication automation,
official Discord, account data, or a partial native object. It must not claim
`show-in-folder` support. A later, separate test can cover an explicitly
implemented Explorer action after its path and completion contract exists.

## Local primary references

- Shell source: `track-b/discord-shell/MainForm.cs` lines 213-315 and
  391-431; `ClipboardHostObject.cs`; `FileDialogHostObject.cs`.
- Installed SDK documentation:
  `%USERPROFILE%\.nuget\packages\microsoft.web.webview2\1.0.4258.31\lib\net462\Microsoft.Web.WebView2.Core.xml`
  lines 652-671 (microphone, camera, notification, and clipboard permission
  kinds), 1473-1475 (permission event), 2069-2071 (display capture),
  2091-2096 and 5451-5473 (notification event and default-handling contract),
  2210-2212 and 3789-3816 (download event and destination/cancel controls),
  and 3939-3999 (file-system picker permission behavior).
- Existing boundary report: `docs/track-b-desktop-compatibility.md`.

## Validation boundary

This report was written from local source and SDK XML only. No official
Discord process was started, stopped, or modified. No authenticated route was
visited. Build and repository checks are recorded in the commit message and
final task report.
