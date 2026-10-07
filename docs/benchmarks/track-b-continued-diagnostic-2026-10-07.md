# Track B continued diagnostic capture

Date: 2026-10-07

This capture used the current normal Track B shell after a 30-second settle period and five 60-second repetitions. It was run in automated mode without a manual route checkpoint, so it is diagnostic evidence only. It must not be used as authenticated same-route acceptance evidence.

The capture did not restart or inspect official Discord. The Track B process inventory was synchronized for every repetition. The renderer PID stayed at `38268` and the process count stayed at eight.

| Repetition | Private working set median | Private working set p95 | Private bytes median | CPU median | CPU p95 |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1 | 396.45 MiB | 437.39 MiB | 591.21 MiB | 0.050% | 0.340% |
| 2 | 393.56 MiB | 396.63 MiB | 577.08 MiB | 0.040% | 0.250% |
| 3 | 395.37 MiB | 415.74 MiB | 577.38 MiB | 0.050% | 0.840% |
| 4 | 253.78 MiB | 391.44 MiB | 514.15 MiB | 0.080% | 0.510% |
| 5 | 269.58 MiB | 290.16 MiB | 522.32 MiB | 0.050% | 0.810% |

## Interpretation

Three repetitions occupied a high band around 394–396 MiB. Two occupied a lower band around 254–270 MiB. The renderer PID and process count did not change, so process replacement is not the explanation for this split.

The route and visible frontend state were not manually confirmed, so the capture cannot determine whether the split is caused by route state, frontend initialization, navigation timing, cache/profile state, or another workload difference. The low band is therefore not an optimization result.

The next controlled experiment must hold the route and visible state constant and record the lifecycle timestamp, renderer private working set, V8 heap, DOM/frame counts, and allocation-base groups together. No renderer behavior change is approved from this capture alone.

Raw process-tree and resident-classifier artifacts remain under the private `artifacts/` directory and are not part of the public repository evidence.
