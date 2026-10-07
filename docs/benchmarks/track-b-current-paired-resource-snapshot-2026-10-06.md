# Track B current paired resource snapshot: 2026-10-06

This is a contemporaneous read-only process-tree comparison between the running official Discord PTB root and the running Track B root. It is a resource snapshot, not the authenticated same-route acceptance benchmark: the exact route, account state, and workload were not machine-verifiable.

## Conditions

- Official root PID: 41096
- Track B root PID: 4988
- Duration: approximately 60 seconds
- Samples: 6 for each root at 10-second intervals
- Official process tree: 6 processes
- Track B process tree: 7 processes
- Both root windows remained available during capture

## Results

| Metric | Official PTB | Track B | Change |
| --- | ---: | ---: | ---: |
| Summed working set median | 1,126.06 MiB | 530.61 MiB | 52.9% lower |
| Private working set median | 557.23 MiB | 166.90 MiB | 70.0% lower |
| Private bytes median | 886.50 MiB | 256.78 MiB | 71.0% lower |
| CPU median | 0.311% | below 0.2% target | lower |
| Handles median | 5,357 | 3,603 | 32.7% lower |
| Threads median | 241.5 | 175 | 27.5% lower |
| Process count | 6 | 7 | one additional Track B process |

## Acceptance status

The Track B numerical subgate passes for private working set and CPU. The comparison tool rejects the overall pair because the process count differs by more than the five-percent regression threshold. The exact authenticated same-route workload, UI responsiveness under identical interaction, feature behavior, and visual parity remain separate acceptance gates.
