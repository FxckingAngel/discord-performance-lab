# Track B native module attribution

Date: 2026-10-06

## Scope

This is an unverified-route-and-workload diagnostic capture of the authenticated no-bridge probe. It is attribution evidence, not an acceptance benchmark. The diagnostic shell was closed and the normal shell was restored after capture.

Raw output is kept under `artifacts/track-b-cdp-module-current-20261006/` and is not a public artifact. The CDP report contains only aggregate diagnostic fields for native samples. It does not publish addresses, raw stacks, cookies, tokens, page text, or heap objects.

## Capture

| Field | Value |
|---|---:|
| CDP sampling window | 20 seconds |
| Process measurement window | 30.55 seconds |
| Display | 1920 x 1080 at 60 Hz |
| Initial process count | 9, including a transient video-capture service |
| Settled process count | 8 |
| Renderer PID | 21252 |

The process tree was still settling during this short probe. The renderer private working set fell from 510.40 MiB in the first sample to 379.10 MiB in the final sample. The complete-tree private working-set sums fell from 631.81 MiB to 494.65 MiB. These values must not replace the existing 600-second observations.

## Native sampling result

| Result | Sampled bytes | Samples |
|---|---:|---:|
| Chromium-native category | 30.86 MiB | 821 |
| GPU-graphics category | 480 bytes | 3 |
| All sampled native allocations | 30.86 MiB | 824 |
| Attributed total reported by the profile | 47.44 MiB | n/a |

Every sampled allocation mapped to the sanitized module label `msedge.dll.pdb`. The label is the debugger/module name exposed by the local CDP profile, not a resident-memory category. It identifies that the sampled native signal is inside the WebView2/Edge module, but it does not identify which allocator subsystem owns the renderer's private working set.

The browser-level native sampling profile returned no samples for this window. This does not prove that the browser process has no native allocations; it means that this diagnostic endpoint did not expose a browser profile for the capture.

## Process attribution

The per-PID capture preserved the following private working-set medians across its five samples:

| Role | PID | Median private working set |
|---|---:|---:|
| Renderer | 21252 | 474.45 MiB |
| GPU process | 32628 | 43.98 MiB |
| Browser | 38296 | 45.64 MiB |
| Native shell | 31288 | 8.25 MiB |
| Network service | 38448 | 10.80 MiB |
| Audio service | 2896 | 3.35 MiB |
| Storage service | 24760 | 3.22 MiB |
| Crashpad | 38424 | 1.59 MiB |

The renderer remains the dominant private-resident target. No renderer optimization was enabled by this capture.

## Interpretation and next step

The module aggregation removes raw address and path data while establishing that the sampled native allocation signal is overwhelmingly WebView2/Edge-native rather than GPU-classified. Because sampled allocation bytes are not resident bytes, they cannot be subtracted directly from the approximately 302 MiB renderer private-working-set baseline.

The next useful attribution step is to correlate this native sample with V8 used/total heap, DOM counters, and repeated settled per-PID measurements. No memory-reducing switch is approved from this result alone.
