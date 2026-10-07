# Track B contemporaneous official comparison: 2026-10-06

This read-only comparison sampled an already-running official Discord PTB root and the already-running Track B shell at the same time. The official window showed `Friends - Discord`. The Track B route and account state were not independently visible, so this is comparative process evidence, not the final same-route acceptance result.

## Conditions

- Official root PID: 41096
- Track B root PID: 32472
- Duration: approximately 191 seconds each
- Samples: 6 at 30-second intervals
- Official process tree: 6 processes
- Track B process tree: 7 processes
- Raw samples: `benchmarks/raw/official-contemporaneous-visible-friends-180s-20261006.json` and `benchmarks/raw/track-b-contemporaneous-current-shell-180s-20261006.json`

## Comparison

| Metric | Official PTB | Track B | Track B improvement |
| --- | ---: | ---: | ---: |
| Summed working-set median | 912.20 MiB | 519.29 MiB | 43.07% lower |
| Summed working-set p95 | 919.47 MiB | 519.30 MiB | 43.52% lower |
| Private working-set median | 450.54 MiB | 163.95 MiB | 63.61% lower |
| Private working-set p95 | 457.75 MiB | 163.96 MiB | 64.18% lower |
| Private bytes median | 930.18 MiB | 254.88 MiB | 72.60% lower |
| Private bytes p95 | 938.12 MiB | 254.91 MiB | 72.83% lower |
| CPU median and p95 | 0.32% / 0.32% | 0% / 0% at sampler resolution | lower |
| Process count median | 6 | 7 | one higher |
| Threads median | 326.00 | 172.50 | 47.09% lower |

## Gate status

Track B clears the 250 MiB private-working-set and 0.2% CPU thresholds in this capture. Its 254.88 MiB private-bytes median remains 4.88 MiB above the strict 250 MiB private-bytes limit, so the automated resource gate reports `FAIL` for this run. Earlier natural-settling observations reached 241.61 MiB, but that lower state was not reproduced after the latest restart and is not attributed to the origin-boundary change.

The comparison does not prove visual parity, route equivalence, or normal functionality. The manual functional checklist and visual review remain required.
