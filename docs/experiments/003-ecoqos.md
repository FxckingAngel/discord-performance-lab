# Experiment 003: Windows EcoQoS background scheduling

## Status

Promising private profile; functional acceptance pending.

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

## Acceptance state

The quantitative gate passed. A runtime smoke check also passed: the root process was responsive, exposed a main window titled `Friends - Discord`, and carried the EcoQoS switch. Normal navigation, messaging, notifications, voice, media, settings persistence, and cleanup remain unverified and are still required before final acceptance.
