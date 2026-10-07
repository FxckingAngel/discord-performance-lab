# Track B settled renderer attribution

Date: 2026-10-06

## Scope

This was a 60-second settle followed by a 120-second CDP and process-tree capture of the authenticated no-bridge probe. The route and workload were not independently verified, so this remains diagnostic evidence rather than an acceptance benchmark. The normal shell was restored after capture.

Raw local output:

- `artifacts/track-b-cdp-settled-20261006/process-tree.json`
- `artifacts/track-b-cdp-settled-20261006/process-summary.json`
- `artifacts/track-b-cdp-settled-20261006/cdp.json`
- `artifacts/track-b-cdp-settled-20261006/renderer-attribution.json`

## Complete-tree result

| Metric | Median | P95 |
|---|---:|---:|
| Process count | 8 | 8 |
| Total working set | 833.38 MiB | 851.48 MiB |
| Private working set | 389.25 MiB | 424.13 MiB |
| Shareable working set | 444.11 MiB | 446.57 MiB |
| Private bytes | 580.75 MiB | 617.21 MiB |
| Total CPU | 0.108% | 0.289% |

Private working set remains the primary resident-memory KPI. Shareable working set is reported separately and is not treated as unique physical memory.

## Renderer result

| Metric | Result |
|---|---:|
| Renderer PID | 3796 |
| Renderer private working set median | 287.00 MiB |
| Renderer private working set P95 | 311.37 MiB |
| Renderer working set median | 404.00 MiB |
| Renderer private bytes median | 351.13 MiB |
| Renderer CPU median | 0.081% |
| Renderer page faults median | 221 per second |

Other private-working-set medians were GPU 43.15 MiB, browser 36.44 MiB, native shell 7.11 MiB, network 8.85 MiB, audio 3.10 MiB, storage 2.91 MiB, and crashpad 1.37 MiB.

## Runtime attribution

| Measurement | Result |
|---|---:|
| V8 used heap | 106.15 MiB |
| V8 total heap | 112.86 MiB |
| V8 embedder heap | 29.42 MiB |
| V8 backing storage | 22.78 MiB |
| DOM documents | 15 |
| DOM nodes | 6,249 |
| JavaScript event listeners | 2,421 |
| Frames | 2 |
| Image elements | 157 |
| Video elements | 3 |
| Canvas elements | 4 |
| Canvas pixels | 128,115 |

The sampled native profile recorded 0.952 MiB of sampled allocation, all classified as Chromium-native and mapped to the sanitized `msedge.dll.pdb` module label. This is sampled allocation data, not resident memory. It cannot be subtracted from the renderer private working set.

## Interpretation

This capture narrows the next investigation. The renderer's 287 MiB private resident median is not explained by a small JavaScript heap: V8 alone is about 106 MiB used, with additional embedder/backing storage, DOM/layout, decoded resources, compositor state, and native allocations still unaccounted for. CPU is already within the 0.2% median target and remains secondary.

No renderer behavior was changed from this evidence. The next safe step is local-only heap-retention analysis across repeated settled captures, keeping snapshots private and publishing only aggregate retained-object categories.
