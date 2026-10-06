# Track B authenticated manual-checkpoint measurement: 2026-10-06

This run began after the user confirmed that Track B was ready for measurement. The measurement process did not control or inspect the native window. It sampled the existing Track B process tree for a full settled interval.

## Conditions

- Root PID: 32472
- Scenario: `authenticated-manual-ready`
- Duration: 621.2 seconds
- Samples: 20 at 30-second intervals
- Process count: 7 throughout
- Raw samples: `benchmarks/raw/track-b-authenticated-manual-ready-600s-20261006.json`
- UI state: user-confirmed ready; route, account, and exact feature state are not independently recorded by the measurement process

## Process-tree result

| Metric | Median | p95 |
| --- | ---: | ---: |
| Summed working set | 519.40 MiB | 519.66 MiB |
| Private working set | 163.94 MiB | 164.17 MiB |
| Private bytes / commit | 254.93 MiB | 255.20 MiB |
| Total CPU | 0.000% | 0.0032% |

## Private-bytes role attribution

| Role | Private bytes median |
| --- | ---: |
| Renderer | 120.48 MiB |
| GPU process | 58.47 MiB |
| Browser | 40.70 MiB |
| Network service | 13.09 MiB |
| Native shell | 11.62 MiB |
| Storage service | 7.69 MiB |
| Crashpad handler | 2.88 MiB |

## Interpretation

The run clears the 250 MiB private-working-set threshold and the 0.2% CPU threshold. It misses the strict 250 MiB private-bytes target by 4.93 MiB at the median and 5.20 MiB at p95. This is a resource result, not a full acceptance result: the authenticated same-route functional checklist and visual-parity review are still separate gates.

The largest private-byte owners were the renderer and GPU process. No renderer or GPU optimization was applied for this run.
