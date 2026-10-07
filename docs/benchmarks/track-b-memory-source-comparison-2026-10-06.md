# Track B memory-source cross-check

Date: 2026-10-06

This read-only capture queries the rooted process tree through both `Win32_PerfFormattedData_PerfProc_Process` and `Get-Counter` at the same sampling point. It checks whether the earlier difference between the direct process-tree sampler and the fallback counter capture was caused by different definitions.

## Result

All seven rooted PIDs were available through both sources, and every per-PID value matched exactly.

| Metric | WMI | Get-Counter |
| --- | ---: | ---: |
| Private working set | 166.82 MiB | 166.82 MiB |
| Private bytes | 256.59 MiB | 256.59 MiB |

The per-PID comparison is stored at `benchmarks/raw/track-b-memory-source-comparison-20261006.json`. It included the native shell, browser, crashpad, GPU, network service, storage service, and renderer. The earlier 256.8 MiB versus 265.6 MiB difference therefore came from separate captures and timing/row availability, not a stable disagreement between the two APIs.

This cross-check does not replace the longer settled benchmark. It establishes that synchronized samples can use either source consistently, while the direct rooted process-tree sampler remains the acceptance path because it also records CPU deltas, role mapping, handles, threads, and process lifetime.
