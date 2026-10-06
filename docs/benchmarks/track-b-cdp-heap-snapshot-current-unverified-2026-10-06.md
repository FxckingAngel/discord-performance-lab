# Track B current private heap snapshot

This capture used the repeatable unverified authenticated-no-bridges diagnostic. The raw snapshot is private and remains under `artifacts/track-b-cdp-current-20261006-163748/private.heapsnapshot`. Only aggregate counts and sizes are recorded here.

| Measurement | Result |
| --- | ---: |
| Heap nodes | 3,178,664 |
| Aggregate snapshot self size | 171.55 MiB |
| Detached nodes reported | 4,862 |
| `Runtime.getHeapUsage` used heap | 61.32 MiB |
| Native allocation samples in the same diagnostic | 710 |

| Snapshot type | Count | Self size |
| --- | ---: | ---: |
| Native | 321,439 | 75.92 MiB |
| Code | 514,910 | 29.37 MiB |
| Object | 698,085 | 18.36 MiB |
| String | 703,601 | 18.02 MiB |
| Array | 213,450 | 14.00 MiB |
| Object shape | 168,260 | 8.15 MiB |
| Closure | 202,608 | 5.60 MiB |

The snapshot's `Native` category is inside the V8 heap graph and is not the same as the renderer's Windows private working set. The detached-node count is a lead for retaining-path analysis, not proof of a leak. The route and workload were not independently verified, and no frontend or runtime change was made.
