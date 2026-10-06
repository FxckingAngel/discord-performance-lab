# Track B virtual-memory type attribution: 2026-10-06

This was a read-only `VirtualQueryEx` snapshot of the current seven-process Track B tree rooted at PID 24280. It classifies committed virtual regions as `MEM_PRIVATE`, `MEM_MAPPED`, `MEM_IMAGE`, or other. These are commit-address-space categories, not resident-RAM categories, and must not replace the process sampler's working-set/private-working-set measurements.

Raw artifact: `benchmarks/raw/track-b-virtual-memory-types-current-20261006.json`.

## Per-process result

| Role | Process private bytes | Private committed regions | Mapped committed | Image committed |
| --- | ---: | ---: | ---: | ---: |
| Renderer | 120.42 MiB | 112.44 MiB | 251.96 MiB | 369.80 MiB |
| Browser/utility | 42.69 MiB | 31.26 MiB | 279.99 MiB | 474.75 MiB |
| GPU process | 58.42 MiB | 23.56 MiB | 199.37 MiB | 599.83 MiB |
| Network service | 13.25 MiB | 7.03 MiB | 231.45 MiB | 375.62 MiB |
| Storage service | 7.58 MiB | 1.97 MiB | 227.46 MiB | 365.07 MiB |
| Crashpad handler | 3.11 MiB | 1.24 MiB | 179.53 MiB | 33.76 MiB |
| Native shell | 12.14 MiB | 7.90 MiB | 268.81 MiB | 115.26 MiB |

## Interpretation

The renderer's process private bytes are close to its committed `MEM_PRIVATE` regions, while mapped and image-backed regions are much larger virtual reservations. This makes the renderer's remaining private allocation a useful target for allocator/runtime attribution, but it does not identify JavaScript, Blink, decoded media, WebRTC, or GPU ownership. The snapshot also does not prove that committed private pages are resident.

No renderer setting, Chromium switch, memory trimming, or page instrumentation was changed. The next candidate still needs a foreground process-tree comparison and normal-function checks.
