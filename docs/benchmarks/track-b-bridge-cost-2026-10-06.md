# Track B audited bridge cost

Date: 2026-10-06

## Scope

This compares two local blank-page diagnostics with the same WebView2 runtime and native shell. The first has no injected native bridge. The second uses the diagnostic bridge-pair mode containing the audited window and display-count groups. Neither run loads Discord or accesses account data.

## Result

| Metric | Blank without bridge | Blank with bridge pair | Difference |
| --- | ---: | ---: | ---: |
| Summed working set median | 363.12 MiB | 369.29 MiB | +6.17 MiB |
| Private working set median | 71.47 MiB | 73.38 MiB | +1.91 MiB |
| Private bytes / commit median | 143.19 MiB | 145.11 MiB | +1.92 MiB |
| CPU median | 0.017% | 0.027% | +0.010 percentage points |
| Handles median | 3476 | 3480 | +4 |
| Threads median | 179 | 184 | +5 |

The audited compatibility layer has a small measured cost relative to the WebView2 runtime floor. The result does not prove Discord uses either capability, and it does not justify exposing additional unsupported Electron APIs. Any future bridge must meet the same behavior, rollback, and resource-cost standard.

Raw samples remain under `benchmarks/raw/` and are not published.
