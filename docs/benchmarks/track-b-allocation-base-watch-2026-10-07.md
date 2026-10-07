# Track B idle allocation-base watch

Date: 2026-10-07  
Renderer PID: `26104`  
Captures: 4, three seconds apart  
Artifact: local `artifacts/track-b-allocation-base-watch-current-20261007-r2/manifest.json`

This was a read-only watch of the existing renderer. It did not navigate Discord, change settings, request garbage collection, trim the working set, or alter page state. The route was not manually confirmed, so this is diagnostic evidence only.

## Stable families

| Allocation base | Resident range | Committed range | Resident delta |
| --- | ---: | ---: | ---: |
| `0x29500000000` | 70.902 MiB | 72.500 MiB | 0.000 MiB |
| `0x2B1C00000000` | 37.699–37.703 MiB | 42.500 MiB | 0.004 MiB |
| `0x7FFCA8600000` | 10.816 MiB | 12.000 MiB | 0.000 MiB |
| `0x6A3200000000` | 10.527 MiB | 11.500 MiB | 0.000 MiB |
| `0x3F0800000000` | 7.043 MiB | 17.746 MiB | 0.000 MiB |

The largest family remained at about 70.9 MiB and the second at about 37.7 MiB throughout the watch. That indicates stability during this short idle interval, but it does not establish whether the families are a fixed WebView2 floor or Discord-created state. Workload transitions are still required.

The first attempt exposed a strict-mode issue in the watcher because PowerShell had not initialized `LASTEXITCODE`; that was fixed before the successful four-capture run.
