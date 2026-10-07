# Track B garbage-collection reclaim probe

Date: 2026-10-06

## Scope

This was an opt-in diagnostic run with a 60-second settle period and a 30-second process capture. It invoked Chromium's diagnostic `HeapProfiler.collectGarbage` once after the initial heap measurement. The route and workload were not independently verified. The normal shell was restored after capture.

Raw local output:

- `artifacts/track-b-gc-probe-20261006/cdp.json`
- `artifacts/track-b-gc-probe-20261006/process-tree.json`

The collection was not added to normal Track B startup or runtime behavior.

## V8 result

| Metric | Before | After | Change |
|---|---:|---:|---:|
| V8 used heap | 106.40 MiB | 100.95 MiB | -5.45 MiB |
| V8 total heap | 111.36 MiB | 107.36 MiB | -4.00 MiB |
| Embedder heap | 29.97 MiB | 25.50 MiB | -4.47 MiB |
| Backing storage | 22.79 MiB | 22.55 MiB | -0.24 MiB |

The CDP collection command completed successfully.

## Renderer result

During the process capture, renderer private working set was 315.94 MiB before the collection, then 309.23, 305.30, 300.43, 303.11, 302.63, and 325.54 MiB across subsequent samples. The renderer did not show a sustained drop corresponding to the 5.45 MiB V8 reduction.

The final 325.54 MiB sample also had 1.32% renderer CPU, so it is not used as a settled idle estimate.

## Interpretation

The collection reclaimed a small amount of V8 memory but did not materially reduce renderer private resident memory. This is evidence against forced garbage collection as a path to the 250 MiB goal. It also supports shifting the investigation toward Blink/layout, decoded media, compositor resources, code pages, and native WebView2 allocations.

No production change was made, and no forced GC should be used to game the benchmark.
