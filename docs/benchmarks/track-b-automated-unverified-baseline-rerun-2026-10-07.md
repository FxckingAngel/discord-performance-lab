# Track B automated baseline rerun

This five-repetition run measured the rebuilt normal Track B shell after the desktop identity change. It used the existing authenticated WebView2 profile, but no manual route checkpoint, so it is diagnostic evidence rather than final same-route acceptance evidence.

## Results

| Metric | Median | p95 | Min | Max | Standard deviation |
| --- | ---: | ---: | ---: | ---: | ---: |
| Complete-tree private working set | 357.27 MiB | 378.97 MiB | 354.74 MiB | 378.97 MiB | 10.31 MiB |
| Complete-tree private bytes | 529.17 MiB | 548.19 MiB | 522.89 MiB | 548.19 MiB | 11.30 MiB |
| CPU | 0.033% | 0.034% | 0.017% | 0.034% | 0.007 percentage points |

All five repetitions completed, and all five renderer resident-memory classifications were captured. The process-tree sampler no longer aborted when a renderer memory map changed during the read-only classification step.

## Interpretation

The run establishes a tighter automated variance band than the earlier failed run, but it does not prove the exact authenticated route or visual/functional parity. The result remains above the approximately 250 MiB private-resident target, while CPU is below the 0.2% median target.

Raw captures remain private under `artifacts/track-b-automated-unverified-baseline-20261007-rerun/`.
