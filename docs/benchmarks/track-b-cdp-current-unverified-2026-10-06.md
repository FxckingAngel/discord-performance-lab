# Track B current authenticated CDP attribution

The new `Invoke-TrackBUnverifiedCurrentAttribution.ps1` workflow closed the normal shell, launched the isolated authenticated-no-bridges diagnostic, collected 30 seconds of local CDP and process-tree data, and restored the normal shell. It does not log in, navigate, or claim a route or workload. The result is therefore unverified diagnostic evidence.

| Metric | Median | P95 |
| --- | ---: | ---: |
| Complete-tree private working set | 622.83 MiB | 653.57 MiB |
| Complete-tree private bytes | 838.99 MiB | 894.10 MiB |
| Renderer private working set | 504.63 MiB | 534.27 MiB |
| Renderer private bytes | 556.45 MiB | not summarized |

CDP reported 66.83 MiB V8 used heap and 90.30 MiB total heap, 1,155 DOM nodes, one image, one video, and two canvases. Heap sampling collected 1,278 samples totaling 41.26 MiB of sampled self allocations. Native allocation sampling returned no samples in this window.

The renderer's private working set exceeded measured V8 used heap by roughly 438 MiB in this run. This is evidence that the renderer residual includes substantial non-V8 allocation, but it does not identify whether the bytes are Blink, decoded media, compositor resources, WebRTC, or other Chromium-native allocations. No optimization was selected from this result.

Raw process and CDP artifacts remain under `artifacts/` and are private.
