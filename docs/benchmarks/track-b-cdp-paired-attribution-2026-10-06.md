# Track B paired CDP and process attribution

Date: 2026-10-06

This diagnostic launch used the isolated unauthenticated `--diagnostic-discord` profile. It is not a logged-in acceptance benchmark and does not represent a normal account, channel, or media workload. The rooted process sampler and localhost CDP diagnostic were run against the same launch after an 8-second settle period. Raw process and CDP files remain private under `benchmarks/raw/track-b/`.

At the final 30-second process-tree sample:

| Role | Working set | Private working set | Private bytes | CPU seconds |
| --- | ---: | ---: | ---: | ---: |
| Renderer | 257.9 MiB | 168.9 MiB | 187.5 MiB | 2.27 |
| GPU process | 89.5 MiB | 34.4 MiB | 83.8 MiB | 0.78 |
| WebView2 browser | 56.9 MiB | 38.6 MiB | 48.0 MiB | 1.36 |
| Network service | 47.5 MiB | 9.2 MiB | 14.3 MiB | 0.67 |
| Storage service | 19.7 MiB | 2.9 MiB | 7.5 MiB | 0.05 |
| Audio service | 23.6 MiB | 3.1 MiB | 7.8 MiB | 0.03 |
| Crashpad | 19.8 MiB | 2.1 MiB | 3.4 MiB | 0.05 |

The full tree ended at approximately 661.9 MiB working set and 364.1 MiB private bytes across eight processes. The CDP diagnostic reported 54.68 MiB V8 heap used, 53.7 MiB V8 heap capacity, 12.45 MiB embedder heap, and 19.35 MiB backing storage. It reported 1,174 DOM nodes, 12 frames, 695 JavaScript event listeners, 684 layout objects, 3 image elements, 0 video elements, 2 canvas elements, and 0 active RTCPeerConnections.

The renderer therefore retains at least roughly 133 MiB of private bytes beyond the measured V8 heap used. That is a lower bound, not a complete attribution: Blink/DOM, native Chromium allocations, decoded resources, GPU/shared buffers, and other process state may all be included. The current state has no evidence that this residual is removable without a workload-specific experiment.

The 20-second allocation-sampling result contained one sample and about 35 KiB of sampled data, so it is insufficient for allocation ranking. It must not be used to claim that the native residual is JavaScript memory.
