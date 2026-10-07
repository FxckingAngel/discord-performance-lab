# Track B process-tree parent-reuse correction: 2026-10-07

The first post-smoke sampler run reported 16 processes and approximately 498.97 MiB complete-tree private working set. That result was invalid. It included an unrelated Overwolf tree whose parent PID had been reused by the current WebView2 browser PID.

The affected process was created on 2026-10-06, while the current Track B browser was created on 2026-10-07. The sampler's creation-time conversion assumed WMI text, but PowerShell returned `CreationDate` as a native `DateTime`; the conversion failed and the old code accepted the child conservatively.

## Correction

`Measure-DiscordPhase2Attribution.ps1` now:

- accepts native `DateTime` process creation values;
- falls back to WMI and invariant date parsing when needed;
- rejects ancestry when either creation time cannot be validated;
- requires each child creation time to be at or after its parent's creation time.

## Corrected smoke-follow-up

The same running Track B shell was sampled for six observations at one-second intervals after the fix:

| Metric | Median | p95 |
| --- | ---: | ---: |
| Process count | 8 | 8 |
| Complete-tree private working set | 388.61 MiB | 390.57 MiB |
| Renderer private working set | 285.87 MiB | 287.23 MiB |
| CPU | 0.042% | 0.083% |

The window remained visible, responsive, and at 1920 x 1080 / 60 Hz. This is still an unverified route/workload observation, not an acceptance benchmark. The contaminated 16-process result is excluded from Track B baselines.
