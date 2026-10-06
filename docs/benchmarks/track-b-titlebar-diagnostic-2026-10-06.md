# Track B native titlebar diagnostic

Date: 2026-10-06

This is a short diagnostic of the new native shell chrome. It used a clean build of the existing blank-page diagnostic, with the WebView2 content still blank. The authenticated Track B shell was left running and was not restarted.

## Result

| Metric | Median | P95 |
| --- | ---: | ---: |
| Summed working set | 366.05 MiB | 366.17 MiB |
| Private working set | 72.50 MiB | 72.51 MiB |
| Private bytes/commit | 144.94 MiB | 144.95 MiB |
| CPU | 0.027% | 0.027% |
| Processes | 7 | 7 |
| Handles | 3,470 | 3,474.5 |
| Threads | 180 | 180 |

The binary started with the custom frame, responded, and exited through its window close path. This confirms startup and basic native-window behavior for the clean build. It does not prove visual parity with Discord Desktop or functional parity for authenticated Discord use.

The short blank diagnostic is not an acceptance benchmark. The existing authenticated 10-minute result remains the authoritative Track B performance comparison until the new shell is run through the manual functional and visual checkpoints.
