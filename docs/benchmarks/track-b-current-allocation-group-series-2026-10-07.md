# Track B current allocation-base series

Date: 2026-10-07

This is a read-only series against the existing live Track B shell. Three renderer resident classifications were taken about 20 seconds apart without navigation, feature changes, or renderer intervention.

| Sample | Renderer private-writable resident | Renderer committed private-writable | Group `0x39400000000` resident | Group committed |
| --- | ---: | ---: | ---: | ---: |
| 1 | 295.31 MiB | 451.02 MiB | 52.92 MiB | 53.50 MiB |
| 2 | 297.61 MiB | 455.81 MiB | 60.94 MiB | 62.25 MiB |
| 3 | 295.72 MiB | 452.00 MiB | 56.10 MiB | 57.25 MiB |

The group that previously measured approximately 98.258 MiB was present at the same allocation base in all three samples, but its resident size varied by 8.02 MiB over the short series. The other two largest groups in sample 1 were 45.27 MiB and 17.65 MiB. These measurements establish resident-size variability, not ownership. The group must not be called a cache, allocator arena, Blink structure, or compositor surface until lifecycle or stack evidence identifies it.

No production behavior was changed. The series does not disable media, animation, notifications, voice, or any other Discord feature.

Raw classifications remain local at `artifacts/track-b-current-boundary-series-20261007/`.
