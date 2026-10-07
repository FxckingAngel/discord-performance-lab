# Official Discord visible idle comparison

Date: 2026-10-06

## Scope

Official Discord PTB was already open on the visible `Friends - Discord` window. This was a read-only 35-second process-tree observation of root PID 26556. It was not a controlled same-account, same-route comparison against Track B because Track B's authenticated account state remains unconfirmed.

## Official process-tree result

| Metric | Median | P95 | Minimum | Maximum |
| --- | ---: | ---: | ---: | ---: |
| Summed working set | 1147.25 MiB | 1149.79 MiB | 1142.65 MiB | 1149.80 MiB |
| Private working set | 576.72 MiB | 579.22 MiB | 572.14 MiB | 579.27 MiB |
| Private bytes / commit | 908.64 MiB | 952.39 MiB | 883.61 MiB | 953.41 MiB |
| Shareable working set | 570.53 MiB | 570.65 MiB | 570.51 MiB | 570.70 MiB |
| Total CPU | 0.347% | 0.347% | - | - |
| Process count | 6 | 6 | - | - |

## Last-sample role attribution

| Role | Working set | Private working set | Private bytes |
| --- | ---: | ---: | ---: |
| Browser | 180.8 MiB | 67.6 MiB | 121.1 MiB |
| Renderer | 599.1 MiB | 430.6 MiB | 531.8 MiB |
| GPU process | 163.4 MiB | 61.9 MiB | 255.0 MiB |
| Network service | 69.6 MiB | 12.4 MiB | 21.4 MiB |
| Audio service | 98.0 MiB | 5.2 MiB | 10.5 MiB |
| Crashpad | 38.9 MiB | 1.4 MiB | 9.5 MiB |

The renderer is the dominant official private-working-set owner in this observation. The GPU process is the second-largest private-bytes owner. These results support prioritizing renderer and GPU attribution, but they do not establish a final percentage improvement because the Track B workload and account state were not proven identical.

Raw samples remain under `benchmarks/raw/` and are not published.
