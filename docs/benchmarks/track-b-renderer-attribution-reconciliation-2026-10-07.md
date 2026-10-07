# Track B renderer attribution reconciliation

Date: 2026-10-07  
Renderer PID: 28160

## Current evidence ledger

| Evidence source | Value | What it measures |
| --- | ---: | --- |
| Settled renderer private working set | 254.92 MiB median | Primary resident-memory KPI |
| Settled renderer private bytes | 432.81 MiB median | Committed private memory |
| VirtualQueryEx private-writable resident scan | 275.996 MiB | Classified renderer resident pages in a nearby settled state |
| Earlier CDP V8 used heap | 113.77 MiB | Live JavaScript heap for a diagnostic state |
| Clean WPR VirtualAllocation outstanding blocks | 4.926 MiB | Allocations observed during one five-second interval |
| Clean WPR VirtualAllocation committed blocks | 19.137 MiB | Committed virtual-allocation blocks represented by that interval |
| WPR HeapSnapshot outstanding set | 0.008088 MiB | Snapshot-instance allocations only |

These values are intentionally not summed. Each source has a different scope,
and the WPR allocation traces are interval or snapshot evidence rather than a
complete resident-memory ledger.

## What the evidence supports

The renderer remains the dominant resident-memory owner. The clean
VirtualAllocation trace directly observed Chromium PartitionAlloc and V8/JIT
paths, with some stacks passing through Blink timers and Discord frontend
JavaScript. Those observed blocks are far smaller than the renderer's roughly
255 MiB private working set, so they cannot be treated as the main owner.

The current unexplained bucket includes retained native allocations, image and
media resources, compositor surfaces, mapped/runtime pages, and allocations
that were already outstanding before the five-second trace. The existing
anonymous allocation-base groups remain correlation targets, not proven
allocator families.

## Optimization decision

No renderer behavior is changed from this ledger. Disabling JIT, forcing
collection, trimming working sets, or changing Chromium flags would not be an
attribution-backed reduction of the retained resident bucket. The next
high-value experiment remains a manually verified static-text versus
media-heavy pair, using the same settled process measurements and clean
VirtualAllocation capture where the trace has no lost events.

Raw ETL, xperf stack text, CDP data, and account-dependent diagnostics remain
private.
