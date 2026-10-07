# Track B live follow-up

Date: 2026-10-07

Status: unverified diagnostic observation. The exact authenticated route and workload were not independently confirmed, so this is not an acceptance baseline.

The rebuilt normal shell, root PID 38572, was sampled for 30 seconds across the complete process tree without sending input or changing Discord state.

| Metric | First sample | Last sample |
| --- | ---: | ---: |
| Total working set | 784.8 MiB | 775.3 MiB |
| Total private memory | 627.4 MiB | 580.6 MiB |
| Samples | 5 | 5 |

The downward movement during the short window reinforces the existing state/lifetime variance finding. It does not demonstrate an optimization or a failed target. A manually confirmed canonical route and settled repetition set remain required before comparing memory changes.

The official Discord reference was not touched.
