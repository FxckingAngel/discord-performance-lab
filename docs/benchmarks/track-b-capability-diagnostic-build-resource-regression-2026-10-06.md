# Track B capability-diagnostic build resource check

Date: 2026-10-06  
Build: rebuilt `Verified` shell containing diagnostic-only capability-call logging and the authenticated capability-events launch mode  
Scenario: same live shell process, settled foreground state  
Runs: two consecutive 10-minute observations

Raw runs:

- `benchmarks/raw/track-b-capability-diagnostic-build-settled-10min-20261006.json`
- `benchmarks/raw/track-b-capability-diagnostic-build-followup-10min-20261006.json`

## Results

| Run | Private working set median / p95 | Private bytes median / p95 | CPU median / p95 |
|---|---:|---:|---:|
| First rebuilt run | 175.53 / 190.25 MiB | 254.40 / 272.18 MiB | 0.006 / 0.006% |
| Same-process follow-up | 162.59 / 162.73 MiB | 254.04 / 254.39 MiB | 0.002 / 0.002% |

The CPU target passed, but private bytes remained above the approximately 250 MiB target in both rebuilt-binary observations. The follow-up shows that the first run's high p95 was partly settling or transient allocation, but it did not return below the strict private-bytes gate.

## Interpretation

The capability-call logger is guarded by the diagnostic-mode boolean and is not registered or executed in the normal shell path. The remaining difference is concentrated in the renderer, but these two runs do not identify a removable renderer allocation or prove a code regression. The earlier 40-sample resource pass remains valid evidence for the earlier build/session; this rebuilt binary now requires a controlled comparison against the prior binary or a later repeated settled session before the target can be called stable.

No forced collection, working-set trimming, paging hint, hardware-acceleration change, or functionality reduction was used.
