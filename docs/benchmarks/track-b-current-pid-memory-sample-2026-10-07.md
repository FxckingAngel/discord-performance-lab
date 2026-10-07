# Track B current PID-level memory sample

Date: 2026-10-07

This is a 10-second read-only Windows process-tree sample from the live normal Track B shell. It does not expose a Chromium DevTools endpoint, so the CDP-to-renderer association remains unverified for this normal-shell state.

| Role | PID | Private working set median | Private bytes median |
| --- | ---: | ---: | ---: |
| Renderer | 28160 | 296.11 MiB | 465.62 MiB |
| GPU process | 6372 | 56.52 MiB | 156.29 MiB |
| Browser | 39032 | 19.45 MiB | 51.96 MiB |
| Network service | 39524 | 7.64 MiB | 18.76 MiB |
| Native shell | 39116 | 4.73 MiB | 13.28 MiB |
| Audio service | 32012 | 1.20 MiB | 7.86 MiB |
| Storage service | 39096 | 1.20 MiB | 7.84 MiB |
| Crashpad | 40452 | 0.30 MiB | 2.85 MiB |

Complete-tree results:

- private working set median: 387.13 MiB
- private working set p95: 421.35 MiB
- private bytes median: 724.46 MiB
- CPU median: 0%
- CPU p95: 0.615%
- process count: 8

The normal shell had no listener on the diagnostic CDP ports during this sample. The local `webview-process-info.json` file was older than the current renderer lifetime and was not used to claim a PID match. Raw process data remains in `artifacts/track-b-current-live-sample-20261007.json`.
