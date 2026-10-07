# Track B isolated clipboard bridge

Date: 2026-10-07

Track B now has a diagnostic-only `--diagnostic-clipboard` mode on loopback CDP port 9241. It composes the existing `WindowsClipboardBackend` with the audited `ClipboardHostObject` and exposes only the seven source-backed clipboard methods:

`copy`, `copyImage`, `copyFile`, `cut`, `paste`, `read`, and `hasMixedContent`.

The bridge is available only on a local blank probe page. The normal shell still exposes no `DiscordNative` object, and the official Discord reference was not changed.

## Verification

- C# build: passed, zero errors.
- Synthetic clipboard contract test: passed.
- Synthetic test did not access, read, or overwrite the user's system clipboard.
- Runtime WebView2 method-shape probe: not completed because the local execution policy rejected launching the diagnostic GUI process from the shell.

The diagnostic bridge intentionally does not invoke any clipboard operation during its CDP shape probe. This avoids collecting or changing user clipboard contents. The isolated group remains ineligible for Discord activation until a runtime probe and a behavior-level upload/paste test establish the exact WebView2 host-object behavior.
