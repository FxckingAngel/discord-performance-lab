# Track B isolated file-dialog capability

Date: 2026-10-07  
Scope: diagnostic-only Track B work. The official Discord client was not touched. The normal Track B shell still exposes no `DiscordNative` object.

## Result

Track B now has an isolated `--diagnostic-file-dialog` mode on loopback CDP port `9240`. It exposes two isolated method paths matching the vanilla contract:

`DiscordNative.fileManager.showOpenDialog({ filters, properties })` and `showItemInFolder(path)`

The methods use a real Windows `OpenFileDialog` or Explorer and return native results. This is an isolated file-dialog capability, not the complete vanilla `fileManager` group and not a production bridge.

## Vanilla evidence

The installed PTB `core.asar` was read without changing the official client. The extracted preload defines:

```text
async function showOpenDialog({filters,properties}) {
  return (await DiscordIPC.renderer.invoke(FILE_MANAGER_SHOW_OPEN_DIALOG, {filters, properties})).filePaths
}
```

The corresponding Electron main handler delegates the options object directly to `dialog.showOpenDialog` and returns its result. The sanitized preload artifact reports `fileManager.showOpenDialog` as a function, but it intentionally does not retain private values.

This establishes:

| Contract item | Evidence |
| --- | --- |
| Method name | `showOpenDialog` |
| Input shape | one object with `filters` and `properties` |
| Timing | asynchronous preload method |
| Success shape | array taken from the native result's `filePaths` |
| Native owner | Electron open-file dialog |
| Cancellation | native result produces an empty `filePaths` array |

## Track B implementation boundary

The diagnostic mode uses `FileDialogHostObject` behind WebView2's asynchronous host-object proxy. The page-facing wrapper returns proxy promises and exposes only the two audited methods; it does not call the synchronous host-object proxy from page JavaScript.

Supported input semantics are deliberately narrow and explicit:

- `properties` may contain `openFile` and `multiSelections`;
- `filters` must be an array of objects with string `name` and non-empty string `extensions`;
- extension separators and wildcard patterns are normalized into the Windows dialog filter format;
- unsupported properties and malformed filters throw an error;
- selected paths are returned only to the local diagnostic page and are not written to benchmark artifacts.
- `showItemInFolder` accepts an existing file or directory and delegates to Windows Explorer with `/select`; invalid and missing paths fail before launching Explorer.

The harness does not expose `showSaveDialog`, path helpers, downloads, voice-message files, or model/clip storage. Those remain unimplemented and are not represented by placeholders. The diagnostic file-manager surface now also includes source-backed `saveWithDialog` and `saveWithDialog2`; the save path is not yet eligible for Discord activation until its runtime marshaling, cancellation, and file-write behavior are exercised end to end.

## Verification

| Check | Result |
| --- | --- |
| .NET build | passed, 0 errors; existing WindowsBase reference warning remains |
| Diagnostic process | started as `File Dialog Probe` with CDP on port 9240 |
| `DiscordNative.fileManager` | present in isolated mode |
| `showOpenDialog` type | function |
| `showItemInFolder` type | function |
| Unsupported `openDirectory` property | rejected with an error before opening a dialog |
| Empty `showItemInFolder` path | rejected before launching Explorer |
| Normal shell exposure | unchanged and absent |
| Official Discord | untouched |

The automated probe covered shape and rejection behavior. It did not select a file through the native dialog, because that requires a separate manual UI checkpoint. The next isolated test should exercise cancel and successful single/multi-selection manually, then compare the returned path-array behavior with the vanilla contract.

## Security and rollback

- The mode uses a separate `FileDialogProbeUserData` profile.
- It loads a local blank document, not Discord.
- It has no access to account data, tokens, Discord network traffic, or the official profile.
- The normal shell has no file-dialog bridge.
- Removing the diagnostic flag removes the capability entirely.
- Unsupported options fail closed instead of being approximated.

## Decision

The isolated `showOpenDialog` capability is suitable for continued harness testing because its argument and return contract are source-backed and its native owner is real. It is not authorization to expose a partial `DiscordNative.fileManager` object to Discord. Production activation still requires a coherent contract and separately verified semantics for every group Discord consumes.

## Evidence files

- `artifacts/discord-vanilla-environment-probe-complete-20261007.json`
- `docs/benchmarks/track-b-vanilla-preload-module-map-2026-10-07.md`
- `track-b/discord-shell/FileDialogHostObject.cs`
- `track-b/discord-shell/MainForm.cs`
- `track-b/discord-shell/Program.cs`
- `tools/Test-TrackBFileDialog.mjs`
