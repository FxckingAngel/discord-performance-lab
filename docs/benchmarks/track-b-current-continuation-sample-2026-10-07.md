# Track B current continuation sample

Date: 2026-10-07  
Build: `KoroneDiscordShell`  
Artifact: local `artifacts/track-b-current-continuation-sample-20261007-corrected.json`

This is a bounded read-only sample of the existing Track B process tree. The shell was not restarted. The route, account state, and frontend readiness were not independently confirmed, so this capture is diagnostic only and is excluded from acceptance baselines.

## Capture

| Metric | Result |
| --- | ---: |
| Samples | 7 |
| Duration | 36.5 seconds |
| Process count | 8 |
| Complete-tree private working set median | 286.33 MiB |
| Complete-tree private working set p95 | 295.80 MiB |
| Complete-tree working set median | 446.17 MiB |
| Complete-tree private bytes median | 615.69 MiB |
| Renderer private working set median | 214.05 MiB |
| CPU median | 0.032% |
| CPU p95 | 0.427% |
| Display | 1920x1080 at 60 Hz |

The renderer remained the largest private-resident owner in this sample. The result is lower than several earlier normal-shell captures, but without a manual route/readiness checkpoint it cannot establish that the shell was in the same fully initialized Discord state. The next canonical comparison must therefore record readiness, route class, renderer identity, and the same display conditions before treating this level as an optimization result.

The first attempt at this capture used the correct root PID but omitted the explicit Track B process-name label, which would have incorrectly identified the artifact as `DiscordPTB`. That artifact is not used. The corrected capture explicitly used `KoroneDiscordShell`.
