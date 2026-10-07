# Track B authenticated frontend delta refresh

Date: 2026-10-06

Artifact directory: `artifacts/track-b-release-auth-delta-refresh-9230-20261006/`

The rebuilt Release shell was launched with `--diagnostic-authenticated-no-bridges`, settled for 15 seconds, and measured for 20 seconds. The route and workload remain unverified, so this is attribution evidence rather than an acceptance benchmark.

## Process-tree result

| Metric | Median | P95 |
| --- | ---: | ---: |
| Summed working set | 1,022.59 MiB | 1,023.40 MiB |
| Private working set | 608.82 MiB | 611.36 MiB |
| Private bytes | 778.18 MiB | 795.54 MiB |

The renderer's final process-reported private working set was 341.91 MiB. The per-PID resident classification measured 438.0 MiB resident and 332.3 MiB private-writable resident for the renderer. No private-writable renderer pages were marked shared in that classification.

## Chromium diagnostics

The diagnostic aggregate reported:

- V8 used heap: 117.3 MiB
- V8 total heap: 206.3 MiB
- DOM nodes: 6,188
- Documents: 15
- Frames: 14 in the performance metrics, with 2 associated active renderer frames in the WebView2 process sidecar
- JavaScript event listeners: 2,353
- Layout objects: 3,777
- Image elements: 156
- Natural image pixels: 2,383,584
- Video elements: 3
- Canvas elements: 4
- RTCPeerConnections: 0

The renderer therefore has roughly 215 MiB of private-writable resident memory beyond the measured live V8 heap in this capture. That remainder is not automatically JavaScript memory. It may include Blink state, decoded resources, compositor/raster allocations, WebView2 native allocations, and Discord's application state. The capture does not justify a renderer change by itself.

## Comparison with the blank floor

The repeated blank Release floor had a private-working-set median of 74.05 MiB and private-bytes median of 145.64 MiB. The authenticated capture's corresponding medians were 608.82 MiB and 778.18 MiB. The loaded frontend is therefore the dominant memory cost in this shell, with a much larger delta than the blank WebView2 runtime floor.

The next safe optimization gate remains feature-scenario attribution. No memory trimming, forced garbage collection, security change, protocol change, or functionality reduction was used in this capture.
