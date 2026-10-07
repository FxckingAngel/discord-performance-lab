# Track B post-rebuild full-tree native memory classification

This is a read-only classification of every process in the live Track B tree. The route and workload were not manually verified, so it is attribution evidence rather than an authenticated acceptance benchmark. The shell was the existing `bin/Release` instance; it was not the separately rebuilt `bin/Verified` executable.

Artifacts:

- `artifacts/track-b-post-rebuild-full-native-types-20261007/resident-types.json`
- `artifacts/track-b-post-rebuild-full-native-types-20261007/summary.json`

## Per-role resident classification

| Role | Resident pages | Private writable resident | Mapped resident | Image resident |
| --- | ---: | ---: | ---: | ---: |
| Renderer | 383.21 MiB | 285.11 MiB | 21.56 MiB | 75.56 MiB |
| GPU process | 103.97 MiB | 38.39 MiB | 6.00 MiB | 59.34 MiB |
| Browser | 144.49 MiB | 33.05 MiB | 9.44 MiB | 101.78 MiB |
| Native shell | 53.08 MiB | 4.42 MiB | 11.75 MiB | 36.88 MiB |
| Network service | 50.18 MiB | 7.59 MiB | 3.76 MiB | 38.72 MiB |
| Storage service | 24.46 MiB | 1.89 MiB | 1.69 MiB | 20.82 MiB |
| Audio service | 28.70 MiB | 1.77 MiB | 1.73 MiB | 25.12 MiB |
| Crashpad | 16.37 MiB | 0.81 MiB | 0.91 MiB | 14.59 MiB |

The renderer is the dominant private-writable resident owner. GPU private writable memory is material but much smaller. Browser and utility image pages account for resident runtime code and shared mappings; they should not be treated as reclaimable Discord state without feature-specific evidence.

These are per-process classifications. They are not cross-process unique physical-page accounting, and reserved address space is excluded. No working-set trimming, paging, security change, or feature disablement was used.
