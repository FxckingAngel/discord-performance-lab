# Track B separated-role settled benchmark

Date: 2026-10-06

This run used the authenticated Track B shell already prepared by the user. It measured the complete rooted process tree without UI automation after the process sampler was updated to identify the native shell host separately from the WebView2 browser process.

Capture: 615.4 seconds, 20 samples, 30-second interval, seven processes, one renderer.

| Metric | Median | P95 | Target |
| --- | ---: | ---: | ---: |
| Summed working set | 524.50 MiB | 525.12 MiB | secondary |
| Private working set | 165.43 MiB | 166.08 MiB | 250 MiB |
| Private bytes / commit | 255.20 MiB | 255.87 MiB | approximately 250 MiB |
| Total CPU | 0.001% | 0.001% | 0.2% |
| Process count | 7 | 7 | diagnostic |
| Renderer count | 1 | 1 | attribution |

Role medians, private bytes / commit:

| Role | Private bytes |
| --- | ---: |
| Native shell | 11.38 MiB |
| WebView2 browser | 41.77 MiB |
| Renderer | 120.31 MiB |
| GPU | 58.20 MiB |
| Network service | 13.13 MiB |
| Storage service | 7.52 MiB |
| Crashpad | 2.89 MiB |

This is the best current authenticated settled result. The physical-resident and CPU subgates pass. The complete private-bytes target remains a near miss by 5.20 MiB, so Track B is not marked successful. The role split points to the renderer as the largest loaded allocation, while the native shell itself is only about 11.38 MiB private bytes.

The exact authenticated route remains user-confirmed rather than independently machine-verifiable. Visual parity and the full functional matrix remain separate acceptance gates.

Raw samples remain local and private at `benchmarks/raw/track-b-separated-role-settled-20261006.json`.
