# Track B live renderer decomposition

Date: 2026-10-07

Artifacts:

- `artifacts/track-b-live-renderer-types-20261007.json`
- `artifacts/track-b-live-virtual-types-20261007.json`

The renderer was sampled read-only at PID 26104 while the existing Track B shell remained running. Route readiness was not established, so this does not qualify as an authenticated acceptance baseline.

Observed renderer state:

| Category | Resident | Committed |
| --- | ---: | ---: |
| Private writable | 228.2 MiB | 328.7 MiB |
| Private executable | 0.0 MiB | 0.0 MiB |
| Private other | 0.3 MiB | 2.3 MiB |
| Mapped | 5.7 MiB | 394.1 MiB |
| Image | 38.8 MiB | 369.6 MiB |
| **Total classified** | **273.1 MiB** | **1,094.8 MiB** |

The per-process shared-page flag reduced the renderer's estimated unique-private resident value to 224.9 MiB. This is still only process-local accounting, not cross-process physical-page deduplication.

The largest private-writable allocation families were:

| Allocation base | Regions | Resident | Committed |
| --- | ---: | ---: | ---: |
| `0x29500000000` | 14 | 73.8 MiB | 76.0 MiB |
| `0x2B1C00000000` | 4 | 39.0 MiB | 42.9 MiB |
| `0x7FFCA8600000` | 1 | 11.5 MiB | 12.5 MiB |
| `0x6A3200000000` | 1 | 11.0 MiB | 11.8 MiB |
| `0x3F0800000000` | 5 | 7.2 MiB | 19.3 MiB |

These families are allocation ownership evidence only. They have not been labeled as Blink, media, compositor, or Discord state, and no renderer behavior was changed from this capture.
