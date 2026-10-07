# Track B post-rebuild process sample

This was a read-only 16-second sample of the restored Release shell after a normal close, rebuild, and relaunch. The route and workload were not manually confirmed. Official Discord was not touched.

| Metric | Earlier sample | Post-rebuild sample |
| --- | ---: | ---: |
| Process count | 8 | 8 |
| Summed private working set | 362.23 MiB | 433.78 MiB |
| Summed working set | 763.09 MiB | 830.45 MiB |
| Summed private bytes | 521.84 MiB | 571.24 MiB |
| Renderer private working set | 269.39 MiB | 323.01 MiB |
| Renderer PID | 28928 | 26104 |

The process count is stable, but the private-resident state differs by 71.55 MiB for the complete tree and 53.62 MiB for the renderer. This is diagnostic evidence that unverified short samples are not a valid optimization baseline. The canonical authenticated route and settle condition still need to be held constant before accepting memory changes.

Raw capture: `artifacts/track-b-post-rebuild-sample-20261007.json`.
