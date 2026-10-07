# Decision 0021: renderer-native memory is the active Track B gate

Date: 2026-10-07

## Evidence

The minimal native-host experiment reduced the blank-shell private bytes by only 2.77 MiB and increased blank-shell private working set by 5.37 MiB. Its authenticated repeat settled at 565.98 MiB private bytes and 372.79 MiB private working set over 616 seconds, so replacing the production WinForms host does not address the current gap.

The current production-shell rooted baseline is 412.94 MiB median private working set, with approximately 303 MiB in the renderer, 41.8 MiB in the GPU process, and 39.2 MiB in the browser process. Virtual-memory classification shows approximately 348.5 MiB of renderer committed private writable memory and 304.2 MiB private writable resident memory. The PID-filtered WPR trace also assigns 80.5% of Track B sampled-profile events to the renderer.

The matched blank-versus-loaded diagnostic comparison is more discriminating. Blank WebView2 measured 69.72 MiB private working set and 7.30 MiB renderer private writable resident. The loaded diagnostic measured 416.69 MiB private working set and approximately 300.7 MiB renderer private writable resident. The loaded delta is therefore approximately 347 MiB for the complete tree and approximately 293 MiB in the renderer. V8 used heap was approximately 102.45 MiB, leaving a large non-V8 renderer remainder.

The current non-elevated Phase 2 attribution measured 300.14 MiB renderer private working set, 0.084% median CPU, and 2,451 page faults per second at p95. A 30-second aggregate trace recorded 388 animation frames, 375 paints, 416 style/layout updates, and 263 timer fires in the loaded diagnostic state, while the blank shell recorded none of those selected activity classes. Minimizing reduced GPU memory but left the renderer near 310 MiB private working set, so visibility throttling is not a foreground memory solution. WPR remains useful for deeper ETW classification, but the most recent elevation attempt was canceled and produced no new ETL.

An extended reload diagnostic initially rose to approximately 559 MiB private working set, then settled to approximately 420 MiB after 120 seconds, with the renderer at 311 MiB. This is close to the prior loaded baseline and does not support a simple one-time cache buildup explanation.

## Decision

Keep the known-good production shell. Do not promote the minimal native host or add generic WebView2 flags. The active engineering gate is to identify a feature-dependent, renderer-owned allocation or workload that can be reduced while preserving normal Discord behavior.

The approximately 250 MiB target remains unchanged. If the renderer-native floor remains above the target after controlled static/media/voice/video isolation, evaluate a different safe rendering architecture rather than redefining the target.

## Verified long-settle update

The rebuilt Verified authenticated no-bridge diagnostic, after 120 seconds of settling, measured 416.68 MiB complete-tree private working set in its last-five median and 305.43 MiB in the renderer. The associated sanitized heap snapshot measured 171.37 MiB summed self-size, leaving a 145.02 MiB renderer resident boundary that is not explained by heap self-size alone. V8 used heap was 107.17 MiB in the long-settle run. These results reinforce the renderer-native gate but do not identify a removable allocation.

The immediate gate is now a manually confirmed static Discord route versus media-heavy route comparison. Do not implement renderer changes until that comparison identifies a removable allocation or workload. Keep the normal shell as the rollback baseline.

## Live-current refresh

The already-running Verified shell was sampled for 60 seconds without a
restart. It held eight processes and measured 380.79 MiB median complete-tree
private working set, 550.65 MiB private bytes, and 0.081% median CPU. The
single renderer accounted for 280.32 MiB private working set, while the GPU
process accounted for 41.18 MiB. The window stayed visible, unminimized, and
responsive at 1920x1080 and 60 Hz. This is a current live baseline, not a
manually authenticated same-route parity result. It leaves the renderer-first
gate unchanged and does not justify a CPU-focused change.
