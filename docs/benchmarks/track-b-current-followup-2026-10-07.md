# Track B current renderer follow-up

Date: 2026-10-07  
Mode: `unverified-route-and-workload`  
Artifact: `artifacts/track-b-current-followup-20261007`

This synchronized capture used the authenticated no-bridge diagnostic shell after a 60-second settle period and a 30-second measurement window. The diagnostic reported `discord-channels`, a complete document, a populated Discord mount, and a stable renderer/process mapping. The exact account route and user workload were not manually confirmed, so this is diagnostic evidence rather than the canonical acceptance baseline.

## Process-tree snapshot

| Metric | Result |
| --- | ---: |
| Process count | 8 |
| Complete-tree working set | 800.81 MiB |
| Complete-tree private working set | 397.89 MiB |
| Renderer PID | 38280 |
| Renderer private working set | 294.36 MiB |
| Renderer private bytes | 346.44 MiB |
| Renderer unique private resident | 306.82 MiB |
| GPU private working set | 37.94 MiB |

The renderer reported approximately 102.6 MiB of V8 used heap, 6,069 performance-metric nodes, 13 documents, 13 frames, 2,264 JavaScript event listeners, 149 image elements, 3 video elements, and 4 canvases. The application-readiness predicate was true and the Discord mount was present.

## Renderer resident classification

The renderer resident scan reported:

- private-writable resident: 291.28 MiB
- private-writable committed: 335.03 MiB
- mapped resident: 35.77 MiB
- image resident: 74.34 MiB
- shared-flag resident: 107.75 MiB
- three private-writable regions at least 16 MiB: 35.33 MiB combined

The largest private-writable allocation-base groups were:

| Allocation base | Regions | Resident | Committed |
| --- | ---: | ---: | ---: |
| `0x36600000000` | 13 | 76.64 MiB | 78.00 MiB |
| `0x171C00000000` | 7 | 23.98 MiB | 25.50 MiB |
| `0x332000000000` | 4 | 17.72 MiB | 17.72 MiB |

These are allocation ownership groups only. They are not labeled as caches, Blink, Skia, compositor, or Discord state until a stack or lifecycle correlation identifies their owner.

## Interpretation

The renderer remains the dominant resident-memory target. V8 accounts for roughly 102.6 MiB of the renderer diagnostic heap, while the private-writable resident classification remains roughly 291 MiB. This supports continuing native-memory attribution rather than treating the whole renderer footprint as JavaScript memory.

The capture does not justify changing renderer behavior. The next valid optimization experiment still needs a manually confirmed canonical route and repeated measurements, followed by lifecycle comparison of the three large allocation-base families.
