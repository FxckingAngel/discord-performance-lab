# Track B aggregate heap comparison

Date: 2026-10-06

Compared summaries:

- Earlier local snapshot: `artifacts/track-b-cdp-heap-current-20261006-1700/heap-summary.json`
- Settled local snapshot: `artifacts/track-b-heap-settled-20261006/heap-summary.json`
- Sanitized comparison: `artifacts/track-b-heap-settled-20261006/heap-comparison.json`

The two captures used the same local aggregate-only summary format. The route and workload were not independently verified, so this comparison is diagnostic rather than an acceptance result.

## Aggregate change

| Measurement | Earlier | Settled | Change |
|---|---:|---:|---:|
| Nodes | 3,198,838 | 3,193,489 | -5,349 |
| Heap self size | 171.56 MiB | 172.83 MiB | +1.27 MiB |
| Detached nodes | 4,299 | 4,942 | +643 |

## Largest type changes

| Type | Earlier | Settled | Change |
|---|---:|---:|---:|
| Code | 29.25 MiB | 30.51 MiB | +1.26 MiB |
| Native | 75.60 MiB | 75.72 MiB | +0.13 MiB |
| Object shape | 8.09 MiB | 8.17 MiB | +0.09 MiB |
| Array | 14.08 MiB | 14.16 MiB | +0.08 MiB |
| String | 18.25 MiB | 18.07 MiB | -0.18 MiB |
| Closure | 5.64 MiB | 5.58 MiB | -0.06 MiB |

## Interpretation

The aggregate heap size is effectively flat between these captures. The comparison does not show the kind of large retained-heap growth that would explain the renderer's approximately 287–318 MiB private-working-set range by itself. It also does not prove that individual application objects are efficiently retained, because the summaries intentionally omit object names and retainers and the route/workload was not independently verified.

The current evidence shifts the priority toward non-JavaScript resident categories: Blink/layout structures, decoded image/media resources, compositor surfaces, code and native allocator pages, and WebView2/Chromium bookkeeping. No heap-clearing or forced-GC behavior was added.
