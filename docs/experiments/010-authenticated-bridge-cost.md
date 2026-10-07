# Experiment 010: authenticated bridge cost

Date: 2026-10-06

## Scope

The diagnostic mode `--diagnostic-authenticated-no-bridges` reused the normal Track B WebView2 profile and Discord route but did not inject the audited `DiscordNative.window` or `DiscordNative.hardware` bridges. The production launch path was unchanged.

This isolates bridge presence as a possible contributor to the approximately 5 MiB private-bytes near miss. It is not a valid functionality build because it intentionally removes desktop capabilities.

## Result

The no-bridge capture ran for 132.5 seconds with eight samples at 15-second intervals.

| Metric | Production settled baseline | No-bridge diagnostic |
| --- | ---: | ---: |
| Summed working set median | 524.50 MiB | 869.69 MiB |
| Private working set median | 165.43 MiB | 434.14 MiB |
| Private bytes median | 255.20 MiB | 622.49 MiB |
| CPU median | 0.001% | 0.180% |
| Process count | 7 | 8 |

The diagnostic was still settling, with its private bytes falling from 894.4 MiB to 578.0 MiB. That prevents using it as a direct A/B performance result, but it provides no evidence that removing the bridges lowers resource use. It instead changes the frontend/runtime state substantially and introduces an additional process.

## Decision

Do not remove the audited bridges from the production shell. They remain the smallest implemented desktop capability layer, and bridge removal is rejected as an optimization strategy. Future renderer work must preserve the bridges and compare against the separated-role production baseline.

Raw samples remain local at `benchmarks/raw/track-b-authenticated-no-bridges-20261006.json` and its summary file.
