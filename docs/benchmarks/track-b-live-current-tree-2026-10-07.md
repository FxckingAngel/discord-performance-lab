# Track B live current-tree observation: 2026-10-07

Status: unverified current-state diagnostic. This capture measured the already-running Track B shell without restarting or modifying the official Discord installation. The exact Discord route and workload were not independently checkpointed, so this is not an acceptance benchmark.

Raw capture: `artifacts/track-b-live-current-20261007-014226/`.

## Capture conditions

- Root PID: `28920`
- Window: visible, not minimized, responding
- Display: 1920 x 1080 at 60 Hz
- Samples: 13 over approximately 60 seconds
- Process count: 8 throughout the sample
- Shell build: current running Track B build

## Complete process tree

| Metric | Median | p95 |
| --- | ---: | ---: |
| Total working set | 796.75 MiB | 801.52 MiB |
| Private working set | 395.73 MiB | 400.12 MiB |
| Shareable working set | 400.78 MiB | 401.40 MiB |
| Private bytes | 531.92 MiB | 609.02 MiB |
| CPU | 0.030% | 0.276% |

## Per-role private resident ownership

| Role | Private working set median | CPU median |
| --- | ---: | ---: |
| Renderer | 291.08 MiB | 0.015% |
| GPU process | 37.20 MiB | 0.000% |
| Browser process | 40.33 MiB | 0.000% |
| Native shell | 8.95 MiB | 0.000% |
| Network service | 10.18 MiB | 0.000% |
| Audio service | 3.17 MiB | 0.000% |
| Storage service | 3.08 MiB | 0.000% |
| Crashpad | 1.77 MiB | 0.000% |

The renderer remains the dominant private-resident owner. CPU is already below the 0.2% median target in this observation. The memory result is approximately 145.7 MiB above the overall private-working-set target, but it cannot be used as an optimization claim because the route and workload were not manually verified.

## Renderer resident-page classification

The renderer PID was `34356` during the final classification. Its private-writable resident memory was **286.00 MiB**, against **328.48 MiB** committed private-writable memory. The largest resident allocation-base families were:

| Allocation base family | Resident | Committed |
| --- | ---: | ---: |
| `0x21200000000` | 79.38 MiB | 80.75 MiB |
| `0x24E800000000` | 42.30 MiB | 43.88 MiB |
| `0x2A2000000000` | 19.15 MiB | 19.56 MiB |
| `0x5E0C00000000` | 10.66 MiB | 11.25 MiB |
| `0x7FFEC31C0000` | 9.13 MiB | 10.00 MiB |

The first three families account for approximately **140.82 MiB** resident. These are correlation groups from `VirtualQueryEx` and `QueryWorkingSetEx`, not allocator ownership labels. They do not justify calling the memory Blink, media, compositor, or application state until a workload differential or stack attribution identifies the owner.

No renderer behavior, visible media behavior, authentication behavior, network protocol, or security setting was changed. The result is evidence for the existing renderer-memory attribution work, not permission to disable Discord functionality or apply a speculative runtime switch.
