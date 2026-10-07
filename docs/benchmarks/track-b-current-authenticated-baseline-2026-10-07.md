# Track B current authenticated baseline

Date: 2026-10-07  
Mode: normal Track B shell, no `DiscordNative` object  
Artifact: `artifacts/track-b-current-baseline-20261007/process-tree.json`

This is a current diagnostic observation of the normal shell after it was already running with its authenticated WebView2 profile. The route was not independently revalidated through CDP during this capture, so this is not the canonical acceptance baseline. It is retained to anchor the next fully initialized lifecycle comparison.

## Capture

The root process was PID 26860. The observation lasted 120 seconds with 10-second samples. The process tree contained eight processes at the final sample.

| Metric | Result |
| --- | ---: |
| Complete-tree private working set, median | 400.43 MiB |
| Complete-tree private working set, p95 | 404.91 MiB |
| Complete-tree private working set, min/max | 399.08 / 405.08 MiB |
| Complete-tree working set, median | 798.56 MiB |
| Complete-tree working set, p95 | 802.94 MiB |
| Total CPU, median | 0.018% |
| Total CPU, p95 | 0.071% |

The tool's private-memory summary was private bytes, not private working set: it moved from approximately 565.3 MiB at the first sample to 536.3 MiB at the last sample. It is kept separate from the resident-memory KPI.

## Final process inventory

| Role | PID | Private working set | Working set |
| --- | ---: | ---: | ---: |
| Native shell | 26860 | 10.41 MiB | 60.29 MiB |
| WebView2 browser | 35772 | 39.35 MiB | 140.04 MiB |
| Crashpad | 11104 | 1.71 MiB | 11.84 MiB |
| GPU process | 45140 | 36.25 MiB | 97.91 MiB |
| Renderer | 11232 | 296.71 MiB | 400.57 MiB |
| Utility/audio | 12248 | 3.16 MiB | 23.34 MiB |
| Utility/network | 27876 | 9.73 MiB | 45.46 MiB |
| Utility/storage | 28800 | 3.07 MiB | 19.09 MiB |

The renderer remains the dominant private-resident owner. CPU is already below the settled-idle target in this observation, so no idle-CPU change is justified by this result.

## Interpretation and boundary

This capture does not prove that the route is the canonical static route, and it does not identify the renderer's native allocation owners. It must not be compared with the earlier lightweight initialization controls as an optimization win. The next valid baseline needs a manual route confirmation, a synchronized renderer/CDP PID, and at least three settled repetitions.

The normal shell remains on the known-good no-`DiscordNative` path. The diagnostic atomic boot candidate remains rejected because the frontend did not populate `#app-mount` and the requested native voice/utility modules are not implemented. The clean official Discord control was not changed.
