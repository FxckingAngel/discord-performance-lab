# Track B authenticated multi-renderer attribution: 2026-10-06

This run used a rooted Track B process tree and preserved each renderer separately. It is resource-attribution evidence, not a same-route official-versus-Track-B acceptance comparison. The exact account route and user workload were not independently machine-verifiable.

## Conditions

- Build: verified Track B shell
- Root PID: 22780
- Duration: 118.7 seconds of usable samples within a 129.8-second capture
- Samples: 12 at approximately 10-second intervals
- Process tree: 10 processes throughout the capture
- Raw local sample: `artifacts/current-settled-120s-cpu-v2.json`
- Renderer command-line details and process identifiers remain local and are not published

## Full-tree results

| Metric | Median | P95 |
| --- | ---: | ---: |
| Summed working set | 1,114.79 MiB | 1,188.46 MiB |
| Private working set | 525.50 MiB | 600.67 MiB |
| Private bytes / commit | 660.66 MiB | 782.13 MiB |
| CPU, all logical processors | 0.009% | 0.287% |

The higher footprint compared with the earlier seven-process settled baseline is explained by four renderer processes present in this tree. This is a workload/profile change, not evidence that the seven-process result was representative of every authenticated state.

## Renderer ownership

The final sample retained four separate renderer rows:

| Renderer | Private working set | Private bytes |
| --- | ---: | ---: |
| Renderer 1 | 96.45 MiB | 115.28 MiB |
| Renderer 2 | 110.14 MiB | 123.81 MiB |
| Renderer 3 | 108.23 MiB | 121.85 MiB |
| Renderer 4 | 107.79 MiB | 122.08 MiB |
| Renderer total | **422.61 MiB** | **483.02 MiB** |

The renderer total is the dominant private-memory owner. The GPU process held 17.08 MiB private working set and 59.57 MiB private bytes at the final sample. The WebView2 browser process held 47.60 MiB private working set and 59.84 MiB private bytes.

## Interpretation

This result answers an important attribution question: the large authenticated footprint was distributed across multiple renderer processes rather than owned by one renderer alone. Any renderer optimization must therefore preserve per-renderer identity and compare renderer count, process lifetime, private working set, private bytes, CPU, and functionality together. Aggregating renderer rows before recording them would hide this distinction.

The result does not justify disabling renderer isolation, changing Chromium process-model settings, trimming memory, or removing features. It also does not prove that all four renderers are Discord UI renderers; the local command-line role map is retained for the next authenticated diagnostic.
