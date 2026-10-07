# Track B live settled 120-second baseline, 2026-10-07

This capture sampled the already-running Verified shell at root PID 39116 for
120 seconds. It did not restart or modify the shell. The window remained
visible, unminimized, and responsive at 1920x1080 and 60 Hz. The route and
account state were not independently authenticated by this capture.

Source: `artifacts/track-b-live-settled-120s-20261007/`.

| Metric | Median | P95 |
| --- | ---: | ---: |
| Total working set | 796.36 MiB | 807.80 MiB |
| Private working set | 381.34 MiB | 392.62 MiB |
| Shareable working set | 415.04 MiB | 419.69 MiB |
| Private bytes | 559.53 MiB | 600.21 MiB |
| CPU | 0.154% | 0.297% |
| Process count | 8 | 8 |

The renderer remained the dominant private-resident owner:

| Role | Private working-set median | P95 |
| --- | ---: | ---: |
| Renderer | 281.74 MiB | 288.31 MiB |
| GPU process | 42.41 MiB | 46.09 MiB |
| Browser | 35.20 MiB | 36.34 MiB |
| Network service | 8.80 MiB | 9.35 MiB |

Compared with the earlier 60-second live capture, renderer and complete-tree
memory are effectively stable. The longer run raises the observed CPU median
from 0.081% to 0.154% and records a 0.297% p95, while remaining below the
0.2% settled-idle median target. This is evidence to repeat CPU measurements
over longer windows, not a reason to change the memory-focused priority.

No optimization or runtime flag was changed.
