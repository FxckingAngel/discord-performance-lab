# Track B current CDP and native attribution

Date: 2026-10-07

This was a controlled diagnostic-only restart using a loopback CDP endpoint. The normal shell was closed through its normal window path and restored afterward. The account route and workload were not independently verified, so this is not an acceptance benchmark.

## Process-tree observation

- Diagnostic settle: 60 seconds
- Attribution capture: 30 seconds
- Samples: 7
- Process count: 8
- Private working set: 416.69 MiB median, 419.18 MiB p95
- Private bytes: 556.15 MiB median, 654.96 MiB p95
- CPU: 0.15% median, 0.47% p95

Final private working-set leaders were the renderer at 303.74 MiB, GPU process at 45.01 MiB, browser at 40.13 MiB, and native shell at 9.17 MiB.

## CDP renderer data

- V8 used heap: 102.45 MiB
- V8 total heap: 106.85 MiB
- Embedder heap: 26.38 MiB
- Backing storage: 22.63 MiB
- Documents/frames: 14 / 14
- DOM nodes: 6,143 from performance metrics; 4,731 from the document aggregate
- JavaScript event listeners: 2,224
- Layout objects: 3,776
- Image elements: 151, approximately 2.82 million natural pixels
- Video elements: 3, approximately 0.29 million video pixels
- Canvas elements: 4, approximately 0.12 million canvas pixels
- WebRTC peer connections: 0
- Detached script states: 0

The renderer's live V8 heap is substantial, but it does not account for the full approximately 304 MiB private working set. The result supports the current conclusion that non-V8 renderer memory remains a major part of the gap.

## Native sampling limits

Renderer allocation sampling was available, but the diagnostic sampled only 574,832 bytes of V8 allocation data and 1,802,240 attributed bytes from the Chromium-native sampling window. Those samples are far smaller than the renderer's resident footprint and therefore cannot be treated as a complete native-memory account. Browser-target sampling was unavailable because the browser target did not expose `Memory.startSampling`.

## Per-process resident classification

| Role | Resident | Private writable resident | Mapped resident | Image resident | Committed private |
| --- | ---: | ---: | ---: | ---: | ---: |
| Renderer | 410.34 MiB | 300.68 MiB | 30.06 MiB | 78.51 MiB | 333.50 MiB |
| GPU | 108.03 MiB | 38.62 MiB | 5.92 MiB | 63.26 MiB | 156.73 MiB |
| Browser | 146.48 MiB | 35.54 MiB | 9.40 MiB | 101.27 MiB | 38.32 MiB |
| Native shell | 60.77 MiB | 6.88 MiB | 13.36 MiB | 40.51 MiB | 7.86 MiB |
| Network service | 50.46 MiB | 8.34 MiB | 3.72 MiB | 38.28 MiB | 9.00 MiB |
| Audio service | 28.12 MiB | 1.70 MiB | 1.71 MiB | 24.63 MiB | 2.02 MiB |
| Storage service | 23.73 MiB | 1.78 MiB | 1.64 MiB | 20.25 MiB | 2.00 MiB |
| Crashpad | 16.38 MiB | 0.91 MiB | 0.91 MiB | 14.49 MiB | 1.15 MiB |

## Decision

No renderer or GPU optimization is applied from this capture. The evidence narrows the next investigation to Blink/DOM state, decoded media and compositor/native allocations, while keeping V8 as a separate measured category. Heap snapshots were not taken or published, and no authentication, network, protocol, or security behavior was changed.

Raw data is in `artifacts/track-b-current-cdp-native-20261007/`.
