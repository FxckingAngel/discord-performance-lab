# Track B heap retention capture

Date: 2026-10-06

## Scope

This capture used a 60-second settle period, a 30-second diagnostic window, and one local V8 heap snapshot. The route and workload were not independently verified. The raw snapshot remains private at `artifacts/track-b-heap-settled-20261006/private.heapsnapshot`.

Only the sanitized aggregate summary is suitable for project notes. It emits counts and sizes, not names, strings, URLs, page text, cookies, tokens, or heap objects.

## Heap composition

| Heap type | Count | Self size |
|---|---:|---:|
| Native | 323,349 | 75.72 MiB |
| Code | 521,650 | 30.51 MiB |
| Object | 699,870 | 18.46 MiB |
| String | 705,531 | 18.07 MiB |
| Array | 213,749 | 14.16 MiB |
| Object shape | 169,362 | 8.17 MiB |
| Closure | 201,954 | 5.58 MiB |
| Other reported types | n/a | 2.15 MiB |
| **Total snapshot self size** | **3,193,489** | **172.83 MiB** |

The snapshot summary reported 4,942 detached nodes. This is a count only and does not establish that the detached nodes are the cause of the renderer's resident footprint.

The contemporaneous CDP counters were 111.08 MiB V8 used heap, 115.98 MiB V8 total heap, 28.83 MiB embedder heap, 23.79 MiB backing storage, 6,240 DOM nodes, 2,369 JavaScript event listeners, 14 documents, 161 image elements, 3 video elements, and 4 canvas elements.

## Instrumentation effect

The heap snapshot is not a no-overhead idle measurement. The renderer process rows were:

| Sample phase | Renderer private working set | Page faults/sec | CPU |
|---|---:|---:|---:|
| Before snapshot | about 307–319 MiB | 0–219 | 0.00–0.57% |
| During snapshot serialization | 1,727.67 MiB | 185,941 | 1.92% |
| Final snapshot sample | 2,663.32 MiB | 372,477 | 6.24% |

Those spike samples are excluded from Track B idle medians and p95 values. They demonstrate that heap snapshots perturb resident memory and page-fault behavior, so snapshots are attribution artifacts only.

## Interpretation

The repeated snapshot total is about 173 MiB, close to the earlier 172 MiB snapshot. V8 and heap composition are therefore reproducible enough to justify retention analysis, but the snapshot does not explain the entire renderer private working set. Native heap, Blink/layout, decoded media, compositor resources, and shared graphics allocations remain separate categories.

No renderer optimization was selected from the snapshot alone. The next safe analysis is to compare aggregate heap categories across two settled captures without publishing private heap contents, then test one measured retention hypothesis at a time.
