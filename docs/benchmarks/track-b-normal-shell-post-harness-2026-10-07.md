# Track B normal shell post-harness measurement: 2026-10-07

Status: diagnostic evidence only. This was a read-only measurement of the already running normal Track B shell. The exact Discord route and visible workload were not manually confirmed, so it is not an authenticated same-route acceptance benchmark.

The official Discord installation was not touched.

## Capture

- Root: normal `KoroneDiscordShell` process
- Duration: 61.5 seconds
- Samples: 10 at five-second intervals
- Process count: 8 at the final sample
- Metrics: complete-tree working set, private working set, private bytes, CPU, per-process roles, handles, and threads

## Result

| Metric | Median | P95 |
| --- | ---: | ---: |
| Complete-tree private working set | 451.39 MiB | 611.27 MiB |
| Complete-tree working set | 860.26 MiB | 1009.20 MiB |
| Renderer private working set | 331.94 MiB | 492.73 MiB |
| GPU private working set | 44.41 MiB | 46.04 MiB |
| Total CPU | 0.08% | 1.11% |

The complete-tree private working set fell from 611.27 MiB at the first sample to 409.11 MiB at the last sample. This is consistent with the earlier observation that Track B's resident footprint changes materially during natural settling. It is not evidence that the memory was released from the renderer's committed state, and it is not a production optimization.

## Interpretation

This normal-shell run does not meet the approximately 250 MiB private-resident target. It also shows why the low-memory no-bridge diagnostic state cannot be used as the acceptance baseline: the normal shell's renderer reached a 331.94 MiB median private working set during this capture, with a 492.73 MiB p95.

The next measurement should use a fixed, manually confirmed route and a longer settle condition. Renderer attribution should be collected at the same checkpoints so resident transitions can be separated from retained commit and route-dependent state. No renderer behavior change is selected from this capture alone.
