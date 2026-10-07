# Experiment 001: Chromium low-end device mode

## Status

Rejected for the current candidate set.

## Change

The stock Discord PTB launch was repeated with the external Chromium switch:

```text
--enable-low-end-device-mode
```

The switch propagated to the Discord root process. No package files or user settings were changed.

## Paired resource result

The comparison used two stock idle runs and two candidate idle runs with the same process-tree collector:

| Metric | Stock median/p95 | Candidate median/p95 | Change |
| --- | ---: | ---: | ---: |
| Working set | 1,265.66 / 1,373.59 MiB | 1,026.08 / 1,057.85 MiB | median -18.9% |
| Private memory | 1,130.16 / 1,171.10 MiB | 842.85 / 873.73 MiB | median -25.4% |
| Total CPU | 0.958% / 0.980% | 0.863% / 1.123% | median -9.9%, p95 +14.6% |
| Process count | 6 / 6 | 6 / 6 | unchanged |

## Startup result

| Profile | Run 1 | Run 2 |
| --- | ---: | ---: |
| Stock | 9.813 s | 13.007 s |
| Candidate | 13.028 s | 13.163 s |

The startup observer measures process-tree stabilization, not UI readiness.

## Decision

The candidate is rejected because the p95 CPU regression exceeds the 5% gate and the candidate startup is slower in both runs. The memory reduction is interesting, but it is not sufficient to accept a profile that worsens tail CPU and startup behavior. The functional checklist was not marked passed, so this experiment cannot be promoted.
