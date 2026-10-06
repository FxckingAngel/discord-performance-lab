# Track B current shell smoke test

Date: 2026-10-06  
Build: `track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe`

The existing normal shell was closed through its window-close path before the smoke test and was relaunched afterward. The authenticated profile was not edited by the smoke test.

## Results

| Scenario | Result | Evidence |
|---|---|---|
| Runtime-baseline diagnostic startup | Pass | PID 19068, responsive, expected title, six descendants observed |
| Capability-events diagnostic startup | Pass | PID 11732, responsive, expected title, five descendants observed |
| Diagnostic helper cleanup | Pass | Both diagnostic roots exited through normal close and left no matching helpers |
| Normal shell startup | Pass | PID 2572 became responsive |
| Duplicate normal launch | Pass | Second PID 22368 exited; exactly one verified root remained |
| Duplicate launch restore | Pass | Existing minimized window was restored |
| Normal shell after smoke test | Pass | Relaunched as PID 39988 and verified responsive |

This is local shell and lifecycle coverage. It does not establish Discord account-level functionality, desktop UI parity, or voice/video/screen-sharing behavior.
