# Track B current renderer heap attribution: 2026-10-06

Status: private diagnostic evidence. The route and workload were not independently verified. The raw snapshot remains local and is not committed.

## Capture

- Diagnostic mode: authenticated no-bridge profile
- Requested runtime observation: 30 seconds
- One renderer target
- CDP allocation sampling and a local V8 heap snapshot
- Normal shell restored after capture and observed responsive

Raw files:

- `artifacts/track-b-cdp-heap-current-20261006-1700/private.heapsnapshot`
- `artifacts/track-b-cdp-heap-current-20261006-1700/heap-summary.json`
- `artifacts/track-b-cdp-heap-current-20261006-1700/detached-edges.json`

## Heap composition

The snapshot contains 3,198,838 nodes and 171.56 MiB of aggregate self-size. These are V8 heap-snapshot categories, not a replacement for the renderer's private working-set counter.

| Snapshot category | Self-size |
| --- | ---: |
| Native | 75.60 MiB |
| Code | 29.25 MiB |
| Object | 18.51 MiB |
| String | 18.25 MiB |
| Array | 14.08 MiB |
| Object shape | 8.09 MiB |
| Closure | 5.64 MiB |

The separate runtime reading for this capture reported 61.22 MiB V8 used heap and 71.91 MiB total heap. The snapshot is larger because it includes additional snapshot categories and uses a different aggregate boundary; the two values must not be added together.

## Detached-node check

- Detached nodes: 4,299
- Detached nodes with incoming edges: 4,299
- Detached native self-size: 0.67 MiB
- Dominant incoming edge category: element indexes
- Sanitized application-state-like incoming edges: 546

The detached-node allocation is small relative to the renderer private working set. It is not currently a sufficient explanation for the roughly 280–310 MiB renderer private-resident measurements.

## Decision

No frontend or renderer change is justified by this snapshot alone. The measured remainder still needs separation between Blink/DOM, decoded image or media resources, compositor/shared graphics, code, and other native Chromium allocations. Keep the snapshot local because it may contain private Discord data, and do not force collection or alter the normal shell based on detached-node counts.
