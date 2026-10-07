# Track B file-manager source audit

Date: 2026-10-07

Source: read-only inspection of the installed vanilla Discord PTB `mainScreenPreload.js` from `core.asar` for version `1.0.1223`. The official client was not modified, relaunched, or reconfigured. Raw source was kept in a temporary local directory and is not part of the repository.

## Source-backed surface

| Vanilla operation | Vanilla behavior | Track B status |
| --- | --- | --- |
| `showOpenDialog({filters, properties})` | Invokes `FILE_MANAGER_SHOW_OPEN_DIALOG`; resolves to `.filePaths` | Isolated Windows `OpenFileDialog`; open-file and multi-selection validation implemented |
| `showItemInFolder(path)` | Invokes `FILE_MANAGER_SHOW_ITEM_IN_FOLDER`; promise result is returned | Isolated Explorer selection implemented with path validation |
| `saveWithDialog(fileContents, fileName, defaultDirectory)` | Calls `saveWithDialog2(..., true)` and returns the selected directory or `null` | Implemented in the isolated probe over a real Windows `SaveFileDialog` |
| `saveWithDialog2(fileContents, fileName, defaultDirectory, throwOnCancel = false)` | Validates the file name, chooses Downloads when no directory is supplied, derives an extension filter, invokes the save dialog, writes the selected file, and returns cancellation/path metadata | Implemented in the isolated probe with filename validation and cancellation behavior |
| `getModuleDataPathSync()` | Synchronous `FILE_MANAGER_GET_MODULE_DATA_PATH_SYNC` | Not implemented |
| `getModulePath()` | Asynchronous module path lookup | Not implemented |
| `getLogPath()` / `getLogPathSync()` | Asynchronous and synchronous log-path lookup | Not implemented |
| `getAssetCachePath()` / `getAssetCachePathSync()` | Asynchronous and synchronous asset-cache lookup | Not implemented |
| `createDirectoryIfNotExists(path, hidden)` | Invokes `FILE_MANAGER_CREATE_DIRECTORY_IF_NOT_EXISTS` with path and hidden flag | Not implemented |
| `getMLDataDir*`, `getClipsDataDir*`, `getOpenH264Dir`, recording/log helpers | Build paths and manage model, clips, codec, voice-recording, and diagnostic files | Not implemented; requires separate path ownership and security tests |

The vanilla module also exports download and cleanup helpers. Those helpers perform network and filesystem work and are not safe to approximate from the current two-method dialog harness.

## Boundary

The current isolated harness exposes only `showOpenDialog` and `showItemInFolder` to a local probe. It does not expose `DiscordNative.fileManager` to the real Discord frontend. A complete file-manager activation requires exact argument/return marshaling, cancellation and error behavior, safe path ownership, sync/async semantics, and tests for every member that would be present on the exposed group.

This audit authorizes implementation work only. It does not authorize partial activation. The normal Track B shell continues to omit `DiscordNative`, and the atomic boot candidate remains rejected.
