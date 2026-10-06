# Track B authenticated capability-call observation

Date: 2026-10-06  
Build: rebuilt `Verified` shell with diagnostic-only capability-call logging  
Mode: `--diagnostic-authenticated-capability-events`, shared authenticated profile, loopback CDP port 9232  
Observation: 12 seconds after diagnostic readiness, then normal close

The diagnostic mode used the existing authenticated WebView2 profile and the already audited window/display bridge. It logged only bridge group and action names. It did not log arguments, page text, URLs, cookies, tokens, account identifiers, or native values. The normal shell was relaunched afterward and verified responsive as PID 11268.

## Result

| Observation | Result |
|---|---|
| Diagnostic process startup | Pass |
| Diagnostic process normal close | Pass |
| Capability calls during startup/settling window | 0 |
| Normal shell after diagnostic | Pass |

The zero-call result applies only to this short startup/settling window. It does not establish that Discord never uses the bridges during settings, notifications, file operations, voice, video, screen sharing, or other user actions. Those scenarios still require controlled behavior-level testing.

This evidence does not justify adding more Electron-shaped globals or native APIs. The existing minimal bridge remains unchanged in normal mode.
