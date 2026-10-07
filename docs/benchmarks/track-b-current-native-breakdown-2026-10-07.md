# Track B current native resident-memory breakdown

Date: 2026-10-07

This is a read-only `VirtualQueryEx` plus `QueryWorkingSetEx` capture of the live Track B process tree rooted at PID 35936. The route and account state were not independently verified. The values are diagnostic and are not an acceptance benchmark.

The classifications are per-process. They are not cross-process physical-page deduplicated totals.

## Per-process classification

| PID | Role | Resident bytes | Private writable resident | Mapped resident | Image resident | Committed private |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 4388 | Storage service | 22.64 MiB | 1.11 MiB | 1.61 MiB | 19.89 MiB | 1.99 MiB |
| 5336 | Browser | 129.58 MiB | 23.00 MiB | 9.58 MiB | 96.87 MiB | 36.79 MiB |
| 15996 | GPU | 121.84 MiB | 53.75 MiB | 5.74 MiB | 62.20 MiB | 163.90 MiB |
| 21796 | Network service | 46.89 MiB | 5.18 MiB | 3.70 MiB | 37.95 MiB | 8.59 MiB |
| 35936 | Native shell | 52.18 MiB | 3.80 MiB | 11.78 MiB | 36.59 MiB | 7.50 MiB |
| 38344 | Renderer | 357.79 MiB | 260.13 MiB | 24.90 MiB | 72.13 MiB | 355.13 MiB |
| 38852 | Audio service | 26.58 MiB | 0.91 MiB | 1.67 MiB | 23.96 MiB | 1.86 MiB |
| 39296 | Crashpad | 15.78 MiB | 0.44 MiB | 0.91 MiB | 14.41 MiB | 1.02 MiB |

## Interpretation

The renderer remains the dominant resident allocation. Its private writable resident classification is approximately 260 MiB, while the process-tree performance counter measured approximately 302 MiB private working set at the end of the preceding 10-minute observation. The difference is expected from the different Windows APIs and classification rules, and is why both measurements are retained rather than substituted for one another.

The renderer's committed private writable memory is approximately 352 MiB, but committed bytes are not resident RAM. The GPU process has approximately 54 MiB of private writable resident memory and approximately 164 MiB of committed private memory. These results do not identify a safe removable feature yet, so no renderer or GPU optimization was applied.

Raw per-PID files are in `artifacts/track-b-current-native-breakdown-20261007/`.
