# Track B complete-tree resident memory types

Date: 2026-10-06

## Scope

This is a read-only `VirtualQueryEx` plus `QueryWorkingSetEx` classification across the eight processes present in the live Track B tree. It is an instantaneous diagnostic, not a settled acceptance benchmark. Resident-page categories are per-process and are not cross-process physical-page deduplication.

Raw outputs are under `artifacts/track-b-resident-memory-tree-20261006/`.

## Complete-tree classification

| Role | Resident | Private writable | Private executable | Mapped | Image-backed |
|---|---:|---:|---:|---:|---:|
| Renderer | 418.89 MiB | 311.32 MiB | 0.02 MiB | 30.31 MiB | 76.17 MiB |
| Browser | 144.62 MiB | 33.89 MiB | 0 MiB | 9.39 MiB | 101.09 MiB |
| GPU process | 110.35 MiB | 39.70 MiB | 0.01 MiB | 6.01 MiB | 64.41 MiB |
| Native shell | 56.16 MiB | 5.62 MiB | 0 MiB | 11.86 MiB | 38.65 MiB |
| Network service | 50.26 MiB | 8.09 MiB | 0 MiB | 3.73 MiB | 38.32 MiB |
| Audio/utility | 28.01 MiB | 1.59 MiB | 0 MiB | 1.71 MiB | 24.63 MiB |
| Storage service | 24.14 MiB | 2.05 MiB | 0 MiB | 1.65 MiB | 20.39 MiB |
| Crashpad | 16.37 MiB | 0.90 MiB | 0 MiB | 0.91 MiB | 14.49 MiB |
| **Total** | **848.80 MiB** | **403.16 MiB** | **0.03 MiB** | **65.57 MiB** | **378.15 MiB** |

The browser and utility labels follow the local command-line role classifier. The raw artifacts preserve the PID mapping locally; command lines are not published in this document.

## Interpretation

Private writable resident pages are the dominant complete-tree category, with the renderer contributing about 77% of the private-writable total. Private executable pages are negligible. This rules out code/JIT reduction as the main path to the target and confirms that reducing only the native shell or GPU process cannot produce the required approximately 150 MiB reduction.

The private-writable category is still an accounting boundary, not a safe deletion target. It includes V8 backing stores, Blink and DOM state, decoded resources, compositor buffers, and Chromium-native allocator pages. The next optimization candidate must identify one of those subcategories and pass a functional regression check.
