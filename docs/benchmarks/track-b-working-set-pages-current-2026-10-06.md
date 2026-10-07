# Track B resident-page classification: 2026-10-06

Status: read-only live diagnostic. The route and workload were not independently verified, and this is not a settled acceptance benchmark.

Source: `artifacts/track-b-working-set-pages-current-20261006.json`

The collector uses Windows `QueryWorkingSet` to classify resident pages by the per-process PSAPI shared flag and share count. These fields are not cross-process physical-page deduplication. They are supporting evidence only.

## Process results

| Role | Resident pages | PSAPI shared flag | Non-shared flag | Share count > 1 | Single-owner count |
| --- | ---: | ---: | ---: | ---: | ---: |
| Renderer | 422.22 MiB | 46.30 MiB | 47.16 MiB | 0.27 MiB | 93.20 MiB |
| Browser | 145.04 MiB | 51.35 MiB | 53.95 MiB | 0.12 MiB | 105.17 MiB |
| GPU process | 99.93 MiB | 28.76 MiB | 30.04 MiB | 1.23 MiB | 57.56 MiB |
| Native shell | 54.00 MiB | 19.93 MiB | 21.22 MiB | 0.68 MiB | 40.47 MiB |
| Network service | 50.41 MiB | 19.16 MiB | 20.56 MiB | 0.33 MiB | 39.39 MiB |
| Audio service | 28.10 MiB | 12.32 MiB | 13.07 MiB | 0.35 MiB | 25.04 MiB |
| Storage service | 23.72 MiB | 10.32 MiB | 10.71 MiB | 0.34 MiB | 20.69 MiB |
| Crashpad | 16.41 MiB | 7.15 MiB | 7.88 MiB | 0.07 MiB | 14.96 MiB |

Complete-tree resident pages totaled 839.83 MiB. The renderer remained the largest process by a wide margin.

## Interpretation

The per-process shared classifications cannot prove unique physical ownership because the same page can be mapped into multiple processes and reported independently. They also do not align exactly with the process working-set counters because the probes use different Windows APIs and timing.

The result does not support dismissing the renderer's private-resident cost as a simple shared-page double count. Keep private working set as the primary optimization KPI and continue reporting total working set, shareable working set, and private bytes separately.

No application behavior or runtime setting was changed.
