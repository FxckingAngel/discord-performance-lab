# Track B parallel-phase current attribution: 2026-10-07

Status: diagnostic evidence only. This capture used Track B's authenticated no-bridge diagnostic path. The Discord account, route, and visible workload were not manually confirmed after the diagnostic restart, so this is not an acceptance benchmark and is not evidence of a production optimization.

The active official Discord installation was not restarted, stopped, modified, or included in the capture.

## Capture contract

- Shell: current Track B build
- Diagnostic mode: authenticated no-bridge
- CDP: loopback only, diagnostic port 9230
- Settle: 60 seconds
- Observation: 60 seconds, 13 process-tree samples
- Process count: 8 in every captured sample
- Resident attribution: per-process VirtualQueryEx and working-set classification; shared physical pages are not deduplicated across processes
- Raw CDP and resident-type files: private under `artifacts/`

## Process-tree result

| Metric | Median | P95 |
| --- | ---: | ---: |
| Complete-tree private working set | 233.97 MiB | 256.65 MiB |
| Complete-tree working set | 348.11 MiB | 389.80 MiB |
| Renderer private working set | 183.82 MiB | 191.57 MiB |
| GPU private working set | 14.92 MiB | 26.19 MiB |

The private-resident series increased from 210.91 MiB to 256.65 MiB during the capture. That direction is consistent with the earlier state-dependent residency behavior and is not a stable proof that the normal authenticated Track B workload fits the target.

## CDP aggregate result

- V8 used heap: 102,129,184 bytes, approximately 97.39 MiB
- V8 total heap: 105,492,480 bytes, approximately 100.61 MiB
- V8 backing storage: 23,719,326 bytes, approximately 22.62 MiB
- Documents: 10
- Frames: 10 in the performance metrics, 2 in the document aggregate
- DOM nodes: 5,213 in the performance metrics, 4,317 in the document aggregate
- JavaScript event listeners: 1,441
- Layout objects: 3,301
- Image elements: 119
- Natural image pixels: 2,187,136
- Video elements: 0
- Playing video: 0
- RTCPeerConnections: 0
- Worker globals: 2
- Detached script states: 0

The renderer's median private working set exceeded the reported V8 used heap by approximately 86.43 MiB before accounting for mapped/image pages, compositor resources, and other native allocations. This is a diagnostic remainder only. It must not be labeled Blink, Skia, media cache, or compositor memory without ownership evidence.

## Native sampling limits

The one-shot native sample attributed approximately 100.61 MiB to V8 with a shallow unknown-module frame. The bounded allocation-sampling window captured 39 samples totaling about 0.76 MiB, grouped as Chromium-native and mapped to `msedge.dll.pdb`. This window is useful for proving that sampling is available, but it does not census the renderer's retained private working set. The browser-process native sampling endpoint was unavailable.

## Interpretation and next action

This run does not justify changing renderer behavior. It strengthens the lifecycle/residency hypothesis: the same shell can occupy a lower private-resident band while its committed/private state remains much larger, and the footprint can rise during observation. The next measurement should pair this capture with a fixed, manually confirmed route and record the renderer PID, CDP target PID, process lifetime, and allocation-base groups at each lifecycle checkpoint. Any optimization must wait for a repeatable, fully initialized workload and an attribution-backed owner.
