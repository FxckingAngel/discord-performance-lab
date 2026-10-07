# Track B clipboard capability boundary

Date: 2026-10-07

This report records the smallest safe conclusion from the current local
clipboard evidence. It does not expose a new page-world bridge and does not
change the normal shell.

## Native host status

`track-b/discord-shell/ClipboardHostObject.cs` contains two isolated backends:

- `SyntheticClipboardBackend` is used by the existing contract probe and never
  reads or overwrites the user's clipboard.
- `WindowsClipboardBackend` uses the Windows clipboard through WinForms for
  text, bounded image data, file-drop data, text reads, and mixed-content
  detection. It requires an STA thread, validates file paths, and bounds image
  size before decoding.

The normal shell does not register `trackBClipboard`, does not create a
`DiscordNative` object, and does not expose either backend to Discord. The
three command operations (`cut`, `paste`, and empty-text `copy`) deliberately
remain unsupported because synthesizing those UI commands is a different
native contract from writing clipboard data.

## Local call-shape evidence

A read-only inspection of the locally installed renderer found the following
shape in a Vencord-patched Discord client:

| Operation | Observed local behavior | Track B conclusion |
| --- | --- | --- |
| `copy(text)` with text | Electron clipboard text write | A Windows text write is implemented in the isolated backend |
| `copy(text)` without text | Electron IPC invoke for a copy command | Do not map this to a clipboard write or synthetic keypress |
| `cut()` / `paste()` | Electron IPC invokes | The native command contract is not established |
| `copyFile(path)` on Windows | UTF-16 `FileNameW` clipboard data with a terminator | WinForms file-drop support is useful host behavior, but not proof of exact Electron parity |
| `copyImage(buffer, source)` | Electron native-image creation followed by a clipboard write | Image decoding and clipboard write are isolated only |
| `read()` | Electron clipboard text read | The isolated Windows backend has a bounded text read |
| `hasMixedContent()` | Clipboard format inspection | The isolated Windows backend checks text and image formats |

This renderer is Vencord-patched and is not a pristine Discord reference. The
observations are therefore implementation clues for the local installation,
not an official Discord frontend contract. No account data, clipboard content,
arguments, return values, tokens, or network behavior were collected or
published.

## Promotion decision

Do not expose `DiscordNative.clipboard` in the normal shell. The safe boundary
is:

`Discord frontend -> no promoted clipboard group -> WebView2/browser clipboard`

until a pristine or behavior-level Discord test establishes the expected
method contract. In particular, do not implement `cut` or `paste` by sending
synthetic keyboard input, and do not treat the locally observed IPC names as
authorization to add an Electron-shaped object.

The next valid clipboard promotion would require a complete, origin-restricted
contract with real tests for text, image, file, mixed-content, cut, paste,
error handling, and cleanup. It must also be measured as a normal Discord
workload and remain independently removable. Until then, the existing
diagnostic-only boundary is the result.

## Verification

- `pwsh -NoProfile -ExecutionPolicy Bypass -File
  .\tools\Test-TrackBClipboardHostObject.ps1` passed against the synthetic
  backend. The test confirmed no real system clipboard read or overwrite.
- `dotnet build .\track-b\discord-shell\KoroneDiscordShell.csproj -c Review
  --no-restore` passed with zero errors. The existing WindowsBase version
  conflict warning remains.
- The active official Discord installation was not stopped, restarted, or
  modified.

