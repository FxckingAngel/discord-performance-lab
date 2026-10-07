# Track B rooted WPR follow-up process baseline

Date: 2026-10-06

This 60-second process-tree capture overlaps the authenticated rooted WPR capture for root PID 28156. It uses the existing read-only process sampler and preserves the per-PID rows in `artifacts/track-b-rooted-followup-20261006/process-tree.json`.

## Settled baseline

- Samples: 10
- Processes: 8
- Private working set: 412.94 MiB median, 424.77 MiB p95
- Private bytes: 596.67 MiB median
- CPU: 0.0844% median, 2.7673% p95

The median idle CPU remains below the 0.2% target. The p95 is reported separately because a short burst occurred during the observation and must not be hidden by the median.

## Last-sample per-process private working set

- Renderer PID 39048: 303.04 MiB
- GPU PID 39764: 41.78 MiB
- Browser PID 8644: 39.18 MiB
- Network service PID 4928: 9.59 MiB
- Native shell PID 28156: 8.04 MiB
- Audio service PID 39600: 3.22 MiB
- Storage service PID 1080: 3.11 MiB
- Crashpad PID 35584: 1.75 MiB

The renderer still owns roughly three quarters of the private resident tree. This result does not justify a generic CPU or priority change. The next optimization evidence should explain the renderer's native/private resident pages before any renderer behavior is changed.
