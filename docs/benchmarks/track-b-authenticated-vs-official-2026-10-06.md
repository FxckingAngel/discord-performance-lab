# Track B manual-checkpoint versus official Discord comparison

Date: 2026-10-06

## Scope

Track B was measured after the user-confirmed manual checkpoint. Official Discord was measured contemporaneously for the same 10-minute window without being closed or modified. The process-tree sampler used 30-second intervals and 20 samples for each application.

The user confirmed the Track B checkpoint, but the exact route and workload are not machine-readable evidence. Functional parity, visual parity, and media/call scenarios remain separate acceptance gates.

## Resource comparison

| Metric | Official Discord | Track B | Track B improvement |
| --- | ---: | ---: | ---: |
| Summed working set median | 1166.87 MiB | 499.59 MiB | 57.19% lower |
| Summed working set p95 | 1169.33 MiB | 499.79 MiB | 57.26% lower |
| Private working set median | 588.70 MiB | 146.23 MiB | 75.16% lower |
| Private working set p95 | 590.97 MiB | 146.28 MiB | 75.25% lower |
| Private bytes / commit median | 979.34 MiB | 234.43 MiB | 76.06% lower |
| Private bytes / commit p95 | 1019.17 MiB | 234.54 MiB | 76.99% lower |
| Shareable working set median | 578.18 MiB | 353.36 MiB | 38.88% lower |
| Total CPU median | 0.108% | 0.001% | 99.07% lower |
| Handles median | 6741 | 3552 | 47.31% lower |
| Threads median | 272.5 | 173 | 36.51% lower |
| Process count | 6 | 7 | 1 higher |

## Gate interpretation

The Track B numerical target sub-gate passes:

- private working set: 146.23 MiB, below the 250 MiB target;
- total CPU: 0.001%, below the 0.2% target;
- summed working set: 499.59 MiB, just below the 500 MiB minimum level.

The automated comparison remains marked provisional rather than accepted because process count differs and the exact same route/workload has not been independently captured. The extra Track B process must not be removed without checking normal notifications, media, voice, video, and screen-sharing behavior.

This result does not declare Track B complete. The remaining gates are authenticated functional checks, visual A/B parity, desktop capability behavior, and repeated workload-specific measurements.

Raw samples and generated summaries remain under `benchmarks/raw/` and are not published.
