# Track B current native virtual-memory breakdown

This is a short read-only snapshot of the currently running Track B shell. It is diagnostic evidence, not an acceptance benchmark: the visible Discord route and workload were not manually verified for this capture.

The process tree was sampled while the normal shell remained open. `VirtualQueryEx` classified committed virtual regions by allocation type and protection. `QueryWorkingSetEx` was used separately for resident pages. Reserved address space was excluded from RAM totals.

| Role | Private committed | Private writable committed | Mapped committed | Image committed | Private writable resident |
| --- | ---: | ---: | ---: | ---: | ---: |
| Renderer | 351.5 MiB | 349.2 MiB | 384.2 MiB | 369.6 MiB | 326.5 MiB |
| GPU process | 79.1 MiB | 78.7 MiB | 218.1 MiB | 607.0 MiB | 39.9 MiB |
| Browser | 36.5 MiB | 36.0 MiB | 272.4 MiB | 475.9 MiB | 34.1 MiB |
| Network utility | 1.8 MiB | 1.7 MiB | 209.8 MiB | 375.9 MiB | not retained in this table |
| Native shell | 7.2 MiB | 7.1 MiB | 248.7 MiB | 109.9 MiB | 5.4 MiB |

The renderer's committed private region is overwhelmingly writable, while executable private memory is not a material category in the corresponding resident classifier. This does not identify the owner as JavaScript, Blink, media, or application state. Those categories still require feature-specific CDP and scenario captures.

The source artifact remains local under `artifacts/track-b-current-native-memory-check-20261006/virtual-types-recheck.json`.
