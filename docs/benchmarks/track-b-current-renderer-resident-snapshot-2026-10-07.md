# Track B current renderer resident snapshot

Date: 2026-10-07

Artifacts:

- `artifacts/track-b-current-memory-snapshot-20261007/process-tree.json`
- `artifacts/track-b-current-memory-snapshot-20261007/renderer-resident-types.json`

This is a short read-only observation of the normal Track B shell after the isolated file-manager work. The route was not manually confirmed, so it is diagnostic evidence rather than an acceptance benchmark. No renderer flags, media behavior, cache policy, or hardware acceleration setting changed. The official Discord client was not touched.

## Process snapshot

| Metric | Result |
| --- | ---: |
| Samples | 5 |
| Process count | 8 |
| Complete-tree private working set, final sample | 412.24 MiB |
| Complete-tree private bytes, final sample | 543.25 MiB |
| Renderer PID | 28928 |
| Renderer private working set, final sample | 308.01 MiB |
| Renderer private bytes, final sample | 352.87 MiB |
| Renderer handles / threads | 605 / 34 |

## Renderer resident classification

The read-only `VirtualQueryEx` plus `QueryWorkingSetEx` walk reported:

| Category | Resident | Committed |
| --- | ---: | ---: |
| Private writable | 300.33 MiB | 337.09 MiB |
| Private executable | 0.02 MiB | 0.02 MiB |
| Private other | 1.06 MiB | 2.31 MiB |
| Mapped | 37.79 MiB | 393.92 MiB |
| Image | 68.25 MiB | 369.83 MiB |

The largest private-writable allocation-base families were:

| Allocation base | Regions | Resident | Committed |
| --- | ---: | ---: | ---: |
| `0x1C800000000` | 12 | 67.56 MiB | 68.25 MiB |
| `0x5E7400000000` | 9 | 29.21 MiB | 30.25 MiB |
| `0x5A000000000` | 3 | 15.83 MiB | 15.83 MiB |
| `0x137D00000000` | 2 | 10.42 MiB | 11.50 MiB |

The first three families total 112.60 MiB resident. Their ownership is still unresolved. They are not called Blink, Skia, media, or caches until a lifecycle or allocation-stack correlation identifies that ownership.

## Interpretation

The renderer remains the dominant optimization target. The current map separates the private-writable resident bucket from mapped and image pages, but it does not identify allocator ownership or prove reclaimability. No renderer behavior change is justified by this snapshot alone.
