# Track B post-restart baseline, 18 seconds

Date: 2026-10-06

This was a read-only capture of the running `KoroneDiscordShell` process tree after the Windows restart. The sampler produced four samples over 18.5 seconds. The window remained visible and responsive at 1920x1080 and 60 Hz. The Discord route, account state, and workload were not independently verified, so this is short-run drift evidence rather than authenticated acceptance evidence.

## Complete tree

| Metric | Median | P95 |
| --- | ---: | ---: |
| Processes | 8 | 8 |
| Working set | 810.33 MiB | 812.48 MiB |
| Private working set | 383.10 MiB | 385.21 MiB |
| Derived shareable working set | 427.22 MiB | 427.25 MiB |
| Private bytes | 607.27 MiB | 608.80 MiB |
| CPU | 0.017% | 0.368% |

Private working set remains the primary resident-memory KPI. The shareable value is reported for context and is not treated as unique physical memory.

## Role breakdown

| Role | Private working set | Private bytes | Working set |
| --- | ---: | ---: | ---: |
| Renderer | 280.66 MiB | 346.90 MiB | 384.71 MiB |
| GPU process | 42.89 MiB | 168.34 MiB | 108.95 MiB |
| WebView2 browser | 36.14 MiB | 47.21 MiB | 142.27 MiB |
| Network service | 9.15 MiB | 14.93 MiB | 50.86 MiB |
| Native shell | 6.91 MiB | 11.42 MiB | 54.08 MiB |
| Audio service | 3.07 MiB | 7.87 MiB | 28.53 MiB |
| Storage service | 2.96 MiB | 7.71 MiB | 24.47 MiB |
| Crashpad | 1.29 MiB | 2.87 MiB | 16.43 MiB |

## Interpretation

The renderer is the largest current private-resident owner. Holding the other roles at this snapshot's median, reaching the 250 MiB complete-tree private-working-set target would require the renderer to reach approximately 147.6 MiB. That is a measurement-derived subgoal, not permission to trim or page out memory.

The snapshot does not identify which renderer allocations are releasable. The next diagnostic boundary is to correlate renderer private resident memory with V8 live heap, Blink/DOM state, decoded media, compositor/GPU resources, code/JIT, and other native Chromium allocations. No renderer or runtime change is justified by this snapshot alone.

Raw capture: `artifacts/track-b-post-restart-check.json`.
Summary: `artifacts/track-b-post-restart-check-summary.json`.
