# Track B manual checkpoint measurement: 2026-10-06

The user confirmed `READY` after leaving Track B in the requested authenticated state. This run observed the existing process tree without controlling the native window. The route and account state remain user-confirmed rather than independently inspected by the benchmark.

## Conditions

- Build: verified Track B shell
- Root PID: 36456
- Duration: 615 seconds
- Samples: 20 at 30-second intervals
- Process tree: 7 processes throughout
- Window: existing shell left running

## Results

| Metric | Median | P95 |
| --- | ---: | ---: |
| Summed working set | 528.96 MiB | 529.77 MiB |
| Private working set | 163.15 MiB | 163.97 MiB |
| Private bytes / commit | 255.80 MiB | 256.69 MiB |
| CPU | 0.002% | 0.002% |
| Handles | 3,599 | 3,599.1 |
| Threads | 173 | 175 |

## Largest roles

The renderer was 99.79 MiB private working set and 119.62 MiB private bytes. The browser process was 36.91 MiB and 53.84 MiB respectively. The GPU process was 14.96 MiB and 58.52 MiB. Network and storage services were 7.30 MiB and 2.89 MiB private working set.

## Acceptance status

The run passes the current settled private-working-set subgate and the 0.2% CPU target. Private bytes remain about 5.80 MiB above the 250 MiB design target, so the full target is not yet met under commit/private-bytes accounting. This is a resource checkpoint, not a claim of visual parity or complete normal Discord feature coverage. The official same-route paired comparison remains pending because the exact authenticated route could not be independently verified by the native-window connector.
