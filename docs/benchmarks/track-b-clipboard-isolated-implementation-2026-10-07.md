# Track B isolated clipboard implementation

Date: 2026-10-07

The seven-method clipboard contract is now implemented behind an injected backend:

`copy`, `copyImage`, `copyFile`, `cut`, `paste`, `read`, and `hasMixedContent`.

The contract is in `track-b/discord-shell/ClipboardHostObject.cs`. `WindowsClipboardBackend` now maps text, image-plus-HTML, file-drop/FileNameW, text reads, mixed-content detection, and foreground edit messages to Windows APIs. The backend boundary keeps Windows clipboard ownership separate from the contract surface. This turn only executed `SyntheticClipboardBackend`; it did not read, write, or overwrite the user's real clipboard, and it did not add the object to `DiscordNative`.

The isolated harness is `tools/Test-TrackBClipboardHostObject.ps1`. It uses synthetic text, an eight-byte image signature, a synthetic file path, and synthetic mixed content. The result was:

```json
{"syntheticOnly":true,"realSystemClipboardAccessed":false,"userClipboardRead":false,"userClipboardOverwritten":false,"methods":["copy","copyImage","copyFile","cut","paste","read","hasMixedContent"],"imageBytes":8,"copyCommandCount":2,"cutCommandCount":1,"pasteCommandCount":1}
```

This is an implementation test, not desktop parity. The real Windows backend's runtime clipboard-format behavior, permission boundary, and Discord end-to-end use remain unverified. The normal shell continues to expose no partial `DiscordNative` object. The clipboard group is not part of the atomic Discord activation candidate.

The Windows API choice follows Microsoft's Windows Forms clipboard guidance: clipboard access is STA-bound, `SetDataObject` is the multi-format path, and the format-specific methods cover text, images, and file drops. See [Microsoft's clipboard data guide](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/advanced/how-to-add-data-to-the-clipboard).

Validation completed:

- isolated synthetic clipboard harness under PowerShell 7;
- Release build of the shell;
- normal Track B relaunched and responding after the build;
- official Discord left untouched.
