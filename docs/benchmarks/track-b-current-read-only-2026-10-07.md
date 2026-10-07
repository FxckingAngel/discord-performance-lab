# Track B current read-only process snapshot

This was a read-only 30-second observation of the already-running normal
Track B shell. It did not restart Track B or touch official Discord.

Raw evidence:

`artifacts/track-b-current-read-only-20261007.json`

The process tree contained eight processes in all four samples. The route and
visible workload were not manually confirmed, so this is diagnostic evidence,
not an acceptance result.

| Metric | First sample | Last sample |
| --- | ---: | ---: |
| Complete-tree working set | 863.48 MiB | 830.27 MiB |
| Complete-tree private working set | 457.21 MiB | 424.40 MiB |
| Complete-tree private bytes | 705.36 MiB | 725.39 MiB |
| Process count | 8 | 8 |

Last-sample roles:

| Role | Working set | Private working set | Private bytes |
| --- | ---: | ---: | ---: |
| Renderer | 421.82 MiB | 312.16 MiB | 351.51 MiB |
| GPU process | 100.45 MiB | 43.45 MiB | 276.29 MiB |
| Browser | 142.93 MiB | 40.39 MiB | 49.14 MiB |
| Network service | 47.14 MiB | 10.31 MiB | 15.48 MiB |
| Native shell | 60.23 MiB | 9.91 MiB | 13.25 MiB |
| Storage service | 20.24 MiB | 3.06 MiB | 8.65 MiB |
| Audio service | 24.61 MiB | 3.29 MiB | 8.05 MiB |
| Crashpad | 12.84 MiB | 1.82 MiB | 3.04 MiB |

This confirms that the normal shell currently remains in the previously
observed high-memory band. The renderer is still the primary private-resident
owner, with the GPU process second. No optimization is inferred from this
snapshot.
