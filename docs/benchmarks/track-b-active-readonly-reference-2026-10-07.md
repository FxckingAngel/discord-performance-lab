# Track B active read-only reference: 2026-10-07

Status: contemporaneous read-only process-tree snapshot. This is not a same-route A/B acceptance benchmark because the exact route, call state, and visible workload were not machine-verified. The official installation is the user's active **Official Discord + Vencord** client and was not restarted, stopped, or modified.

## Results

| Metric | Official Discord + Vencord | Track B | Interpretation |
| --- | ---: | ---: | --- |
| Complete-tree working set median | 897.95 MiB | 808.95 MiB | Descriptive only |
| Complete-tree private working set median | 777.04 MiB | 403.87 MiB | Descriptive only |
| Complete-tree private bytes median | 2,395.79 MiB | 621.86 MiB | Descriptive only |
| Complete-tree CPU median | 2.208% | 0.045% | Descriptive only |
| Process count | 10 | 8 | Different process topology |
| Renderer count | 3 | 1 | Workload/state may differ |

Each client was sampled for approximately 60 seconds at five-second intervals. Official Discord was rooted at its visible main-window process and Track B was rooted at its normal shell process. Both remained responsive during sampling.

## Attribution context

In the official snapshot, the renderer role accounted for approximately 678.04 MiB private working set and 1.79% CPU, with three renderer processes. In Track B, the single renderer accounted for approximately 293.90 MiB private working set and 0.04% CPU. These values are not a same-workload comparison because the official client was actively in use and the Track B route was not confirmed.

This result supports continuing full-tree and renderer attribution work, but it does not establish a percentage improvement, isolate an Electron tax, or satisfy visual/functional parity. A valid comparison still requires the same account, exact route, call state, window, display, and workload. A pristine unmodified official client is also required for architecture claims.
