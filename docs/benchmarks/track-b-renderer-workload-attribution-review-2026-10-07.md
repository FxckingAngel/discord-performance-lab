# Track B renderer workload-attribution review

Date: 2026-10-07

This is a read-only review of the existing lifecycle, resident-region, CDP, and media/GPU artifacts. No Discord process or renderer behavior was changed.

## Evidence that is reproducible

| Evidence | Result | What it supports | What it does not prove |
| --- | ---: | --- | --- |
| Blank versus loaded diagnostic | Loaded tree +346.97 MiB private WS; loaded renderer about +293 MiB over blank | Discord-created renderer state is the main target | It does not identify DOM, media, compositor, or allocator ownership |
| Renderer lifecycle family 1 | 220.88 MiB at navigation, 53.10 MiB at shell, 67.45 MiB at 10 minutes | A large allocation family is acquired during navigation and mostly released naturally | It is not a production leak or optimization target without owner and workload evidence |
| Renderer lifecycle family 2 | 52.19 MiB at navigation, 33.54 MiB at 10 minutes | A smaller family persists after load | It is not identified as Blink, media, GPU, or Discord state |
| Same-process short series | `0x39400000000` resident size 52.92, 60.94, 56.10 MiB | Short-term resident variation is real | Allocation-base identity does not identify ownership |
| Foreground versus minimized | Renderer private WS fell 16.44 MiB when minimized; GPU stayed flat | Some renderer state is visibility-dependent | Reproducing this by hiding or pausing the visible app would violate the functionality rule |

## Media and GPU evidence

The available media artifacts are single-state smoke captures, not a controlled transition pair. One capture reported 162 image elements, 3 video elements, 4 canvases, and no active RTCPeerConnections. Another reported a renderer at 541.26 MiB private working set and GPU at 42.22 MiB, but it has no matched static-channel sample with the same route, renderer lifetime, settle condition, and process identity. The CDP native sampling window represented about 1.0 MiB, which is far below the renderer resident total.

The WPR HeapSnapshot decoded 0.009 MiB of outstanding allocations, and the clean VirtualAllocation trace represented about 4.926 MiB of allocations observed during its five-second interval. Neither trace accounts for the retained renderer resident set. No allocation stack connects the large anonymous region groups to images, GIFs, Skia, compositor surfaces, WebRTC, Blink, or a Discord-owned cache.

## Decision

No workload-dependent allocation family is proven large enough and safe enough for a renderer A/B optimization. The strongest current lead is a visibility-dependent renderer allocation, but the only observed release occurs when the window is minimized. That is diagnostic evidence, not permission to hide the window, suspend visible rendering, trim memory, or disable media.

Do not change renderer behavior based on the anonymous allocation groups or the navigation family.

## Exact missing measurement

Capture a manually confirmed static text channel and a manually confirmed media-heavy channel from the same Track B diagnostic session or matched renderer lifecycle. For each state, hold the same window and display configuration, wait for the same fixed settle condition, and preserve:

- renderer and GPU PID/lifetime;
- private working set, private bytes, and allocation-base groups;
- image, GIF/animated-image, video, canvas, DOM, and frame counts;
- GPU private working set and GPU counters;
- decoded WPR allocation stacks, if the elevated capture is authorized and complete.

Then leave the media-heavy route, return to the static route, and repeat the region scan. A family becomes an optimization candidate only if it grows with visible media, contracts after leaving that route, and has an identified owner whose release does not change visible behavior.
