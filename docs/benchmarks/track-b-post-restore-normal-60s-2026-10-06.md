# Track B post-restore normal-shell capture, 60-second request

Date: 2026-10-06

This read-only capture followed the isolated authenticated no-bridge diagnostic and normal-shell restore. It collected 13 samples over 76.2 seconds from the ordinary `KoroneDiscordShell` process. The window remained visible and responsive at 1920x1080 and 60 Hz. The Discord route, account state, and workload were not independently verified.

| Metric | Median | P95 |
| --- | ---: | ---: |
| Processes | 8 | 8 |
| Working set | 838.94 MiB | 846.08 MiB |
| Private working set | 413.25 MiB | 422.05 MiB |
| Derived shareable working set | 423.64 MiB | 425.70 MiB |
| Private bytes | 576.13 MiB | 631.15 MiB |
| CPU | 0.119% | 0.913% |
| Renderer private working set | 308.86 MiB | 314.46 MiB |
| Renderer private bytes | 352.17 MiB | 357.37 MiB |

The renderer's page-fault rate was zero at the median but reached 4,929/sec at p95. Renderer I/O was 741 bytes/sec read and 370 bytes/sec written at the median. These counters are evidence of activity during this run, not proof of paging or a cause; the route and workload were not verified and ETW remains unavailable under the current Windows policy.

This result does not demonstrate a safe optimization. It shows that the lower previously observed settled state is not automatically reproduced after restoring the ordinary shell. The next valid comparison remains a manually prepared static-versus-media pair with preserved per-PID and CDP evidence.

Raw capture: `artifacts/track-b-post-restore-normal-60s.json`.
Summary: `artifacts/track-b-post-restore-normal-60s-summary.json`.
