# Track B audited bridge-pair smoke check

Date: 2026-10-06  
Build: current `Verified` shell  
Mode: isolated `--diagnostic-bridge-pair` profile  
CDP endpoint: loopback port 9229

The diagnostic profile was launched while the normal authenticated shell remained running. The probe recorded only the shape of the exposed native surface and the integer display count. It did not read page text, URLs, cookies, tokens, account data, or native object values.

## Result

| Check | Result |
|---|---|
| `DiscordNative.window` present | Pass |
| `window.minimize` | Pass |
| `window.maximize` | Pass |
| `window.restore` | Pass |
| `window.close` | Pass |
| `window.focus` | Pass |
| `DiscordNative.hardware.getDisplayCount` present | Pass |
| Returned display count | 2 |
| Diagnostic process exited through normal close | Pass |

Raw local result: `benchmarks/raw/track-b-bridge-pair-current-20261006.json`

An additional isolated `--diagnostic-window-bridge` run exercised the native behavior through CDP. The window was not iconic before the call, became iconic after `DiscordNative.window.minimize`, and was non-iconic again after `DiscordNative.window.restore`. The process remained responsive and exited through the normal close path afterward.

This verifies the narrow native bridge implementation and its local source boundary, including two behavior-level window actions. It does not prove that Discord's frontend uses these capabilities, that the UI selects desktop-only paths, or that voice, video, screen sharing, notifications, dialogs, clipboard, and other desktop features have parity. Those remain separate functional checkpoints.
