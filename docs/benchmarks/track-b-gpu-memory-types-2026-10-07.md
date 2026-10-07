# Track B GPU-process memory classification

Date: 2026-10-07  
GPU PID: 28660  
Source: `artifacts/track-b-normal-gpu-memory-types-20261007.json`

This is a read-only classification of the live Track B GPU process. Hardware acceleration remained enabled and no Chromium flags or media settings were changed.

| Category | Amount |
| --- | ---: |
| Total classified resident | 65.71 MiB |
| Private-writable resident | 26.19 MiB |
| Private-executable resident | 0.01 MiB |
| Other private resident | 0.09 MiB |
| Image resident | 36.18 MiB |
| Mapped resident | 3.24 MiB |
| Committed private-writable | 57.34 MiB |

No allocation-base family reached 16 MiB resident in the GPU process. The largest individual families were below 2 MiB resident. This separates the GPU process from the renderer's two dominant anonymous families, which together account for more than 100 MiB of renderer private-writable residency.

The result does not prove that GPU textures or shared graphics allocations are cheap overall, because shared pages can be mapped across processes. It does show that the next renderer experiment should not disable hardware acceleration or target the GPU process blindly.

