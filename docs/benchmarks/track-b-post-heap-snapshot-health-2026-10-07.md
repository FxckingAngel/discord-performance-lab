# Track B post-heap-snapshot health check

Date: 2026-10-07

This read-only capture checked the existing shell after the bounded WPR heap
snapshot and cleanup. It used root PID 39116 and recorded 16 samples over
approximately 51 seconds.

| Metric | Median | P95 |
| --- | ---: | ---: |
| Process count | 8 | 8 |
| Total working set | 694.10 MiB | 697.19 MiB |
| Private working set | 326.05 MiB | 328.10 MiB |
| Private bytes | 543.78 MiB | 545.78 MiB |
| CPU | 0.033% | 0.133% |

The WPR snapshot configuration was queried after capture and remained
disabled. The shell stayed available for measurement.

These numbers are a cleanup-health check, not a performance win: the route
and exact frontend state were not controlled against the earlier baseline, so
the lower memory result must not be used as an optimization claim.

The native shell PID remained 39116 and renderer PID 28160 remained alive and
responsive. A direct follow-up classifier measured 231.97 MiB
private-writable resident in the renderer, 328.38 MiB committed private
writable, 47.62 MiB image resident, and 4.37 MiB mapped resident. This is
useful evidence that the long-lived renderer can release a substantial amount
of resident memory, but it still does not identify which frontend state caused
the change.
