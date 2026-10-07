# Track B current-state baseline with route unknown

Date: 2026-10-06

This is a short read-only observation after restoring the normal shell from diagnostic work. No manual route confirmation was supplied, so this is not an authenticated same-route acceptance benchmark.

## Capture

- Duration: 35.0 seconds elapsed
- Samples: 5 at a requested 5-second interval
- Root PID: the single running normal shell at capture start
- Process tree: 7 processes, 1 renderer in every sample
- Scenario label: `current-state-route-unknown`
- Raw data: `benchmarks/raw/track-b-current-state-route-unknown-20261006.json`

| Metric | Median | P95 |
| --- | ---: | ---: |
| Summed working set | 530.34 MiB | 530.58 MiB |
| Private working set | 173.55 MiB | 173.79 MiB |
| Private bytes / commit | 265.59 MiB | 265.83 MiB |
| Total CPU | 0.012% | 0.012% |

## Role ownership

| Role | Private bytes median |
| --- | ---: |
| Renderer | 128.71 MiB |
| GPU | 58.47 MiB |
| Browser | 42.19 MiB |
| Network service | 13.20 MiB |
| Native shell | 12.31 MiB |
| Storage service | 7.58 MiB |
| Crashpad | 3.12 MiB |

This run is about 10.4 MiB above the 250 MiB private-bytes design target, while CPU and private working set remain below their limits. The difference from the earlier 255.20 MiB separated-role run shows that the private-bytes gap varies with profile state and must not be treated as a fixed shell overhead. No optimization was selected from this run because the route and workload were not manually confirmed.
