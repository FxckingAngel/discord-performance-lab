# Track B current live process-tree capture

This read-only capture sampled the already-running Track B shell rooted at PID 15152 for 64.4 seconds. It did not restart or modify the shell. The account route and workload were not independently verified, so this is current-state attribution evidence and not an authenticated acceptance result.

| Metric | Median | P95 |
| --- | ---: | ---: |
| Complete-tree private working set | 351.91 MiB | 352.57 MiB |
| Complete-tree private bytes | 527.50 MiB | 528.63 MiB |
| Renderer private working set | 268.39 MiB | 269.02 MiB |
| Renderer private bytes | 339.40 MiB | 340.49 MiB |

The tree contained eight processes. The renderer remained the dominant private-resident process. The raw per-sample process rows are retained locally in `artifacts/track-b-live-current-60s.json`; that artifact is not a public result and must remain private.

This capture does not identify which renderer allocation category owns the residual. The next renderer step remains safe, local CDP attribution of V8, DOM/layout, media, GPU, and native Chromium allocations in a separately launched diagnostic session, followed by a functional comparison before any runtime change.
