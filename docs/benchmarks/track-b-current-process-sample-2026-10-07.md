# Track B current process sample

Date: 2026-10-07

This was a read-only 22-second sample of the already running normal Track B shell. It did not restart Track B, touch official Discord, navigate the page, or change renderer behavior. The Discord route and workload were not manually confirmed, so this is diagnostic evidence only.

## Final sample

| Metric | Value |
| --- | ---: |
| Process count | 8 |
| Summed working set | 763.09 MiB |
| Summed private working set | 362.23 MiB |
| Summed private bytes | 521.84 MiB |
| Renderer PID | 28928 |
| Renderer private working set | 269.39 MiB |

The renderer remained the dominant private-resident process. This sample is consistent with the existing fully loaded diagnostic range, but it cannot establish the canonical authenticated idle baseline because route and workload readiness were not independently verified.

The raw process capture remains local under `artifacts/track-b-current-process-sample-20261007.json`.
