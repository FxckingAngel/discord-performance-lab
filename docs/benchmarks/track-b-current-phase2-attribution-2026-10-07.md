# Track B current Phase 2 attribution

Date: 2026-10-07

This was a read-only 71-second, 13-sample capture of the existing shell rooted at PID 26036. The route and workload were not independently verified. WPR elevation was attempted separately but Windows canceled the UAC launch, so these results use the existing non-elevated Windows process and performance counters.

## Complete-tree results

- Display: 1920x1080 at 60 Hz
- Process count: 8 throughout
- Private working set: 403.65 MiB median, 408.64 MiB p95
- Private bytes: 571.53 MiB median, 621.87 MiB p95
- CPU: 0.084% median, 0.454% p95

## Role attribution

| Role | Private working set median | CPU median / p95 | Page faults median / p95 per second | Read / write bytes per second median |
| --- | ---: | ---: | ---: | ---: |
| Renderer | 300.14 MiB | 0.084% / 0.420% | 59 / 2,451 | 2,128 / 2,864 |
| Browser | 38.77 MiB | 0.000% / 0.017% | 0 / 251 | 0 / 0 |
| GPU | 37.49 MiB | 0.000% / 0.067% | 0 / 147 | 2,458 / 1,404 |
| Network service | 9.90 MiB | 0.000% / 0.034% | 0 / 44 | 350 / 700 |
| Native shell | 8.11 MiB | 0.000% / 0.000% | 0 / 0 | 0 / 0 |

The renderer owns approximately 74% of the complete-tree private working set and all of the material median CPU. Its p95 page-fault rate and I/O are also much higher than the other roles. This is evidence for continued renderer attribution, but it does not establish whether the faults are caused by media, resource caches, layout state, or ordinary Chromium paging behavior.

No priority changes, working-set trimming, forced garbage collection, browser flags, protocol changes, or security changes were made.

Raw capture: `artifacts/track-b-current-phase2-attribution-20261007/attribution.json`.
