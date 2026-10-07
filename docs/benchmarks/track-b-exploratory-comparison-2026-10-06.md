# Track B exploratory full-tree comparison

Date: 2026-10-06

## Scope

This compares the current same-machine observations from [official visible Friends idle](official-visible-friends-idle-2026-10-06.md) and [Track B profile diagnostic](track-b-profile-diagnostic-2026-10-06.md). The official client showed `Friends - Discord`. Track B loaded a Discord document, but its account and exact route state were not verified. These percentages are therefore exploratory attribution only, not acceptance results.

## Measured comparison

| Metric | Official Discord | Track B profile | Track B change |
| --- | ---: | ---: | ---: |
| Summed working set | 1147.25 MiB | 531.06 MiB | 53.72% lower |
| Private working set | 576.72 MiB | 184.59 MiB | 68.00% lower |
| Private bytes / commit | 908.64 MiB | 262.82 MiB | 71.08% lower |
| Total CPU | 0.347% | 0.024% | 93.08% lower |
| Process count | 6 | 7 | 1 higher |

The current evidence supports the architecture's resource-reduction hypothesis, especially for private resident memory and idle CPU. It does not establish that Track B preserves normal Discord functionality or that it reaches the target on the same authenticated channel.

The repository comparison tool independently calculated the same result. Its target sub-gate passed at 185.06 MiB private working set and 0.008% CPU, but the overall comparison failed because the process counts were 7 versus 6 and the controlled workload contract was not met. This is the expected safe outcome for an exploratory, state-mismatched pair.

## Next acceptance use

The next valid comparison must replace the Track B profile row with a manually authenticated Track B capture using the same account, route, window size, display, call state, and settled duration. The formulas and metric definitions remain fixed. No result should be called a Track B improvement until that controlled pair exists.
