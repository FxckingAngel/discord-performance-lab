# Track B heap snapshot attribution

Date: 2026-10-06

This was a private diagnostic against the authenticated no-bridge profile. The raw snapshot is stored only in the local ignored benchmark area. The committed result contains aggregate counts and sizes only.

## Aggregate result

- 3,183,792 heap nodes.
- 170.14 MiB total snapshot self-size.
- 4,254 detached nodes.

Largest self-size categories:

| Category | Count | Self size |
| --- | ---: | ---: |
| native | 323,276 | 75.66 MiB |
| code | 504,494 | 28.40 MiB |
| object | 704,099 | 18.47 MiB |
| string | 712,366 | 18.07 MiB |
| array | 215,281 | 13.76 MiB |
| object shape | 167,629 | 8.08 MiB |
| closure | 202,960 | 5.61 MiB |

## Interpretation

The snapshot is larger than the point-in-time `Runtime.getHeapUsage` value because it includes snapshot self-size categories and diagnostic bookkeeping. It does not identify a single retained JavaScript object or detached-tree leak that could safely be removed by the shell. The detached-node count is recorded for follow-up, not treated as proof of a leak.

The result supports the existing attribution: the loaded Discord frontend has a substantial V8/native heap, while process private bytes also include renderer allocation outside the page heap and GPU/runtime allocations. No heap object was modified, collected, or discarded by this diagnostic.

Input: `benchmarks/raw/track-b-current-heap-summary-20261006.json`
