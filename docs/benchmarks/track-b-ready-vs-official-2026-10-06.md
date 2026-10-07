# Track B READY checkpoint versus official Discord

Date: 2026-10-06

This is a process-tree comparison between the `READY` Track B capture and the contemporaneous official Discord checkpoint. The user supplied the manual route confirmation for Track B. The exact route and account state are not independently machine-verifiable, so this is comparative evidence, not the final same-route acceptance result.

| Metric | Official median | Track B median | Improvement |
| --- | ---: | ---: | ---: |
| Summed working set | 1166.87 MiB | 531.56 MiB | 54.45% |
| Private working set | 588.70 MiB | 178.14 MiB | 69.74% |
| Private bytes / commit | 979.34 MiB | 256.32 MiB | 73.83% |
| Total CPU | 0.108% | 0.008% | 92.59% |
| Process count | 6 | 7 | Track B has one more process |
| Handles | 6741 | 3546.5 | 47.39% lower |
| Threads | 272.5 | 173 | 36.51% lower |

P95 values also favored Track B for memory: private working set was 192.18 MiB versus 590.97 MiB, and private bytes were 274.05 MiB versus 1019.17 MiB.

The Track B physical-resident subgate passes, and the CPU target passes. The private-bytes target does not: the Track B median is 6.32 MiB above the approximately 250 MiB design target. The comparison tool therefore correctly reports the full target as failed.

This result does not prove visual parity, complete desktop capability parity, or preservation of every required Discord feature. Those remain separate acceptance gates. It also does not justify reducing the target or using working-set trimming, paging tricks, disabled media, or security changes.

Raw comparison inputs remain local and private:

- `benchmarks/raw/official-contemporaneous-checkpoint-summary-2026-10-06.json`
- `benchmarks/raw/track-b-ready-manual-checkpoint-20261006-064727-summary.json`
