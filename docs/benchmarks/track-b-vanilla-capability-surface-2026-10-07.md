# Track B vanilla capability surface

The sanitized probe now enumerates every object/function group under the vanilla control's `DiscordNative` object and records property names plus types only. It does not read return values, arguments, account data, URLs, cookies, tokens, or page text.

The control exposed 33 groups:

| Group | Members observed | Initial Track B disposition |
| --- | ---: | --- |
| accessibility | 1 | investigate standard accessibility mapping |
| app | 16 | implement only values backed by the shell |
| clipboard | 7 | map to WebView2/Windows clipboard behavior |
| clips | 10 | out of scope until Clips is separately supported |
| crashReporter | 4 | do not expose until a real local path exists |
| cs2Gsi | 4 | do not expose; unrelated integration |
| desktopCapture | 1 | test WebView2 capture and source picker |
| dotaGsi | 4 | do not expose; unrelated integration |
| features | 2 | use only for capabilities actually implemented |
| fileManager | 40 | split dialogs/downloads from unrelated model/Clips helpers |
| gcEvents | 1 | do not expose as an optimization mechanism |
| gpuSettings | 3 | do not expose; hardware policy is not yet equivalent |
| hardware | 1 | existing real display-count diagnostic |
| http | 2 | do not expose; must not alter Discord networking |
| ipc | 3 | do not emulate generic IPC |
| nativeModules | 4 | do not expose arbitrary native loading |
| ntpClock | 5 | investigate only if a feature requires it |
| os | 4 | implement only read-only actual values if required |
| powerMonitor | 3 | investigate for push-to-talk/idle behavior |
| powerSaveBlocker | 3 | implement only with an explicit real native owner |
| process | 4 | do not expose arbitrary process state |
| processUtils | 28 | keep diagnostic-only; includes unsafe memory/process controls |
| riotGames | 1 | do not expose; unrelated integration |
| safeStorage | 3 | requires a real protected Windows storage implementation |
| setUncaughtExceptionHandler | 3 | do not expose until error ownership is defined |
| settings | 3 | map only to a real Track B settings store |
| spellCheck | 6 | use WebView2/browser behavior unless a gap is proven |
| sysimg | 5 | do not expose until image conversion is implemented |
| thumbar | 1 | investigate Windows taskbar equivalent |
| tracing | 2 | diagnostic-only and local/private |
| userDataCache | 3 | do not expose account/cache paths |
| webAuthn | 5 | preserve WebAuthn security; no compatibility stub |
| window | 25 | existing shell controls cover only a small subset |

The complete property names are retained in the local sanitized artifact at `artifacts/discord-vanilla-environment-probe-complete-20261007.json`. The probe found that the official object is much broader than the earlier fixed-group list. This rules out treating `window` and `hardware` as a sufficient desktop layer.

The next implementation gate is method-level: select one group, document the official behavior needed by a specific Discord workload, implement its native equivalent, and verify that workload before reporting the group. No group from this inventory is enabled in the normal Track B shell.
