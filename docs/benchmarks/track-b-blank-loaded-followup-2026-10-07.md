# Track B blank versus loaded follow-up

Date: 2026-10-07  
Artifacts: `artifacts/track-b-blank-followup-20261007` and `artifacts/track-b-current-followup-20261007`

Both captures used the same attribution tool, 60-second settle period, 30-second measurement window, five-second sampling interval, and resident-memory classification. The loaded state was an authenticated no-bridge diagnostic with a ready `discord-channels` document. The blank state was intentionally uninitialized and therefore is a runtime-floor control only.

| State | Complete-tree private working set | Process count | V8 used heap | Readiness |
| --- | ---: | ---: | ---: | --- |
| Blank WebView2 | 72.11 MiB | 7 | 0.50 MiB | false |
| Discord loaded diagnostic | 397.89 MiB | 8 | 102.60 MiB | true |

The loaded diagnostic adds approximately 325.78 MiB of complete-tree private resident memory over the blank control. This confirms that the remaining Track B gap is created by the Discord-loaded state rather than the blank WebView2 runtime floor.

The comparison does not identify ownership by itself. The loaded renderer remains the next target, with native resident classification and allocation-base lifecycle tracking required before any renderer behavior is changed. The blank result is not counted as a Discord performance win because it is not initialized.

## Rank-based renderer family comparison

Using `Compare-TrackBAllocationBaseGroups.ps1` on the renderer resident scans, the loaded renderer's first five ranked private-writable allocation groups exceeded the blank renderer's corresponding ranks by approximately 130.7 MiB combined. The largest rank increased by 73.5 MiB, the second by 23.5 MiB, and the third by 17.2 MiB.

This is deliberately a rank-based comparison. Allocation-base addresses are process-local and can change between renderer processes, so these rows do not prove that a particular allocator family is the same object across the blank and loaded captures. They establish the scale of the Discord-loaded resident families and justify same-renderer lifecycle tracking as the next attribution step.
