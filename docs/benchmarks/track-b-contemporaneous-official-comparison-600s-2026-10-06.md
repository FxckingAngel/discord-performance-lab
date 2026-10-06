# Track B 10-minute contemporaneous official comparison: 2026-10-06

This read-only comparison sampled an already-running official Discord PTB root and the already-running Track B shell concurrently for a full settled window. The official window showed `Friends - Discord`. The Track B route and account state were not independently visible, so this remains comparative process evidence rather than final same-route acceptance evidence.

## Conditions

- Official root PID: 41096
- Track B root PID: 32472
- Duration: 615.3 seconds each
- Samples: 20 at 30-second intervals
- Official process tree: 6 processes throughout
- Track B process tree: 7 processes throughout
- Raw samples: `benchmarks/raw/official-contemporaneous-visible-friends-600s-20261006.json` and `benchmarks/raw/track-b-contemporaneous-current-shell-600s-20261006.json`

## Comparison

| Metric | Official PTB | Track B | Track B improvement |
| --- | ---: | ---: | ---: |
| Summed working-set median | 914.41 MiB | 519.30 MiB | 43.21% lower |
| Summed working-set p95 | 942.03 MiB | 519.34 MiB | 44.87% lower |
| Private working-set median | 452.71 MiB | 163.85 MiB | 63.81% lower |
| Private working-set p95 | 480.07 MiB | 163.96 MiB | 65.85% lower |
| Private bytes median | 940.56 MiB | 254.86 MiB | 72.90% lower |
| Private bytes p95 | 1,000.62 MiB | 254.93 MiB | 74.52% lower |
| CPU median and p95 | 0.30% / 0.30% | 0.001% / 0.001% | 99.66% lower |
| Process count | 6 | 7 | one higher |
| Threads median | 327 | 172 | 47.40% lower |

## Gate status

Track B clears the 250 MiB private-working-set and 0.2% CPU thresholds. Its 254.86 MiB private-bytes median remains 4.86 MiB above the strict 250 MiB private-bytes limit, so the automated resource gate reports `FAIL` for this current post-build session. Earlier natural-settling observations reached 241.61 MiB, but that lower state was not reproduced in this longer post-build comparison.

The comparison does not prove visual parity, route equivalence, or normal functionality. The manual functional checklist and visual review remain required.
