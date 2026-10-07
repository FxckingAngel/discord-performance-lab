# Track B post-rebuild live baseline

This was a read-only 30-second process-tree capture of the already running normal Track B shell. The route and workload were not manually verified, so this is baseline evidence and not an authenticated acceptance benchmark. The shell was running from the existing `bin/Release` executable; a separate rebuild completed into `bin/Verified`, so this capture does not verify behavior or performance of that rebuilt binary.

Artifact: `artifacts/track-b-post-rebuild-live-baseline-20261007/process-tree.json`

## Result

Six samples were collected for root PID `16360`. The complete tree contained eight processes.

| Metric | Result |
| --- | ---: |
| Private working set median | 377.29 MiB |
| Private working set p95 | 381.89 MiB |
| Total working set median | 798.18 MiB |
| Private bytes median | 562.08 MiB |
| CPU median | 0.084% |
| CPU p95 | 0.348% |
| Final renderer private working set | 277.05 MiB |
| Final GPU private working set | 40.63 MiB |

The renderer remains the largest private-resident allocation. The CPU median is below the 0.2% target, but the short capture is not enough to establish a long-run p95. No optimization flag, memory trimming, or feature disablement was used.

The source rebuild itself succeeded. The full smoke test was not run because the ordinary `bin/Release` shell instance was still active; the test now reports that condition explicitly regardless of executable output path.
