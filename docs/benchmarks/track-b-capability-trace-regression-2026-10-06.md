# Track B capability-trace regression check: 2026-10-06

This run verifies that adding the diagnostic-only WebView2 capability event mode did not change normal-shell settled resource usage. The normal shell does not register the diagnostic event handlers.

## Conditions

- Build: verified Track B shell after capability-event trace change
- Root PID: 4988
- Scenario: normal shell, existing profile, settled idle
- Duration: 615 seconds
- Samples: 20 at 30-second intervals
- Process tree: 7 processes

## Results

| Metric | Median | P95 |
| --- | ---: | ---: |
| Summed working set | 535.59 MiB | 538.21 MiB |
| Private working set | 179.82 MiB | 180.42 MiB |
| Private bytes / commit | 257.47 MiB | 258.29 MiB |
| CPU | 0.003% | 0.003% |
| Handles | 3,619 | 3,645 |
| Threads | 177.5 | 190 |

The renderer accounted for 106.50 MiB private working set and 121.18 MiB private bytes. The GPU process accounted for 17.40 MiB private working set and 58.27 MiB private bytes.

## Interpretation

The diagnostic capability trace adds no normal-shell event handlers, and the settled baseline remains well below the 250 MiB private-working-set target and 0.2% CPU target. Private bytes remain about 7.47 MiB above the approximate 250 MiB design target in this run. This is a resource regression check only; it does not establish feature parity or a successful authenticated A/B comparison.
