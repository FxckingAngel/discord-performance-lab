# Track B decision 0014: preserve and reproduce the low settled state

Date: 2026-10-06

## Evidence

Two 600-second observations followed a user-confirmed authenticated checkpoint. The first measured 163.94 MiB median private working set and 254.93 MiB median private bytes. The repeat measured 151.24 MiB median private working set and 241.61 MiB median private bytes, with 0.00635% CPU p95. Both runs held a seven-process tree for the complete interval.

The route and account state were confirmed by the user but were not independently inspected by the measurement process. The current unverified live shell is higher, so natural settling, route state, profile state, or workload differences remain possible explanations. No code change is credited for the lower result.

## Decision

Treat the repeated low settled state as the current resource subgate to reproduce, not as permission to lower the target. Keep the normal shell and rollback path unchanged while the project closes the remaining visual, functional, and official same-route comparison gates.

Do not choose a renderer change from the higher unverified live sample alone. Any future candidate must be compared with a user-confirmed settled baseline and must preserve normal Discord functionality.

## Status

Track B remains active. The resource subgate is evidenced; overall acceptance is not.
