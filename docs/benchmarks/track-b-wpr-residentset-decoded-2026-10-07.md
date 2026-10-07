# Track B decoded resident-set evidence

Date: 2026-10-07  
Source ETL: `artifacts/track-b-wpr-elevated-20261006/track-b-cpu-resident.etl`  
Process manifest: `artifacts/track-b-wpr-rooted-20261006/root-process-tree-before.json`

## Result

The Windows Performance Toolkit `residentset` action decoded the existing
elevated ETL into XML. Filtering that XML to the eight PIDs recorded in the
Track B process-tree manifest produced 434.73 MiB of summed ETW resident-set
categories.

| Recorded process role | PID | ETW resident-set categories |
| --- | ---: | ---: |
| WebView2 renderer | 39048 | 315.852 MiB |
| WebView2 GPU process | 39764 | 44.953 MiB |
| WebView2 browser | 8644 | 41.773 MiB |
| WebView2 network service | 4928 | 11.387 MiB |
| Native shell | 28156 | 9.703 MiB |
| WebView2 audio service | 39600 | 4.379 MiB |
| WebView2 storage service | 1080 | 4.344 MiB |
| WebView2 crashpad | 35584 | 2.340 MiB |

The renderer's largest decoded category was `VirtualAlloc_PreTrace` at
307.672 MiB. The GPU process had 37.059 MiB in that category. These values
are consistent with the earlier observation that the renderer dominated the
old capture, but they do not identify which allocator or feature owns those
pages.

## Heap-action boundary

The same ETL was passed to xperf's `heap` action with the recorded renderer
PID. It returned successfully with no heap records. This trace therefore has
resident-set category evidence but no allocation-stack evidence. The absence
of heap rows is not evidence that the renderer has no heap allocations; the
heap provider was not present in that capture.

The xperf `virtualalloc` action was also tested against the recorded renderer
PID with symbol decoding enabled. It returned no allocation rows and only a
stack-query warning. The old trace therefore cannot connect the anonymous
allocation-base groups to virtual-allocation stacks either.

## Accounting limitation

The filtered 434.73 MiB is not a replacement for the current Track B private
working-set KPI. ETW resident-set categories include `PageTable`,
`KernelStack`, `WsMetaData`, image copy-on-write pages, and other categories
that are not unique private application resident memory. The result is useful
for cross-checking process ownership only. The current private-working-set
baseline remains the newer settled process-tree measurement.

The sanitized decoder output is
`artifacts/track-b-wpr-elevated-20261006/sanitized-residentset-trackb.json`.
The xperf action outputs, XML, and raw ETL remain private.
