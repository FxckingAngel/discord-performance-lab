# Track B Release versus Verified blank-floor comparison

This compares the earlier three-run Release blank-floor result with the new short Verified diagnostic. Neither is an authenticated Discord workload.

| Metric | Release repeated median | Verified short median | Difference |
| --- | ---: | ---: | ---: |
| Total working set | 364.90 MiB | 359.62 MiB | -5.28 MiB |
| Private working set | 74.05 MiB | 71.07 MiB | -2.98 MiB |
| Private bytes | 145.64 MiB | 144.58 MiB | -1.06 MiB |

The Verified blank floor is within the same range as the earlier Release floor. The short Verified run is not enough to claim a statistically significant improvement, but it does not show a material runtime-floor regression. A loaded-state comparison is still required before judging the rebuilt binary against the Track B target.
