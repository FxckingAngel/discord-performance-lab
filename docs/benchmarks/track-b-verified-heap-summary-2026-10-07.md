# Track B Verified sanitized heap summary

This summary came from a local heap snapshot captured during the Verified authenticated no-bridge diagnostic after 60 seconds of settling. The route and workload were not manually verified. The raw snapshot is private under `artifacts/` and is not published or inspected as page content.

Artifacts: `artifacts/track-b-verified-authenticated-heap-20261007/heap-summary.json` and the private `private.heapsnapshot` in the same directory.

## Sanitized aggregate

| Heap type | Self-size | Nodes |
| --- | ---: | ---: |
| Native | 75.36 MiB | 318,479 |
| Code | 29.73 MiB | 517,503 |
| String | 18.31 MiB | 722,381 |
| Object | 18.13 MiB | 688,960 |
| Array | 14.04 MiB | 211,586 |
| Object shape | 8.15 MiB | 168,787 |
| Closure | 5.52 MiB | 199,551 |

The snapshot contained 3,183,895 nodes, 171.37 MiB summed self-size, and 4,124 detached nodes. The associated five-sample process-tree medians were 424.24 MiB complete-tree private working set, 577.47 MiB private bytes, and 316.39 MiB renderer private working set.

These are heap-snapshot self-size categories, not retained sizes and not a complete physical-memory ledger. The native category cannot be equated with all renderer-native resident memory, and detached-node count alone does not prove a leak. The next step is a sanitized retaining-path or before/after lifecycle comparison for detached trees and state objects, followed by a complete-tree functional regression check.

## Detached-edge summary

The private snapshot was processed by the local detached-edge summarizer. It found 4,124 detached nodes, all with incoming edges. Their combined detached self-size was approximately 0.64 MiB. The largest sanitized incoming-edge categories were:

| Category | Edges |
| --- | ---: |
| Element index | 40,116 |
| Other named property | 7,273 |
| DOM-relationship-like | 5,228 |
| Application-state-like | 520 |

All detached nodes were classified as `native` by the snapshot schema. This makes detached DOM retention a valid lifecycle lead, but its measured self-size is far too small to explain the renderer's approximately 316 MiB private working set by itself. The summary is stored beside the private snapshot as `detached-edges-summary.json` and contains no raw names or strings.
