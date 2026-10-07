# Track B WPR native-allocation ownership report

Date: 2026-10-07  
Target renderer PID: 28160  
Capture: `artifacts/track-b-wpr-heap-snapshot-20261007/track-b-heap-snapshot.etl`

## Result

The elevated PID-scoped HeapSnapshot capture succeeded. WPR started and stopped normally, `wpr -singlesnapshot heap 28160` returned code 0, and snapshot configuration was disabled during cleanup. The ETL contains 268,651 events with zero reported lost events.

The Windows Performance Toolkit is now installed. `xperf -a heapsnapshot -data` decoded the existing ETL into one snapshot instance containing 18 outstanding allocations totaling 9,529 bytes (0.009088 MiB). This is a real native-heap result, but it is only the allocation set represented by this snapshot instance. It is not a complete explanation of the renderer's private working set.

The 55,028-byte event-100 payload reported by `tracerpt` is serialized trace data, not allocation bytes. The decoded allocation records and module ranges are retained in `artifacts/track-b-wpr-heap-snapshot-20261007/sanitized-xperf-native-ownership.json`; raw ETL and raw stack text remain private.

## Sanitized memory ledger

The paired authenticated renderer ledger is from the earlier renderer sample used for the V8 comparison. The current PID-scoped snapshot is PID 28160; the ledger is retained as the closest paired attribution evidence and is explicitly not treated as the same instantaneous sample.

| Measure | Value | Interpretation |
| --- | ---: | --- |
| Renderer private-writable resident | 321.62 MiB | Primary resident-memory bucket in the paired ledger |
| V8 used heap | 101.19 MiB | CDP heap-used value, not total renderer memory |
| Private-writable resident minus V8 used | 220.41 MiB | Approximate non-V8 remainder; boundaries are not byte-perfect |
| V8 backing storage | 22.44 MiB | Included in the V8/CDP view and may overlap implementation accounting |
| Renderer mapped resident | 30.03 MiB | Per-process mapped pages |
| Renderer image resident | 79.34 MiB | Loaded image/module pages |
| WPR decoded outstanding native heap | 0.009088 MiB | 18 allocations; snapshot-instance total, not full renderer native memory |

The current direct region classifier for PID 28160 found 231.97 MiB private-writable resident and 328.38 MiB committed private-writable memory in a later, minimized state. That sample is useful for region shape, but it is not substituted into the earlier authenticated ledger.

## Allocation-family report

| Allocation family | Outstanding MiB | Allocation count | Confidence | Likely required at idle? |
| --- | ---: | ---: | --- | --- |
| Blink DOM/layout/style | 0 | 0 | not represented in this snapshot instance | unknown |
| Skia/raster/image | 0 | 0 | not represented in this snapshot instance | unknown |
| Compositor/surface resources | 0 | 0 | not represented in this snapshot instance | unknown |
| WebView2/Edge runtime | 0.000259 MiB directly involving `msedgewebview2.exe` frames | 2 | low; module-only mapping | unknown |
| Media/audio/video | 0.001045 MiB involving `ffmpeg.dll` frames | 2 | low; module-only mapping | unknown |
| Networking | 0 | 0 | not represented in this snapshot instance | unknown |
| Strings/buffers | unresolved | unresolved | no symbols or object type | unknown |
| JIT/code | unresolved | unresolved | no symbols or object type | unknown |
| Discord/application native state | unresolved | unresolved | no application symbols in snapshot | unknown |
| PartitionAlloc or large anonymous arenas | up to 140.95 MiB region evidence, not WPR heap bytes | 25 top-region entries across 3 allocation bases | low | unknown |
| Unknown/unresolved native remainder | approximately 220.40 MiB outside this 0.009088 MiB decoded snapshot set | unresolved | high that it is unresolved | unknown |

The decoded stack-family aggregates are:

| Module family observed in frames | Outstanding bytes | Allocations | Average size | Share of decoded heap |
| --- | ---: | ---: | ---: | ---: |
| ntdll-only wrapper family | 5,601 | 11 | 509.18 bytes | 58.78% |
| KERNEL32 wrapper family | 2,096 | 4 | 524.00 bytes | 22.00% |
| ffmpeg-involved family | 1,096 | 2 | 548.00 bytes | 11.50% |
| msvcrt-involved family | 736 | 1 | 736.00 bytes | 7.72% |

With Microsoft symbols enabled, the recurring ownership is more specific:

| Decoded stack family | Outstanding bytes | Allocations | Share | Evidence |
| --- | ---: | ---: | ---: | --- |
| ntdll loader/TLS allocation (`LdrAllocateTls`, `LdrGetNewTlsVector`, `RtlAllocateHeap`) | 3,665 | 10 | 38.46% | symbolized |
| CRT thread/process initialization (`ucrtbase`, `msvcrt`, `RtlAllocateHeap`) | 3,768 | 4 | 39.54% | symbolized |
| WebView2 worker-thread data (`msedgewebview2`/`kernel32`, `TppAllocThreadData`, `RtlAllocateHeap`) | 2,096 | 4 | 22.00% | symbolized |

All 18 decoded allocations end in the Windows NT heap allocator path `RtlAllocateHeap` / `RtlpHpAllocateHeapSlow`. This snapshot does not show a Chromium PartitionAlloc, Blink, Skia, compositor, WebRTC, or Discord-application allocation stack. The decoded heap is therefore a small initialization/thread-data set, not the owner of the large anonymous resident regions.

The raw stack text is retained locally at `artifacts/track-b-wpr-heap-snapshot-20261007/xperf-heapsnapshot-symbols.txt`. Microsoft system symbols resolved the Windows and CRT frames. Chromium/WebView2 private symbols were not available, so the result cannot identify internal Chromium allocator call sites beyond the module and public frame names shown above.

The 140.95 MiB figure is the sum of three large allocation-base groups from the Windows resident-region classifier:

| Allocation base group | Regions | Resident |
| --- | ---: | ---: |
| `0x39400000000` | 16 | 68.79 MiB |
| `0x5E0C00000000` | 5 | 54.41 MiB |
| `0x4AE800000000` | 4 | 17.75 MiB |

These groups do not match loaded module ranges in the classifier. That is consistent with anonymous private arenas or large runtime allocations, but it does not identify PartitionAlloc, Blink, Skia, or Discord ownership. The three groups therefore serve as correlation targets for the next decoded capture, not as proof of an allocator family.

## Repeated post-capture health check

The shell was minimized during this check. Three 13-sample repetitions completed with the same eight-process tree and 60 Hz, 1920x1080 display:

| Repeat | Total WS median / p95 | Total private WS median / p95 | CPU median / p95 | Renderer private WS median / p95 |
| --- | ---: | ---: | ---: | ---: |
| 1 | 624.12 / 634.56 MiB | 310.08 / 315.20 MiB | 0.032% / 0.519% | 233.88 / 237.84 MiB |
| 2 | 682.92 / 970.22 MiB | 347.87 / 611.52 MiB | 0.320% / 8.679% | 252.24 / 434.25 MiB |
| 3 | 873.58 / 951.74 MiB | 494.95 / 546.32 MiB | 0.179% / 5.140% | 347.32 / 360.87 MiB |

The raw repeat files and normalized summaries are retained under `artifacts/track-b-post-heap-snapshot-repeated-20261007/`. Repeats 2 and 3 show large state/process-tree variance, including renderer growth and high p95 CPU, so this set is diagnostic evidence rather than a stable baseline. It should be repeated after confirming the same window state and process set before using it for an optimization claim.

## Narrow hypothesis and reversible A/B design

The largest currently supportable hypothesis remains:

> One or more large anonymous private allocation arenas, represented by the three allocation-base groups above, account for a substantial part of the non-V8 renderer resident remainder. Their owner is not yet known, and they may be runtime infrastructure rather than reclaimable Discord state.

The first experiment will be a no-code-change, reversible workload A/B. The decoded 9,529-byte set is too small to be the target, so the new captures must be designed to represent the retained heap after the target process is in the desired settled state, not only a short post-enable increment:

1. Capture a settled static text channel with PID-scoped HeapSnapshot enabled.
2. Capture the same renderer after switching to a media-heavy channel and settling for the same interval.
3. Decode both captures with WPA/WPA Exporter once available.
4. Compare outstanding bytes, stack families, module ownership, and the three allocation-base groups. Keep V8, renderer private working set, GPU private working set, and DOM/media counters beside the native results.

If the arena groups and native stacks grow with media, the first candidate becomes decoded image/raster/compositor allocation. If they remain stable while the Discord-loaded delta remains, the candidate shifts toward fixed WebView2/Chromium runtime arenas. No renderer behavior is changed by this experiment, and the snapshot configuration is disabled after each capture.

## WPR capability boundary

Confirmed working elevated operations:

- PID-scoped heap snapshot configuration enable.
- HeapSnapshot recording start.
- PID-scoped single snapshot.
- ETL stop/save.
- Snapshot configuration disable and cleanup.
- `tracerpt` conversion with zero reported lost events.

Now available locally:

- `xperf -a heapsnapshot -data` decoding of allocation sizes, counts, stack addresses, and current-process module membership.
- xperf symbol decoding for Microsoft system, CRT, FFmpeg, and WebView2 thread-entry frames.

Still unavailable locally:

- Private Chromium/WebView2 symbolized allocator ranking.
- A complete outstanding native-heap total that reconciles to the renderer's private working set.

Microsoft documents that a heap snapshot exports allocation information and stacks into the trace buffers, and that WPA is the analysis tool for heap allocation stacks. The local capture therefore proves the collection path, not yet the ownership attribution.

Raw ETL, binary event payloads, and any future heap snapshots remain private and are not published.
