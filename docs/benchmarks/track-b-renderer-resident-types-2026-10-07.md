# Track B renderer resident-page decomposition

Date: 2026-10-07

This is an unverified-route diagnostic capture of the authenticated no-bridge Track B profile. It does not count as a functional or official-versus-Track-B acceptance benchmark. The official Discord/Vencord instance was not touched.

## Process-tree result

- settle: 60 seconds
- measurement: 120 seconds
- samples: 25 at 5-second intervals
- process count: 8
- display: 1920x1080 at 60 Hz
- complete-tree private working set: 399.64 MiB median, 407.43 MiB p95
- renderer private working set: 293.77 MiB median, 300.53 MiB p95

## Renderer page classes

The renderer PID was classified with `VirtualQueryEx` plus `QueryWorkingSetEx`. The result counts resident pages per process and does not deduplicate physical pages shared with another WebView2 process.

| Class | Resident MiB | Committed MiB |
| --- | ---: | ---: |
| Private writable | 289.16 | 332.95 |
| Private executable | 0.02 | 0.02 |
| Private other | 0.94 | 2.31 |
| Mapped | 20.71 | 394.04 |
| Image-backed | 75.83 | 369.75 |
| Shared-flag resident pages | 94.16 | not applicable |

The private-writable resident total is the closest current native measure for the renderer's private resident ownership. It is not a V8 total and must not be labeled JavaScript memory.

## Largest allocation-base groups

| Allocation base | Regions | Resident MiB | Committed MiB |
| --- | ---: | ---: | ---: |
| `0x29600000000` | 12 | 69.86 | 71.25 |
| `0x770800000000` | 6 | 46.14 | 47.75 |
| `0x273000000000` | 5 | 18.85 | 19.27 |
| `0x6CC000000000` | 1 | 12.12 | 12.75 |
| `0x7FFEC31C0000` | 1 | 9.21 | 10.75 |

The first four groups account for approximately 146.97 MiB resident. Their address families are not sufficient to identify Chromium PartitionAlloc, Blink, Skia, V8, or Discord state. No optimization is accepted from this table alone.

## Next attribution step

Repeat the same page classification at blank WebView2, Discord shell, static route, media-heavy route, and voice states while preserving the individual allocation-base families. A group becomes an optimization candidate only if it changes with a normal workload and can be reduced without changing visible Discord behavior. The raw per-PID classifications remain local under `artifacts/track-b-resident-types-20261007`.
