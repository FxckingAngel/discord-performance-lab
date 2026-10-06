# Track B renderer memory attribution

Date: 2026-10-06

This diagnostic used the authenticated no-bridge WebView2 profile. It was collected separately from the normal shell so the incomplete desktop bridge could not change Discord initialization. The raw heap snapshot remains local and private because it can contain account and message data.

## Synchronized Windows and CDP result

The Windows process sample covered 13 samples over about 70 seconds while CDP diagnostics ran against the same diagnostic session. The route was not independently verified, so this is attribution evidence rather than an acceptance benchmark.

| Metric | Result |
| --- | ---: |
| Process count | 8 median / 8 p95 |
| Total working set | 881.46 MiB median / 894.43 MiB p95 |
| Private working set | 449.89 MiB median / 461.38 MiB p95 |
| Derived shareable working set | 431.59 MiB median / 433.05 MiB p95 |
| Private bytes | 628.99 MiB median / 671.92 MiB p95 |
| CPU | 0.119% median / 1.633% p95 |
| Renderer private working set | 339.09 MiB median |
| Renderer private bytes | 378.07 MiB median |

The diagnostic process has higher resident memory than the normal settled observation, so its values must not replace the normal-shell baseline. It is useful for comparing process ownership with CDP measurements taken at the same time.

## CDP memory and page state

| Category | Result | Interpretation |
| --- | ---: | --- |
| V8 used heap | 127.3 MiB | Live JavaScript heap, not the complete renderer allocation |
| V8 heap capacity | 216.9 MiB | Reserved/available V8 heap space; not all resident |
| V8 embedder heap | 30.3 MiB | Embedder-owned V8-related memory |
| Array-buffer backing storage | 24.8 MiB | Backing storage reported by V8 |
| DOM nodes | 6,288 | Aggregate page count |
| Documents / frames | 15 / 14 | Includes inactive or auxiliary documents where present |
| Images / videos / canvases | 167 / 3 / 4 | Resource and surface counts, not decoded-byte totals |
| JavaScript event listeners | 2,442 | Retention signal only; not a byte measurement |

The 10-second CDP performance window measured about 0.160 seconds of task time, 0.117 seconds of script time, 0.00067 seconds of layout time, and 0.00224 seconds of style-recalculation time. This does not support an active idle JavaScript or layout loop as the explanation for the resident footprint.

## Heap snapshot aggregates

The private snapshot contained 3,154,138 nodes and 164.48 MiB of snapshot self-size. The largest aggregate categories were:

| V8 category | Self-size |
| --- | ---: |
| native | 76.15 MiB |
| code | 25.67 MiB |
| object | 19.20 MiB |
| array | 14.31 MiB |
| string | 13.57 MiB |
| object shape | 7.72 MiB |
| closure | 5.78 MiB |

The snapshot reported 4,345 detached nodes. That is a retention signal, not proof of a leak. The `native` heap-snapshot category is also not the same thing as all native Chromium/WebView2 allocations.

## Attribution boundary

The paired renderer private working set was about 339 MiB, while V8 reported about 127 MiB used heap. The difference is at least approximately 212 MiB of renderer-private resident memory that is not explained by live V8 heap alone. It may include Blink structures, decoded resources, compositor allocations, native Chromium allocations, code pages, allocator slack, and other renderer state. The current evidence does not separate those categories by bytes.

No renderer optimization is justified yet. The next safe attribution work is a controlled static-versus-media comparison and, where supported, Chromium memory-infra or allocation-domain measurements. Do not force garbage collection, trim working sets, disable hardware acceleration, or discard Discord state based on this snapshot.

Raw inputs:

- `artifacts/track-b-authenticated-cdp-memory-30s.json`
- `artifacts/track-b-authenticated-cdp-performance-10s.json`
- `artifacts/track-b-authenticated-cdp-paired-summary.json`
- `benchmarks/private/track-b-authenticated-no-bridges-heap-20261006.heapsnapshot`
- `artifacts/track-b-authenticated-no-bridges-heap-summary-20261006.json`
