# Track B clipboard contract

Date: 2026-10-07

Source: read-only extraction of the local official Discord PTB `mainScreenPreload.js` from `core.asar`. The official client and its files were not modified.

## Observed method behavior

| Method | Observed shape | Official behavior relevant to Track B | Track B status |
| --- | --- | --- | --- |
| `copy(text)` | one argument | Writes non-empty text directly; empty/null text invokes the desktop clipboard-copy IPC operation | Not implemented |
| `copyImage(imageArrayBuffer, imageSrc)` | two arguments | Decodes the buffer as a native image and writes both image data and an HTML `<img>` representation | Not implemented |
| `copyFile(filePath)` | one argument | On Windows writes a null-terminated UTF-16 `FileNameW` clipboard format | Not implemented |
| `cut()` | no arguments | Invokes the desktop clipboard-cut IPC operation | Not implemented |
| `paste()` | no arguments | Invokes the desktop clipboard-paste IPC operation | Not implemented |
| `read()` | no arguments | Returns native clipboard text synchronously | Not implemented |
| `hasMixedContent()` | no arguments | Returns true only when non-whitespace text and an image-like clipboard format are both present | Not implemented |

## Boundary

The browser `navigator.clipboard` API is not assumed equivalent to the Electron clipboard object. In particular, file clipboard formats, image-plus-HTML writes, and cut/paste command routing need separate Windows behavior tests. Track B will not expose a partial `DiscordNative.clipboard` object to the Discord frontend.

Synthetic isolated tests may use non-sensitive text, a generated image, and a temporary test file. They must record only return shapes and pass/fail results. They must not read or publish the user's existing clipboard contents.

## Decision

Clipboard remains an isolated implementation task. It is not part of the current atomic boot candidate because the startup trace does not require it and the full method group is not implemented. Normal Track B continues to use WebView2/browser clipboard behavior.
