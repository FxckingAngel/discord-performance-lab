# Track B long unverified attribution

Date: 2026-10-07

This was a Track B-only diagnostic run using the authenticated no-bridge profile. No manual route or workload checkpoint was supplied, so it is not an acceptance benchmark. The official Discord/Vencord installation was not stopped, restarted, or modified.

## Capture

- settle: 120 seconds
- measurement: 600 seconds
- process samples: 121 at 5-second intervals
- complete-tree process count: 8 in the settled window
- display: 1920x1080 at 60 Hz
- raw process tree and CDP aggregate: local/private under `artifacts/track-b-current-long-20261007`

The last 60 samples, representing the final five minutes of the measurement, produced:

| Metric | Median | P95 |
| --- | ---: | ---: |
| Complete-tree private working set | 390.24 MiB | 400.96 MiB |
| Complete-tree total working set | 808.58 MiB | 820.18 MiB |
| Complete-tree private bytes | 593.25 MiB | 662.58 MiB |
| Complete-tree CPU | 0.065% | 0.507% |

The final five samples happened to be lower, at 275.83 MiB private working set, but that short tail is not treated as the baseline because the preceding settled window was materially higher. This is evidence that the current shell still has substantial state or resident-page variance after a long settle.

## CDP aggregate at the paired diagnostic point

- V8 used heap: 105.57 MiB
- V8 heap total: 108.35 MiB
- DOM nodes: 4,350
- documents/frames: 10/10 in the performance counters, 2 frames in the document aggregate
- JavaScript event listeners: 1,648
- images: 123 elements, about 1.67 million natural pixels
- video elements: 0
- canvas elements: 2

This still does not prove that V8 is the primary cause of the private-resident gap. The renderer-native and graphics portions require the same route/workload to be manually identified before an optimization is chosen.

## Harness correction

The capture itself completed, but the wrapper failed while post-processing because it initialized the process-tree variable only when resident-type capture was requested. The wrapper now loads and validates the process tree for every run, while keeping resident-page classification optional. The raw evidence was salvaged without rerunning the 12-minute capture.
