# Track B titlebar and tray diagnostic

Date: 2026-10-06

This diagnostic used the newly built blank-page shell with the native titlebar and tray icon enabled. It ran for 60 seconds across the complete process tree. The authenticated Track B shell was not restarted.

| Metric | Median | P95 |
| --- | ---: | ---: |
| Summed working set | 373.54 MiB | 377.84 MiB |
| Private working set | 72.71 MiB | 72.79 MiB |
| Private bytes/commit | 145.80 MiB | 146.00 MiB |
| CPU | 0.013% | 0.013% |
| Processes | 7 | 7 |
| Handles | 3,508 | 3,526 |
| Threads | 177.5 | 180 |

The shell stayed responsive and closed through its normal window-close path. Compared with the earlier titlebar-only blank diagnostic, the private-memory and CPU readings remain effectively unchanged; the summed working-set variation is within short-run runtime noise. This is a shell-integration diagnostic, not authenticated Discord parity evidence.
