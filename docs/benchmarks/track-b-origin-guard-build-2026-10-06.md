# Track B origin-boundary build verification: 2026-10-06

Track B's normal native bridge now parses the WebView2 message source as a URI and accepts only HTTPS `discord.com` or a `*.discord.com` host. Diagnostic bridge modes retain their isolated probe behavior. The bridge still exposes only the previously audited window and display-count actions.

## Verification

- The regression suite passed all 34 PowerShell-tool checks.
- The shell rebuilt successfully into the verified output.
- The previous shell closed through its normal window action; no forced termination was used.
- The rebuilt shell started at PID 32472 and became responsive.
- The rebuilt shell remained responsive after measurement.

## Post-build resource capture

- Duration: 621.09 seconds
- Samples: 20 at 30-second intervals
- Process tree: seven processes in every sample
- Raw sample: `benchmarks/raw/track-b-post-origin-guard-build-full-settled-20261006.json`

| Metric | Median | P95 |
| --- | ---: | ---: |
| Summed working set | 521.10 MiB | 522.06 MiB |
| Private working set | 166.06 MiB | 166.96 MiB |
| Private bytes / commit | 255.21 MiB | 256.07 MiB |
| Total CPU | approximately 0% at median sampler resolution | 0.00635% |

The result is consistent with the earlier 255 MiB checkpoint and does not show a resource regression from URI-based origin validation. The approximately 241.6 MiB result from the prior naturally settled session remains valid evidence, but this build capture did not reproduce it within the same post-restart window.

This change does not claim visual parity or functional parity. It tightens the native message boundary without spoofing Electron, authentication, authorization, or Discord network behavior.
