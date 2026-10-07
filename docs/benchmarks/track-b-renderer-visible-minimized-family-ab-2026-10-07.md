# Track B renderer visible versus minimized allocation-family A/B

Date: 2026-10-07  
Renderer PID: 43892  
Capture files:

- `artifacts/track-b-normal-renderer-memory-types-20261007.json`
- `artifacts/track-b-normal-renderer-memory-types-minimized-20261007.json`

This was a reversible read-only diagnostic. Track B was minimized for 15 seconds, the renderer map was captured, and the window was restored. Official Discord was not touched. No working-set trimming, garbage collection, Chromium flag, media setting, or feature switch was used.

## Allocation-family change

| Allocation base | Visible resident | Minimized resident | Delta |
| --- | ---: | ---: | ---: |
| `0x3C000000000` | 67.56 MiB | 46.72 MiB | -20.84 MiB |
| `0x410C00000000` | 58.66 MiB | 26.50 MiB | -32.16 MiB |

The two families together contracted by approximately 53.0 MiB when the window was minimized. The renderer's private-writable resident total fell from 255.50 MiB to 222.07 MiB, a reduction of approximately 33.4 MiB. The resident bucket for regions at least 16 MiB fell from 81.48 MiB to 0.57 MiB.

## Interpretation

The result makes visible/compositor-dependent residency a stronger hypothesis for these families. It does not prove that they are compositor surfaces, raster caches, or a specific Chromium allocator. Minimization can also change operating-system residency decisions, so it cannot be counted as reclaimable production memory.

The correct next experiment is a visible-state differential: compare static text, media-heavy content, and a returned static route while the window remains visible. Any optimization must release genuinely inactive resources without changing visible media quality or normal Discord behavior.

The window was restored after the capture and remained responsive.

