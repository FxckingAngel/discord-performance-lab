# Track B isolated vanilla Discord reference

Date: 2026-10-07  
Build: Discord PTB 1.0.1223, Electron 42.11.10  
Executable: local PTB package launched with `--vanilla --multi-instance`  
Profile: separate `TrackB-DiscordVanillaDiagnostic` directory  
Active Vencord client: left running and untouched

## Environment comparison

The isolated control reached a CDP page target without reusing the active Discord profile. The probe recorded only sanitized environment facts.

| Signal | Isolated vanilla Discord |
|---|---|
| User agent | Discord Desktop 1.0.1223, Chrome 148, Electron 42.11.10 |
| `userAgentData` brands | `Not/A)Brand`, `Chromium` |
| Platform | `Win32` / Windows |
| Viewport | 1284x726, outer 1298x734, DPR 1.5 |
| `DiscordNative` | Present with the locally observed desktop capability groups |
| Electron globals at page scope | `electron`, `require`, `process`, and `module` absent |
| Web capabilities | Notifications, media devices, user media, display capture, clipboard, file picker, downloads, drag/drop |

This confirms that the remaining desktop-environment gap is not explained by page-scope Electron globals. The reference supplies a native preload contract and a different client-hints surface.

## Short process-tree control

The isolated control was measured for five samples over approximately 26 seconds while unauthenticated and not manually routed.

| Metric | Minimum | Average | Maximum |
|---|---:|---:|---:|
| Complete-tree private working set | 313.64 MiB | 344.53 MiB | 380.53 MiB |
| Complete-tree working set | 659.64 MiB | not used as primary KPI | 720.52 MiB |
| Process count | 6 | 6 | 6 |
| CPU | 0.00% | short diagnostic only | 1.30% |

This is an unauthenticated control and is not an official same-route performance baseline. It must not be used to calculate an Electron tax or a Track B percentage improvement.

## Consequence for Track B

The new Track B client-hints diagnostic should be compared against this isolated control using the same sanitized environment probe. It must remain diagnostic-only until it is shown to preserve Discord initialization, visual behavior, and normal feature behavior. Track B still must not expose a guessed or partial `DiscordNative` object.
