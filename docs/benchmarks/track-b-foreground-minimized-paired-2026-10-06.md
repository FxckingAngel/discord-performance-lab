# Track B foreground versus minimized paired check

These two short captures used the same running Release shell and the same process-tree accounting. The minimized capture restored the window and verified responsiveness before the foreground capture.

| State | Working set | Private working set | Private bytes | CPU sample |
| --- | ---: | ---: | ---: | ---: |
| Foreground | 829.3 MiB | 406.9 MiB | 549.2 MiB | 0.302% |
| Minimized | 835.4 MiB | 412.6 MiB | 551.3 MiB | 0.050% |

The short-run memory difference is within measurement noise, while CPU falls substantially when minimized. This argues against visibility/compositor work being the main owner of the retained renderer memory. The current priority remains Discord-created renderer state and native writable allocations.

Foreground artifact: `artifacts/track-b-foreground-current-20261006/process-tree.json`.
Minimized artifact: `artifacts/track-b-minimized-current-20261006/process-tree.json`.
