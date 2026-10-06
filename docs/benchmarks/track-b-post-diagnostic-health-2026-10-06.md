# Track B post-diagnostic health check: 2026-10-06

This is a short stability check after the controlled official-client diagnostic. It measures the already-running verified Track B shell without controlling the Discord window or changing its authenticated state.

## Conditions

- Build: verified Track B shell
- Root PID: 36456
- Duration: 60 seconds
- Samples: 6 at 10-second intervals
- Process tree: 7 processes
- Window: existing shell left running and responsive
- Raw data: `benchmarks/raw/trackb-post-diagnostic-health-2026-10-06.json`

## Results

| Metric | Median | P95 |
| --- | ---: | ---: |
| Summed working set | 528.87 MiB | 528.94 MiB |
| Private working set | 162.93 MiB | 162.98 MiB |
| Private bytes / commit | 255.86 MiB | 255.89 MiB |
| CPU | 0.005% | 0.005% |
| Handles | 3,599 | 3,602 |
| Threads | 174 | 175 |

## Role breakdown

The renderer was 99.63 MiB private working set and 119.62 MiB private bytes. The browser process was 36.86 MiB and 53.91 MiB respectively. The GPU process was 14.95 MiB and 58.51 MiB. Network and storage services were 7.29 MiB and 2.89 MiB private working set.

## Interpretation

This confirms that the verified shell remained responsive and materially below the 250 MiB private-working-set target during the short post-diagnostic check. Private bytes remained about 5.86 MiB above the 250 MiB design target, so the target is still a near-miss for commit/private-bytes accounting. The result does not establish authenticated same-route parity, feature completeness, or visual parity.
