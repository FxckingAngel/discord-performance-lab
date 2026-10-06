# Track B virtual-memory region classification: 2026-10-06

Status: read-only live diagnostic. The route and workload were not independently verified. Values describe the shell state at one instant and are not a settled acceptance benchmark.

Source: `artifacts/track-b-vm-types-current-20261006.json`

The collector uses `VirtualQueryEx` to classify committed regions as private, mapped, or image-backed and to classify private regions by page protection. These classifications describe virtual-memory commitment. They do not prove which pages are resident or uniquely attributable to the application.

## Per-process classification

| Role | Working set | Private bytes | Private committed | Writable private | Executable private | Mapped committed | Image committed |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Renderer | 461.38 MiB | 402.75 MiB | 390.52 MiB | 388.18 MiB | 10.41 MiB | 372.23 MiB | 369.62 MiB |
| GPU process | 104.94 MiB | 190.39 MiB | 155.00 MiB | 154.58 MiB | 0.01 MiB | 206.11 MiB | 607.00 MiB |
| Browser/utility | 148.70 MiB | 54.09 MiB | 42.46 MiB | 41.96 MiB | 0 MiB | 272.32 MiB | 475.85 MiB |
| Network service | 50.96 MiB | 16.04 MiB | 9.77 MiB | 9.55 MiB | 0 MiB | 212.21 MiB | 375.07 MiB |
| Native shell | 54.06 MiB | 11.31 MiB | 7.18 MiB | 7.15 MiB | 0.01 MiB | 248.70 MiB | 109.90 MiB |

The remaining storage, utility, and crashpad processes were also preserved in the raw per-PID artifact.

## Interpretation

The renderer's private virtual memory is predominantly writable rather than executable. This is consistent with application/runtime/native allocation pressure, but it does not distinguish V8 backing stores, Blink structures, decoded media, compositor allocations, or other Chromium-native buffers. It is therefore not a safe optimization target by itself.

The renderer remains the largest measured category. The next useful step is to join this classification with a settled per-PID capture and the aggregate CDP signals, then test only a category-specific, reversible candidate with functional checks.

No runtime setting, renderer behavior, security feature, or Discord protocol behavior was changed.
