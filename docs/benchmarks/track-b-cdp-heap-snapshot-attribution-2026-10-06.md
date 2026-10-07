# Track B CDP heap-snapshot attribution

Date: 2026-10-06

This diagnostic used the authenticated Track B profile in isolated diagnostic mode. The raw Chromium heap snapshot remains local and private. The checked-in evidence contains only aggregate node types, counts, and self sizes. The collector uses the Chromium DevTools Protocol `HeapProfiler.takeHeapSnapshot` method and receives the snapshot through `HeapProfiler.addHeapSnapshotChunk`; these are documented in the [official DevTools Protocol HeapProfiler reference](https://chromedevtools.github.io/devtools-protocol/tot/HeapProfiler/).

## Sanitized snapshot summary

| Measurement | Result |
| --- | ---: |
| Heap nodes | 1,059,554 |
| Aggregate JavaScript heap-snapshot self size | 52.67 MiB |
| Detached nodes reported | 5 |

| Snapshot node type | Count | Self size |
| --- | ---: | ---: |
| Native | 83,964 | 28.23 MiB |
| Code | 281,157 | 13.10 MiB |
| String | 315,036 | 5.03 MiB |
| Concatenated string | 114,463 | 2.18 MiB |
| Array | 5,275 | 1.85 MiB |
| Object shape | 17,008 | 1.00 MiB |
| Closure | 25,971 | 0.71 MiB |
| Object | 23,096 | 0.47 MiB |

The snapshot shows a large native category inside the renderer heap graph, but this is still a V8/heap-profiler category and must not be equated with the entire Windows renderer private allocation. It does not identify GPU textures, decoded image cache, Blink partitions, WebRTC buffers, or other Chromium allocations outside the JavaScript isolate.

Combined with the earlier 120.31 MiB renderer private-bytes measurement and 27.7 MiB `Runtime.getHeapUsage` used heap, the result leaves a substantial unclassified renderer remainder. The next step is therefore Chromium/Blink/native allocation attribution or a controlled runtime architecture comparison, not a JavaScript collection or renderer-isolation change.

Raw private artifacts:

- `artifacts/diagnostic-authenticated-heap-followup-20261006.heapsnapshot`
- `artifacts/diagnostic-authenticated-heap-followup-20261006.summary.json`
