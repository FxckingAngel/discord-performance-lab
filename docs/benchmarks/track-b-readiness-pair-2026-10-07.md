# Track B readiness-paired diagnostic

This capture paired the authenticated no-bridge diagnostic with the existing
aggregate readiness probe and a synchronized process-tree capture. It restarted
and restored Track B only. The official Discord reference was not touched.

Raw evidence is local under:

`artifacts/track-b-readiness-pair-20261007/`

## Readiness

- Route class: `discord-channels`
- Application readiness: true
- Document ready state: `complete`
- Discord mount present with 6 children
- 4,674 aggregate DOM nodes
- 2 frames
- 142 image elements
- 3 video elements, none playing
- 4 canvas elements
- 13 documents reported by the performance domain
- 2,164 JavaScript event listeners
- 0 active RTCPeerConnections

This satisfies the diagnostic readiness predicate, but it remains an
authenticated diagnostic capture rather than a manually confirmed same-route
acceptance benchmark.

## Synchronized process capture

Across seven samples, the process tree contained eight processes. The renderer
and GPU remained present throughout.

| Metric | Median | P95 |
| --- | ---: | ---: |
| Complete-tree private working set | 413.39 MiB | 539.38 MiB |
| Renderer private working set | 316.62 MiB | not separately summarized |
| GPU private working set | 38.23 MiB | not separately summarized |
| Aggregate CPU | 0.300% | not separately summarized |
| V8 used heap | 98.19 MiB at CDP sample | — |

The renderer remained the dominant private-resident process. CDP native
sampling produced mapped module and stack data, but only approximately 1.05 MiB
was sampled, so it is useful for diagnostic capability validation and not a
complete explanation of the renderer's resident memory.

## Result against the low-memory capture

The earlier five-run unverified capture showed approximately 239.52 MiB
complete-tree private working set and 193.14 MiB renderer private working set.
The readiness-paired capture returned to approximately 413.39 MiB and 316.62
MiB respectively while the Discord application was confirmed initialized.

Therefore the low-memory result is not accepted as a product optimization. The
current evidence points to a state or lifetime transition rather than a proven
renderer reduction. Future optimization comparisons must include the
readiness gate and synchronized process capture together.
