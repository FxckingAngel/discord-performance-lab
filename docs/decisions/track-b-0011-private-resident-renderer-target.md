# Decision 0011: private-resident renderer target

Date: 2026-10-06

## Current evidence

The latest 10-minute live observation measured 412.10 MiB median complete-tree private working set and 304.68 MiB median renderer private working set. CPU was 0.102% median and 0.636% p95. The renderer therefore owns most of the remaining resident-memory gap, while settled median CPU is already below the 0.2% target.

## Decision

Private working set is the primary Track B resident-memory optimization KPI. Continue reporting total working set, derived shareable working set, and private bytes separately. Do not add shareable working-set sums to unique physical memory, because shared pages can be counted in more than one process.

The next renderer subgoal is approximately **140–150 MiB private working set at settled idle**. If other processes remain near their current levels, this is the approximate renderer level required to approach 250 MiB across the complete tree.

The subgoal must be reached without working-set trimming, forced paging, forced garbage collection, disabled hardware acceleration, removed media, or loss of Discord functionality. CPU optimization is secondary while repeated settled median CPU remains at or below 0.2%; p95 must still be recorded and investigated if it regresses materially.

No renderer implementation change is approved by this decision. The next candidate must first attribute the remaining renderer resident memory across V8, Blink/DOM/layout, media, compositor, code, and native Chromium allocations, then demonstrate a reversible foreground comparison and functional checks.
