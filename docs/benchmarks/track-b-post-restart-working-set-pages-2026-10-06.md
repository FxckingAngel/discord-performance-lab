# Track B post-restart working-set page classification

Date: 2026-10-06

This was a read-only `QueryWorkingSet` classification of the live eight-process Track B tree rooted at PID 5400. It does not identify physical-page identity across processes, so it is an accounting cross-check and not a replacement for private working set.

| Classification | Resident MiB |
| --- | ---: |
| All sampled resident pages | 825.578 |
| PSAPI `Shared` flag | 195.516 |
| PSAPI `Shared` flag not set | 204.613 |
| `ShareCount` greater than one | 3.414 |
| Single-owner classification | 396.715 |

All eight rooted processes were available. The small `ShareCount > 1` value reinforces that the PSAPI flags cannot be summed or subtracted to derive unique physical RAM. The established private-working-set process metric remains the Track B resident-memory KPI.

Raw capture: `artifacts/track-b-post-restart-working-set-pages.json`.
