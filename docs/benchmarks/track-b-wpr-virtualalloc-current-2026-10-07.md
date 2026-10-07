# Track B current virtual-allocation stack evidence

Date: 2026-10-07  
Renderer PID: 28160  
Capture: five-second elevated `VirtualAllocation.Verbose.File` trace

## Capture quality

The five-second trace completed without the lost-event warning that affected
the earlier 20-second attempt. The raw ETL and xperf text output remain
private.

## Sanitized stack aggregates

The xperf `virtualalloc` action produced 22 real stack blocks after GLOBAL and
TOP-N rollup blocks were removed to avoid double-counting.

| Ownership family | Blocks | Outstanding | Committed |
| --- | ---: | ---: | ---: |
| Chromium PartitionAlloc | 14 | 2.613 MiB | 16.574 MiB |
| V8/JIT/code | 8 | 2.313 MiB | 2.563 MiB |
| Total represented blocks | 22 | 4.926 MiB | 19.137 MiB |

The raw stack evidence includes `msedge.dll` PartitionAlloc frames and V8 JIT
code-event/compilation frames. Some stacks also pass through Blink timer
execution and Discord frontend JavaScript, but the sanitized report does not
publish asset URLs or source locations.

A top-frame decode of the same clean ETL split the represented outstanding
commit into `KernelBase.dll!VirtualAlloc` at 2.676 MiB and
`KernelBase.dll!VirtualAlloc2` at 2.368 MiB, totaling 5.044 MiB. This is an
entry-point cross-check only; the full-stack decode is the source used for
ownership-family classification.

## Interpretation

This is the first direct stack-level evidence connecting the renderer's
anonymous virtual-allocation activity to Chromium PartitionAlloc and V8/JIT
paths. It does not explain the full approximately 255 MiB renderer private
working set. The trace covers allocations observed during a five-second
interval, not all retained allocations, resident pages, image/media surfaces,
or shared physical pages.

The result does not justify disabling JIT, changing allocator behavior, or
altering Discord's frontend. The next use is comparative: repeat the same
capture for a manually confirmed static text state and media-heavy state, then
compare these ownership families against the renderer private working set and
region groups.

## Repeatability boundary

A second five-second default-profile capture was rejected because xperf
reported lost events, so it is not used as evidence. A private exported profile
with the collector buffer count increased from 20 to 200 was also tested; WPR
rejected that profile at start with exit code `-983562735`, and no ETL was
created. The valid result in this report therefore remains a single clean
five-second capture. No custom-profile result is treated as valid until WPR
accepts it and xperf reports a complete trace.

Sanitized output:

`artifacts/track-b-wpr-virtualalloc-current-5s-20261007/sanitized-virtualalloc-summary.json`
