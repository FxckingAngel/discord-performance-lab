# Track B live current attribution, 2026-10-07

This is a non-elevated 60-second process-tree capture of the already-running
Verified Track B shell (root PID 39116). It was taken after the canceled WPR
elevation attempt and did not restart or modify the shell. The current route
and account state were not independently authenticated by this capture, so it
is a live-current baseline rather than an authenticated parity result.

Source: `artifacts/track-b-live-current-attribution-20261007/`.

The capture used seven samples at 10-second intervals on a 1920x1080, 60 Hz
display. The window remained visible, unminimized, and responsive. The tree
contained eight processes for the full capture.

| Metric | Median | P95 |
| --- | ---: | ---: |
| Total working set | 802.81 MiB | 805.22 MiB |
| Private working set | 380.79 MiB | 382.74 MiB |
| Shareable working set | 421.98 MiB | 422.48 MiB |
| Private bytes | 550.65 MiB | 561.86 MiB |
| CPU | 0.081% | 0.108% |

Per-process private working set medians:

| Role | MiB | CPU median |
| --- | ---: | ---: |
| Renderer (PID 28160) | 280.32 | 0.063% |
| GPU process (PID 6372) | 41.18 | 0.000% |
| Browser | 35.89 | 0.000% |
| Native shell | 6.56 | 0.000% |
| Network service | 8.88 | 0.000% |
| Audio service | 3.11 | 0.000% |
| Storage service | 3.07 | 0.000% |
| Crashpad | 1.50 | 0.000% |

The renderer remains the dominant private-resident owner. Its 280.32 MiB
private working set is approximately 73.6% of the complete-tree private
working-set sum. CPU remains below the 0.2% median target; no CPU change is
justified by this sample. The capture does not identify which renderer-native
allocation category owns the renderer remainder, and it does not deduplicate
shared physical pages across processes.

WPR status was checked before and after the run and reported `WPR is not
recording`; no ETL was produced. The non-elevated sampler remains the
available read-only fallback until Windows elevation is granted.
