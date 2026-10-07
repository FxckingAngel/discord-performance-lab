# Track B current settled 10-minute benchmark

Date: 2026-10-06  
Build: current `Verified` production shell  
Root PID: 39764  
Scenario: existing authenticated shell, unchanged route and window state, settled foreground observation  
Duration: 621.239 seconds, 20 samples at 30-second intervals

Raw benchmark: `benchmarks/raw/track-b-current-settled-10min-20261006.json`  
Summary: `benchmarks/raw/track-b-current-settled-10min-summary-20261006.json`

## Complete process tree

| Metric | Median | p95 | Target | Result |
|---|---:|---:|---:|---|
| Total working set | 522.83 MiB | 523.49 MiB | secondary | informational |
| Private working set | 166.12 MiB | 166.65 MiB | approximately 250 MiB | pass |
| Private bytes / commit | 243.82 MiB | 244.45 MiB | approximately 250 MiB | pass |
| Total CPU | 0.002% | 0.002% | 0.2% | pass |
| Process count | 7 | 7 | no fixed limit | informational |
| Renderer count | 1 | 1 | no fixed limit | informational |

The process tree was stable at seven processes with one renderer. The final sample was 517.3 MiB summed working set and 243.7 MiB private bytes. The ordinary working-set sum remains higher because it includes resident pages shared across the WebView2 processes; private working set and private bytes are retained separately rather than treating the summed working set as unique application RAM.

## Role attribution

Private-byte medians:

| Role | Private bytes |
|---|---:|
| Renderer | 108.34 MiB |
| GPU process | 58.44 MiB |
| Browser/utility | 40.91 MiB |
| Network service | 13.21 MiB |
| Native shell | 12.44 MiB |
| Storage service | 7.72 MiB |
| Crashpad | 2.89 MiB |

The renderer remains the largest private-byte owner, followed by the GPU process. This benchmark does not identify a safe removable allocation inside either process, so no renderer or GPU change was made from this run.

## Acceptance status

This run is a resource result only. It does not close the Track B goal because the full acceptance contract also requires normal Discord functionality, visual parity, and controlled same-route comparison against official Discord. The current result does show that the existing shell can reach the approximately 250 MiB private-memory and 0.2% CPU design target after natural settling on this build.
