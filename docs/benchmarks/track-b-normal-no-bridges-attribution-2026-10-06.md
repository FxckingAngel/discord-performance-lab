# Track B loaded frontend attribution after bridge isolation

Date: 2026-10-06

This run measures the rebuilt normal shell after removing the incomplete `DiscordNative` object from the production path. The change was required because the partial object left Discord's application root empty. The authenticated profile was retained.

## Settled process-tree result

The 10-minute run used 20 samples at 30-second intervals and counted the shell plus all WebView2 descendants.

| Metric | Median | p95 |
| --- | ---: | ---: |
| Total working set | 856.22 MiB | 900.11 MiB |
| Private working set | 433.84 MiB | 482.82 MiB |
| Private bytes / commit | 706.18 MiB | 763.75 MiB |
| Total CPU | 0.226% | 0.226% |

The tree contained eight processes and one renderer. The renderer accounted for 379.31 MiB median private bytes and the GPU process for 212.33 MiB. The browser process accounted for 52.89 MiB, the network service 15.08 MiB, the audio service 8.00 MiB, the storage service 8.64 MiB, the crash handler 2.98 MiB, and the native shell 12.15 MiB.

## Page-level attribution

A 60-second CDP diagnostic against the same authenticated profile reported:

- V8 heap used: 124,398,420 bytes, about 118.6 MiB.
- V8 heap capacity: 216,256,512 bytes, about 206.3 MiB.
- 6,312 DOM nodes, 12 documents, and 12 frames.
- 0.8985 seconds of page task time over the window.
- 0.3226 seconds of script time.
- 0.0288 seconds of layout time.
- 0.0191 seconds of style-recalculation time.

The page was visibly mounted in the no-bridge diagnostic mode. The low task, script, layout, and style totals do not support an always-running JavaScript or layout loop as the main idle CPU cause. The process measurements show that most of the private-memory gap above the V8 heap is in renderer-native, GPU, WebView2, and frontend-managed native allocations.

## Interpretation

Bridge isolation restored frontend functionality but did not approach the Track B target. The current loaded shell is a valid resource baseline, not an acceptance pass: both private working-set p95 and private-bytes median/p95 exceed the approximately 250 MiB goal.

This result also separates two problems. The incomplete desktop bridge was a correctness failure and is now excluded from the normal path. The remaining memory gap is primarily in the Discord frontend and Chromium/GPU runtime, so a useful optimization must reduce those allocations without hiding the page, trimming its working set, disabling hardware acceleration, or removing normal Discord features.

## Inputs

- `benchmarks/raw/track-b-normal-no-bridges-settled-10min-summary-20261006.json`
- `benchmarks/raw/track-b-current-no-bridges-memory-20261006.json`
- `benchmarks/raw/track-b-current-no-bridges-performance-60s-20261006.json`
