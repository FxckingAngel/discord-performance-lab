# Track B rank-based renderer region comparison

This comparison matches private-writable allocation-base groups by resident-size rank, not by raw address. Windows ASLR makes allocation addresses unsuitable as cross-process identity. The authenticated source is the current live boundary capture; the comparison source is the unauthenticated Discord frontend diagnostic. They are not the same route or synchronized workload.

| Rank | Authenticated resident | Unauthenticated resident | Delta |
| ---: | ---: | ---: | ---: |
| 1 | 98.26 MiB | 86.34 MiB | +11.92 MiB |
| 2 | 35.43 MiB | 31.04 MiB | +4.40 MiB |
| 3 | 34.96 MiB | 16.45 MiB | +18.51 MiB |
| 4 | 16.16 MiB | 6.66 MiB | +9.50 MiB |
| 5 | 7.13 MiB | 3.01 MiB | +4.12 MiB |

The leading ranked families are larger in the authenticated state, with the first five ranks contributing approximately 48.45 MiB of additional represented resident memory. This is consistent with account/session/application state adding memory beyond the unauthenticated frontend, but it does not identify the allocator owner or prove that the delta is reclaimable.

The comparison tool is `tools/Compare-TrackBAllocationBaseGroups.ps1`. Raw inputs remain private.
