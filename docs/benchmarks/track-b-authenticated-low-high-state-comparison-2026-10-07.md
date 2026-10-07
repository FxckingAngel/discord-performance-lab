# Track B authenticated low-versus-high state comparison

Date: 2026-10-07

This comparison investigates the earlier approximately 113 MiB authenticated diagnostic state versus the later approximately 405 MiB normal-shell state. Both used the same built shell and the `WebView2UserData` profile. The diagnostic launch used `--diagnostic-authenticated-no-bridges`; the normal shell used no diagnostic argument. Both reported `https://discord.com/app`, but the exact route and manual workload state were not independently confirmed in the diagnostic runs.

| Metric | Low diagnostic state | Long authenticated diagnostic | Normal-shell reference |
| --- | ---: | ---: | ---: |
| Complete-tree private working set | 113.32 MiB | 384.07 MiB | 405.62 MiB |
| Complete-tree private bytes | 242.69 MiB | 522.82 MiB | 568.79 MiB |
| Renderer private working set | 76.16 MiB | 277.14 MiB | 330.18 MiB |
| Renderer PID | 34340 | 19596 | 40684 |
| V8 used heap | 14.97 MiB | 100.19 MiB | not available without CDP |
| Documents | 2 | 10 | not available without CDP |
| DOM nodes | 1,084 / 1,036 aggregate | 5,196 / 4,311 aggregate | not available without CDP |
| Image elements | 0 | 127 | not available without CDP |
| Canvas elements | 0 | 2 | not available without CDP |
| Process count | 7 | 8 | 8 |

The low state is not a lightweight version of the same normal Discord workload. It has a minimal document tree, almost no V8 state, no image elements, and no canvas elements. The longer diagnostic state has a substantially initialized frontend and closely approaches the normal-shell memory range. The evidence therefore points to frontend initialization and retained Discord application state, not a persistent runtime saving that can currently be carried into normal use.

The low state must not be used as an optimization result or acceptance benchmark. No feature was disabled to create it, and no renderer behavior was changed. The next controlled comparison should manually confirm the same static channel in both shells before testing individual variables such as diagnostic launch mode or profile state.
