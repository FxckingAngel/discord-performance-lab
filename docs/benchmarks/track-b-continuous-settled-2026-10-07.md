# Track B continuous settled diagnostic

Date: 2026-10-07

This was a 900-second, 181-sample read-only capture of the current Track B process tree after a stable six-sample settle window. The window stayed visible and responsive at 1920x1080 and 60 Hz. The renderer PID, GPU PID, browser PID, utility PIDs, window handle, and eight-process inventory remained stable.

The route and frontend state were not manually confirmed. This is diagnostic evidence only and is not an authenticated same-route acceptance result.

## Complete tree

| Metric | Median | P95 |
| --- | ---: | ---: |
| Total working set | 324.48 MiB | 403.28 MiB |
| Private working set | 235.37 MiB | 269.60 MiB |
| Shareable working set | 89.39 MiB | 133.62 MiB |
| Private bytes | 544.80 MiB | 587.89 MiB |
| CPU | 0.032% | 0.434% |
| Process count | 8 | 8 |

## Private working-set ownership

| Role | Median | P95 |
| --- | ---: | ---: |
| Renderer | 197.76 MiB | 211.23 MiB |
| GPU process | 21.98 MiB | 29.01 MiB |
| Browser | 9.59 MiB | 21.71 MiB |
| Network service | 4.18 MiB | 4.90 MiB |
| Native shell | 1.04 MiB | 3.34 MiB |
| Storage service | 0.81 MiB | 1.30 MiB |
| Audio service | 0.61 MiB | 1.39 MiB |
| Crashpad | 0.20 MiB | 0.61 MiB |

The renderer remains the dominant private-resident owner. CPU is below the 0.2% median target in this diagnostic run, but the p95 is reported separately as required.

## Interpretation

This run is numerically close to the 250 MiB private-working-set design target, but it cannot establish that Track B has met the target. The same process tree previously occupied a higher private-resident band, and the current run was not route-confirmed. The renderer recorded a page-fault p95 of 258 faults per second, with individual samples near 899 faults per second. That makes working-set residency and possible refault cost part of the result, not evidence of freed allocations.

Renderer private bytes remained much higher than renderer private working set. The run therefore does not prove that the renderer needs only about 198 MiB of committed private memory, nor that the memory reduction is safe for active Discord use.

No renderer behavior, feature, media behavior, authentication, network behavior, or official Discord installation was changed. The raw measurement, settle result, and per-process classifications remain private under `artifacts/track-b-continuous-settled-20261007/`.

The next acceptance-quality run requires manual confirmation of one exact authenticated static route and synchronized CDP data, if a diagnostic endpoint is deliberately enabled for Track B. It must also report responsiveness and page-fault behavior before any memory change is considered valid.
