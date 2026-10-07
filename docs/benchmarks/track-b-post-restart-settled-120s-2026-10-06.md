# Track B post-restart settled capture, 120-second request

Date: 2026-10-06

This was a read-only capture of the running `KoroneDiscordShell` process tree after the Windows restart. The sampler produced 13 samples over 136.8 seconds. The window remained visible and responsive at 1920x1080 and 60 Hz. The Discord route, account state, and workload were not independently verified, so this is diagnostic evidence rather than authenticated acceptance evidence.

## Complete tree

| Metric | Median | P95 |
| --- | ---: | ---: |
| Processes | 8 | 8 |
| Working set | 826.48 MiB | 842.03 MiB |
| Private working set | 399.17 MiB | 412.68 MiB |
| Derived shareable working set | 427.48 MiB | 430.01 MiB |
| Private bytes | 612.83 MiB | 658.44 MiB |
| CPU | 0.099% | 0.620% |

Private working set remains the primary resident-memory KPI. The shareable value is reported for context and is not treated as unique physical memory.

## Role breakdown

| Role | Private working set | Private bytes | Working set | CPU median |
| --- | ---: | ---: | ---: | ---: |
| Renderer | 296.52 MiB | 362.76 MiB | 400.66 MiB | 0.090% |
| GPU process | 43.28 MiB | 161.99 MiB | 109.34 MiB | 0.009% |
| WebView2 browser | 36.27 MiB | 47.31 MiB | 142.64 MiB | 0.000% |
| Native shell | 6.90 MiB | 11.43 MiB | 54.09 MiB | 0.000% |
| Network service | 9.29 MiB | 15.09 MiB | 51.01 MiB | 0.000% |
| Audio service | 3.07 MiB | 7.87 MiB | 28.53 MiB | 0.000% |
| Storage service | 2.97 MiB | 7.71 MiB | 24.48 MiB | 0.000% |
| Crashpad | 1.29 MiB | 2.87 MiB | 16.43 MiB | 0.000% |

## Fault and I/O signal

The renderer's page-fault rate was zero at the median but reached 1,466 faults per second at p95. Renderer I/O was zero at the median and 703 bytes per second at p95. The network service reached 346 page faults per second at p95. These are process-counter observations, not proof of paging or a cause; they should be correlated with an ETW/WPR trace before any memory policy change.

## Interpretation

The renderer is the largest current private-resident owner. The non-renderer roles total approximately 102.65 MiB private working set at this run's medians. Holding them constant, reaching the 250 MiB complete-tree target would require the renderer to reach approximately 147.35 MiB.

This run does not identify which renderer allocations are releasable. The next diagnostic boundary remains a synchronized renderer profile that separates V8 live heap, Blink/DOM, decoded media, compositor/GPU resources, code/JIT, and other native Chromium allocations. No renderer or runtime change is justified by this capture alone.

Raw capture: `artifacts/track-b-post-restart-settled-120s.json`.
Summary: `artifacts/track-b-post-restart-settled-120s-summary.json`.
