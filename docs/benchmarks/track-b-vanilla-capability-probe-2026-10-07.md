# Track B vanilla desktop capability probe

This was a read-only environment probe of the locally installed Discord PTB package using its local `--vanilla` path, `--multi-instance`, a separate profile, and loopback CDP port 9236. The active Vencord Discord process was left running and untouched. The probe did not log in, read account content, or collect native return values.

The local original bundle showed that Discord exits secondary instances unless `--multi-instance` is supplied. With that flag, the isolated vanilla process reached a CDP page target and the sanitized environment probe completed.

## Observed environment

| Signal | Vanilla Discord control | Track B normal shell |
| --- | --- | --- |
| User agent | `discord/1.0.1223 Chrome/148.0.7778.280 Electron/42.11.10` | Same configured desktop identity |
| `userAgentData` brands | `Not/A)Brand`, `Chromium` | WebView2-reported brands from earlier probe |
| Platform | `Win32` | `Win32` |
| `DiscordNative` | Present | Absent |
| Electron globals at page scope | `electron`, `require`, `process`, and `module` absent | Same absent |
| Web capabilities | Notifications, media devices, user media, display capture, clipboard, file pickers, downloads, drag/drop | Same observed availability |

## Native surface shape

The vanilla control exposed these `DiscordNative` groups:

`accessibility`, `app`, `clipboard`, `clips`, `crashReporter`, `cs2Gsi`, `desktopCapture`, `dotaGsi`, `features`, `fileManager`, `gcEvents`, `gpuSettings`, `hardware`, `http`, `ipc`, `isRenderer`, `nativeModules`, `ntpClock`, `os`, `powerMonitor`, `powerSaveBlocker`, `process`, `processUtils`, `riotGames`, `safeStorage`, `setUncaughtExceptionHandler`, `settings`, `spellCheck`, `sysimg`, `thumbar`, `tracing`, `userDataCache`, `webAuthn`, and `window`.

The first narrow candidates with clear WebView2/Win32 equivalents are `window`, `hardware`, `clipboard`, file dialogs/download handling, notifications, and desktop capture. The probe does not establish which groups Discord calls on the tested route. It also does not justify exposing a broad object: every group still needs a behavior-level test, a real native implementation, and a rollback path.

The result changes the parity investigation from “does the user agent look like desktop?” to “which specific `DiscordNative` groups are required for the desktop route and which can Track B implement safely?”

Raw sanitized output is retained locally at `artifacts/discord-vanilla-environment-probe-2026-10-07.json`.
