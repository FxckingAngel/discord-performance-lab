# Track B rebuilt blank WebView2 floor

This capture used the newly rebuilt Release shell after adding the diagnostic WebView2 process-kind snapshot. It ran with `--diagnostic-blank`, a 5-second sample interval, a short settled observation, and no authenticated Discord state.

| Metric | Result |
| --- | ---: |
| Process count | 7 |
| Summed working set | 368.3 MiB |
| Summed private working set | 73.0 MiB |
| Summed private bytes | 144.5 MiB |
| Per-process resident classification | 367.8 MiB |
| Private writable resident | 56.0 MiB |
| Sampled CPU | 0.017% |

The result is consistent with the earlier blank-floor capture of approximately 369 MiB working set, 70 MiB private working set, and 143 MiB private bytes. The process-kind diagnostic did not materially change the runtime floor.

This is a runtime baseline only. It does not represent authenticated Discord functionality and cannot be used as the Track B acceptance result.
