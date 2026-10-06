# Track B current working-set page flags

Date: 2026-10-06

This was a read-only PSAPI `QueryWorkingSet` snapshot of the normal Track B tree after the renderer attribution work. Parent-child relationships were guarded by process creation time. The result is an accounting cross-check, not a replacement for Windows `Working Set - Private`.

| Classification | Resident memory |
| --- | ---: |
| All rooted resident pages | 830.23 MiB |
| PSAPI Shared flag | 198.79 MiB |
| PSAPI ShareCount greater than one | 3.38 MiB |
| PSAPI single-owner classification | 403.40 MiB |

The PSAPI Shared flag and ShareCount are per-process page classifications. They do not deduplicate the same physical page across the complete process tree. The large difference between the flag totals and the share-count total also shows why neither should be substituted for the private-working-set counter.

The renderer row contained approximately 402.8 MiB of resident pages in this snapshot, with 0.3 MiB classified as shared by share count and 93.4 MiB classified as single-owner under the returned page flags. These classifications do not reconcile directly to the renderer's Windows private working set because the APIs use different definitions and the snapshot is point-in-time.

Decision: retain total working set, private working set, derived shareable working set, private bytes, and these page flags as separate measurements. Use private working set as the primary resident-memory KPI. Do not claim a unique physical-memory reduction from this page snapshot.

Raw input: `artifacts/track-b-current-working-set-pages.json`.
