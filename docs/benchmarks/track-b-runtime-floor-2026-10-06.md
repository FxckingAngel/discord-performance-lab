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
