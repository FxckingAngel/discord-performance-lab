# Experiment 003: Windows EcoQoS background scheduling

## Status

Mixed private profile; functional acceptance pending.

## Change

Launch Discord with:

```text
--enable-features=UseEcoQoSForBackgroundProcess
```

The switch was present on the root process in both candidate runs. The profile is reproducible with `tools/Launch-DiscordPerformanceProfile.ps1` and does not modify the installed client or user settings.

## Paired resource result

Two stock idle runs were compared with two EcoQoS idle runs:

| Metric | Stock median/p95 | EcoQoS median/p95 | Change |
| --- | ---: | ---: | ---: |
| Working set | 1,265.66 / 1,373.59 MiB | 1,099.65 / 1,186.93 MiB | median -13.1% |
| Private memory | 1,130.16 / 1,171.10 MiB | 876.37 / 934.21 MiB | median -22.5% |
| Total CPU | 0.958% / 0.980% | 0.275% / 0.291% | median -71.3% |
| Process count | 6 / 6 | 6 / 6 | unchanged |

## Startup result

| Profile | Run 1 | Run 2 |
| --- | ---: | ---: |
| Stock | 9.813 s | 13.007 s |
| EcoQoS | 12.641 s | 12.769 s |

The startup observer measures process-tree stabilization, not UI readiness. EcoQoS startup stayed within the observed stock range, but the functional checklist has not yet been completed.

A later window-aware run recorded process-tree stabilization at 12.135 s, the first main window at 1.260 s, and the final title `Friends - Discord`. The window was responsive in every sampled observation. This confirms launch and window responsiveness only; it does not confirm navigation, messaging, voice, media, notifications, settings persistence, or cleanup.

## Acceptance state

The quantitative gate passed. Runtime smoke checks passed twice: the root process was responsive, exposed a main window titled `Friends - Discord`, and carried the EcoQoS switch. A stock restore was then verified by launching without the candidate switch. Normal navigation, messaging, notifications, voice, media, settings persistence, and cleanup remain unverified and are still required before final acceptance.

An additional paired idle run on 2026-10-06 did not pass the regression gate. Stock measured 1,375.48 MiB working-set median, 1,153.23 MiB private-memory median, and 0.889% CPU. EcoQoS measured 1,366.95 MiB, 1,125.86 MiB, and 1.012% CPU. Memory improved by 0.6% and 2.4%, while CPU regressed by 13.8%; process count stayed at six. The latest pair is therefore not sufficient to accept EcoQoS as a default profile, despite the earlier favorable pair.

## Background-idle result

A separate paired run closed the main window and measured the remaining process tree for 20 seconds. The gate passed:

| Metric | Stock | EcoQoS | Change |
| --- | ---: | ---: | ---: |
| Working set median/p95 | 1,349.85 / 1,371.15 MiB | 1,340.30 / 1,341.45 MiB | p95 -2.2% |
| Private memory median/p95 | 1,157.45 / 1,181.99 MiB | 1,135.38 / 1,137.15 MiB | p95 -3.8% |
| CPU median/p95 | 0.560% / 0.560% | 0.171% / 0.171% | -69.5% |
| Process count median/maximum | 6 / 6 | 6 / 6 | unchanged |

This supports EcoQoS as a background-idle profile, not as a universal foreground default. The close-window action was used to create the background workload; it is not equivalent to Discord's in-app Quit action, and full functional acceptance remains pending.
