# Track B screen-capture diagnostic

Date: 2026-10-07

This diagnostic exercised the existing WebView2 `getDisplayMedia()` path in a
separate `--diagnostic-capability-events` shell. The request was made without a
user gesture and recorded no source names, frames, page data, or account data.

## Result

The promise remained pending through the five-second diagnostic timeout. No
`screen-capture-starting` event was observed in the metadata-only log. The
isolated diagnostic process was then cleaned up without touching the ordinary
Track B shell.

This is not evidence that WebView2 screen capture is unsupported. It shows that
a non-user-gesture request is not enough to validate the host event path. A
manual, authenticated screen-share checkpoint is required to test picker
display, source selection, audio choice, cleanup, and failure behavior.

## Safety boundary

- The normal shell was not changed.
- No `DiscordNative.desktopCapture` object was exposed.
- No capture source, window title, display name, frame, token, or account data
  was recorded.
- The active official Discord installation was not touched.

Microsoft documents `CoreWebView2.ScreenCaptureStarting` as the host event for
page calls to `getDisplayMedia()`. The event can be canceled or deferred by the
host, so Track B leaves the default flow unchanged until the manual behavior is
verified:

https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2.screencapturestarting

## Follow-up limitation

A follow-up automated harness was not retained. Its second launch did not open
the diagnostic endpoint reliably, so it was discarded rather than added to the
benchmark suite. The existing capability-events mode remains the only supported
diagnostic entry point. A real user-gesture checkpoint is still required before
screen sharing can be marked supported.
