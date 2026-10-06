# Track B WebView2 runtime floor

Date: 2026-10-06

This diagnostic capture estimates the cost of the native shell and installed WebView2 runtime without loading Discord. It used `KoroneDiscordShell.exe --diagnostic-blank`, an isolated user-data folder, and `about:blank`. It is attribution evidence only and is not a Track B application performance result.

The rooted capture ran for about 32 seconds with six five-second intervals. The window was responsive and the final sample contained seven processes:

| Role | Working set | Private memory | CPU seconds |
| --- | ---: | ---: | ---: |
| WebView2 browser | 127.6 MiB | 36.7 MiB | 1.11 |
| GPU process | 68.8 MiB | 57.1 MiB | 0.33 |
| Native shell host | 56.8 MiB | 11.7 MiB | 0.27 |
| Renderer | 47.7 MiB | 19.7 MiB | 0.12 |
| Network service | 41.5 MiB | 11.6 MiB | 0.23 |
| Storage service | 18.7 MiB | 7.3 MiB | 0.05 |
| Crashpad | 19.8 MiB | 3.4 MiB | 0.02 |
| **Total** | **380.7 MiB** | **147.5 MiB** | **2.13** |

The latest Discord-loaded unauthenticated shell sample was 836.2 MiB working set and 557.7 MiB private memory across eight processes. The blank-versus-Discord-loaded difference in this pair is therefore about 455.5 MiB working set and 410.2 MiB private memory. The pair is not a valid official-Discord comparison because it uses separate profiles and different content states, but it shows that the current shell cannot approach the 250 MiB target through native-host overhead alone.

The raw capture remains local and ignored at `benchmarks/raw/track-b/runtime-floor/blank-30s.json`.

## Repeated private-accounting floor

Three additional settled repetitions used the updated rooted collector. Each run waited six seconds for startup, then sampled for about 30 seconds. The final sample from each run was retained for the settled summary:

| Metric | Run 1 | Run 2 | Run 3 | Median | p95 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Total working set | 376.6 MiB | 375.9 MiB | 372.2 MiB | 375.9 MiB | 376.6 MiB |
| Private working set | 73.3 MiB | 73.1 MiB | 71.6 MiB | 73.1 MiB | 73.3 MiB |
| Derived shareable working set | 303.3 MiB | 302.8 MiB | 300.7 MiB | 302.8 MiB | 303.3 MiB |
| Private bytes / commit | 145.3 MiB | 145.4 MiB | 143.6 MiB | 145.3 MiB | 145.4 MiB |
| Process count | 7 | 7 | 7 | 7 | 7 |

Windows exposed `WorkingSetPrivate` and `PrivateBytes` through the process performance provider. It did not expose a native Process counter named `Working Set - Shared`; the reported shareable value is therefore the per-process derived remainder `workingSet - workingSetPrivate`. It is retained for attribution but is not treated as unique physical RAM.
