# Track B verified-build comparison

Date: 2026-10-06

This comparison used the newly published Track B shell against the currently running official Discord PTB client. Both process trees were measured for 10 minutes with 20 samples at 30-second intervals. Track B was restarted from the older prototype binary into the verified build before this run. Official Discord was not restarted.

The exact authenticated route and workload were not machine-verifiable through the native-window connector, so this is a contemporaneous same-profile comparison, not final same-route parity evidence.

## Results

| Metric | Official PTB | Track B | Change |
| --- | ---: | ---: | ---: |
| Summed working-set median | 1162.31 MiB | 534.90 MiB | 53.98% lower |
| Summed working-set P95 | 1168.93 MiB | 535.32 MiB | 54.20% lower |
| Private working-set median | 582.62 MiB | 178.30 MiB | 69.40% lower |
| Private working-set P95 | 590.17 MiB | 178.70 MiB | 69.72% lower |
| Private bytes/commit median | 964.89 MiB | 256.88 MiB | 73.38% lower |
| Private bytes/commit P95 | 967.49 MiB | 257.62 MiB | 73.37% lower |
| CPU median | 0.083% | 0.003% | 96.39% lower |
| Processes | 6 | 7 | One additional Track B process |

The Track B target sub-gate passes using the defined resident-private metric: 178.30 MiB is below 250 MiB and 0.003% CPU is below 0.2%. Private bytes/commit is slightly above 250 MiB, so the result is recorded as a near-miss for that secondary accounting view rather than rounded down.

The extra process is the WebView2 storage service. It remains in scope until voice, video, media, notification, and download scenarios show whether that service is needed. No process was removed to make the count pass.

Functional parity, visual parity, exact same-route confirmation, and the full workload matrix remain open. Raw samples and summaries stay in ignored private benchmark directories.
