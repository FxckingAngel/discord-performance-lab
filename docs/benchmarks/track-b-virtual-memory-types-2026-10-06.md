# Track B virtual-memory type attribution: 2026-10-06

This was a read-only `VirtualQueryEx` snapshot of the current seven-process Track B tree rooted at PID 24280. It classifies committed virtual regions as `MEM_PRIVATE`, `MEM_MAPPED`, `MEM_IMAGE`, or other. These are commit-address-space categories, not resident-RAM categories, and must not replace the process sampler's working-set/private-working-set measurements.

Raw artifact: `benchmarks/raw/track-b-virtual-memory-types-current-20261006.json`.

In the later snapshot used for the current raw artifact, the renderer had 119.30 MiB of writable private committed memory across 1,140 regions. Sixteen writable regions were larger than 1 MiB, and the largest was 15.50 MiB. This is a region-shape observation from one point in time, not a leak diagnosis.

## Per-process result

| Role | Process private bytes | Private committed | Private writable | Private executable | Mapped committed | Image committed |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Renderer | 120.42 MiB | 112.44 MiB | 110.86 MiB | 1.88 MiB | 251.96 MiB | 369.80 MiB |
| Browser/utility | 42.44 MiB | 31.04 MiB | 30.57 MiB | 0.00 MiB | 279.89 MiB | 474.81 MiB |
| GPU process | 58.39 MiB | 23.52 MiB | 23.12 MiB | 0.01 MiB | 199.34 MiB | 599.84 MiB |
| Network service | 13.21 MiB | 7.00 MiB | 6.80 MiB | 0.00 MiB | 231.45 MiB | 375.69 MiB |
| Storage service | 7.58 MiB | 1.97 MiB | 1.88 MiB | 0.00 MiB | 227.55 MiB | 365.18 MiB |
| Crashpad handler | 2.95 MiB | 1.11 MiB | 1.01 MiB | 0.00 MiB | 179.55 MiB | 33.77 MiB |
| Native shell | 12.07 MiB | 7.84 MiB | 7.81 MiB | 0.01 MiB | 268.76 MiB | 115.28 MiB |

## Interpretation

The renderer's process private bytes are close to its committed `MEM_PRIVATE` regions, and roughly 110.86 MiB of that committed private space is writable while only 1.88 MiB is executable. This makes JIT code an unlikely explanation for most of the private remainder; writable allocator/runtime state is the larger category. It still does not identify JavaScript, Blink, decoded media, WebRTC, or GPU ownership, and the snapshot does not prove that committed private pages are resident.

No renderer setting, Chromium switch, memory trimming, or page instrumentation was changed. The next candidate still needs a foreground process-tree comparison and normal-function checks.
