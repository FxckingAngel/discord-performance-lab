# Track B current native memory breakdown

Date: 2026-10-06

This read-only snapshot was taken from the same authenticated root PID 28156 after the rooted WPR capture. It uses `VirtualQueryEx` and `QueryWorkingSetEx` for virtual-memory and resident-page classification. The resident values are per-process and are not cross-process physical-page deduplicated.

## Renderer PID 39048

- Working set: 395.81 MiB
- Private bytes: 360.30 MiB
- Private writable resident: 304.19 MiB
- Private executable resident: 0.02 MiB
- Other private resident: 0.94 MiB
- Committed private writable: 348.52 MiB
- Committed mapped: 384.24 MiB
- Committed image: 369.62 MiB
- Mapped resident: 16.46 MiB
- Image resident: 74.19 MiB
- Shared-flag resident pages: 88.26 MiB

The renderer's private writable resident pages are spread across 2,212 regions. The largest region bucket contains 61.15 MiB in two regions of 16 MiB or larger; 78.70 MiB is in 13 regions from 4–16 MiB. This is native/private resident allocation evidence, not a JavaScript-heap measurement.

## Complete-tree virtual snapshot

The renderer dominates committed private writable memory at 346.30 MiB. The GPU process has 135.28 MiB private bytes and 135.26 MiB committed private writable memory. The browser process has 48.12 MiB private bytes and 36.29 MiB committed private writable memory. These committed values are reported separately from resident memory and must not be substituted for the 250 MiB resident target.

## Decision

No generic WebView2 switch is selected from this snapshot. The evidence identifies the renderer's writable native allocation classes and region sizes, but not the owning Chromium subsystem. The next safe step is feature-isolated renderer captures with the same classification, correlated with CDP V8/DOM/media metrics where a diagnostic port is available. Any renderer change should wait for a feature-dependent delta rather than target a broad memory class blindly.
