# Track B renderer lifecycle repeat

Date: 2026-10-07  
Both runs used the authenticated no-bridge diagnostic shell and automatic `/app` navigation. Neither run manually confirmed an exact channel, so both are route-unverified diagnostics rather than the canonical acceptance baseline.

## Settled comparison

| Metric | Earlier run, 10 minutes | Repeat run, 10 minutes | Difference |
| --- | ---: | ---: | ---: |
| Complete-tree private working set | 399.23 MiB | 377.13 MiB | -22.10 MiB |
| Renderer private working set | 294.86 MiB | 276.12 MiB | -18.74 MiB |
| Renderer private bytes | 338.96 MiB | 319.58 MiB | -19.38 MiB |
| V8 used heap | 93.86 MiB | 90.36 MiB | -3.50 MiB |
| Renderer private resident outside V8 | 201.00 MiB | 185.76 MiB | -15.24 MiB |
| Complete-tree CPU median | not reliable, two samples | 0.04% | within target |
| Complete-tree CPU p95 | not reliable, two samples | 0.21% | near target |

## Repeat-run lifecycle

| Checkpoint | Tree private WS | Renderer private WS | V8 used | Tree CPU median | Tree CPU p95 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Blank | 94.97 MiB | 9.76 MiB | 0.50 MiB | 0.00% | 0.55% |
| Navigation | 627.89 MiB | 514.03 MiB | 56.56 MiB | 0.10% | 11.33% |
| Application shell | 430.96 MiB | 326.84 MiB | 149.68 MiB | 0.05% | 1.55% |
| Canonical route | 402.98 MiB | 298.39 MiB | 98.67 MiB | 0.00% | 0.15% |
| Settled 1 minute | 402.86 MiB | 297.76 MiB | 103.75 MiB | 0.00% | 0.05% |
| Settled 5 minutes | 396.94 MiB | 288.88 MiB | 94.78 MiB | 0.05% | 1.03% |
| Settled 10 minutes | 377.13 MiB | 276.12 MiB | 90.36 MiB | 0.04% | 0.21% |

## Allocation-family repeat

The repeat had the same overall shape as the earlier run, but family sizes were not identical:

- blank renderer top three: 4.20 MiB;
- navigation renderer top three: 316.15 MiB;
- application shell top three: 98.48 MiB;
- settled 10-minute top three: 118.74 MiB.

The largest family was approximately 221 MiB during navigation and approximately 67 MiB at 10 minutes. This confirms a large transient initialization allocation and a smaller persistent settled family set, but does not identify the owner.

## Interpretation

The 22.10 MiB tree-level difference between these two route-unverified settled runs is larger than a small optimization claim should be. The next formal baseline must use the same manually confirmed static route and at least three settled repetitions. CPU should remain deprioritized: the repeat median is already below 0.2%, and its p95 is reported separately.

No production behavior was changed. The capture did not clear caches, force garbage collection, trim working sets, disable media, alter protocol behavior, or expose a partial desktop bridge. Raw process and memory maps remain local/private.
