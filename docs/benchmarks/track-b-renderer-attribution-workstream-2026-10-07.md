# Track B renderer attribution workstream

Date: 2026-10-07

This is a read-only synthesis of existing sanitized Track B artifacts. It does
not change the shell, renderer, WebView2 settings, Discord behavior, or the
250 MiB complete-tree private-resident target.

## Current evidence

| Source | Tree private WS | Renderer private WS | Renderer V8 used | Important limitation |
| --- | ---: | ---: | ---: | --- |
| Canonical authenticated baseline, five repetitions | median 386.53 MiB; p95 499.17 MiB | per-repeat 292.13–369.91 MiB | not paired | Same renderer PID was retained, but the 119.28 MiB tree range means small changes are not credible yet. |
| Authenticated lifecycle, settled at 10 minutes | 377.13 MiB | 276.12 MiB | 90.36 MiB | Route was not manually confirmed; diagnostic only. |
| Current long attribution | 393.47 MiB median; p95 423.96 MiB | 279.71 MiB median; p95 316.78 MiB | 98.04 MiB | CDP and Windows renderer identity were joined through contemporaneous WebView2 process inventory. |
| Blank versus authenticated resident classification | not a same-state acceptance comparison | private-writable delta +318.53 MiB | not paired | Different captures and process counts; boundary evidence only. |

The settled renderer therefore has approximately 181.6–185.8 MiB of private
resident memory outside the measured V8-used value in the two lifecycle
samples. This is a lower-bound remainder, not a byte-perfect ownership split,
because V8 backing storage, Blink embedder memory, and graphics resources can
cross the diagnostic boundaries.

The current long attribution also reports approximately 37.36 MiB renderer-
adjacent GPU private WS, 41.16 MiB browser private WS, and 9.82 MiB native
shell private WS. The renderer remains the dominant private-resident owner.

## Lifecycle finding

The existing lifecycle report is the strongest attribution result so far:

| Checkpoint | Tree private WS | Renderer private WS | V8 used | Renderer private WS outside V8 |
| --- | ---: | ---: | ---: | ---: |
| Blank | 94.97 MiB | 9.76 MiB | 0.50 MiB | 9.26 MiB |
| Navigation | 627.89 MiB | 514.03 MiB | 56.56 MiB | 457.47 MiB |
| Application shell | 430.96 MiB | 326.84 MiB | 149.68 MiB | 177.16 MiB |
| Canonical route | 402.98 MiB | 298.39 MiB | 98.67 MiB | 199.72 MiB |
| Settled 10 minutes | 377.13 MiB | 276.12 MiB | 90.36 MiB | 185.76 MiB |

The largest allocation-base family reached 220.88 MiB during navigation, then
fell to 53.10 MiB at application-shell creation and 67.45 MiB at ten minutes.
The second family was 52.19 MiB during navigation and 33.54 MiB at ten minutes.
The third stabilized at 17.75 MiB after shell creation. The three largest
families still totaled 118.74 MiB at ten minutes, but family identity is only
valid within that capture and does not identify an allocator or owner.

This rules out treating the largest family as a fixed blank-WebView2 floor. It
also does not prove that the retained families are media, Blink, compositor,
WebRTC, or Discord application state.

## What the current tools do not explain

- The decoded WPR HeapSnapshot contains 18 outstanding allocations totaling
  0.009088 MiB. It is not a reconciliation of the renderer's retained heap.
- The five-second VirtualAllocation traces observe new allocations during the
  trace window, not the retained pages acquired earlier.
- The large anonymous allocation-base families do not overlap loaded module
  ranges, but that only makes them anonymous/private candidates. It does not
  prove PartitionAlloc, Skia, Blink, compositor, or Discord ownership.
- Existing media/CDP captures are single-state or unmatched. They cannot
  establish a media-dependent delta.

## Next concrete attribution experiment

Use one Track B diagnostic launch and preserve one renderer PID throughout:

1. Manually confirm the exact canonical static route. Capture process-tree
   metrics, renderer and GPU private working set, per-PID resident classes,
   allocation-base groups, and aggregate CDP counters.
2. Require six consecutive five-second samples with unchanged PID/process set,
   window state, and no more than 1% peak-to-peak variation in renderer and GPU
   private WS before recording the static measurement window.
3. Manually navigate to the media-heavy channel. Keep visible GIFs, stickers,
   images, or embeds visible. Do not disable, pause, hide, trim, or force-GC
   anything. Wait for the same stable-state rule, then repeat every capture.
4. Return to the exact canonical static route. Apply the same stable-state rule
   and repeat the capture.
5. Compare per-PID deltas and rank the allocation-base families only within
   this single renderer lifecycle. Preserve the renderer and GPU PID/lifetime,
   DOM/frame/image/video/canvas counts, V8 used/backing storage, private WS,
   private bytes, GPU private WS, and process count beside each state.

A family is a candidate only if it grows with visible media, contracts after
returning to static content, and has an owner supported by CDP/WPR or another
read-only attribution source. A renderer/GPU change without matching media
counter and family evidence is not enough to change production behavior.

The existing `Invoke-TrackBAuthenticatedMediaLifecycle.ps1` already enforces
the same renderer PID across canonical-static, media-heavy, and returned-static
checkpoints. Its current capture contract should be run with the stable-settle
gate above before accepting its results as an optimization baseline.

## Decision

No renderer optimization is justified by the current evidence. The next
measurement is a same-lifecycle, stable static-to-media-to-static comparison.
The Track B target remains approximately 250 MiB complete-tree private resident
RAM and approximately 0.2% median settled-idle CPU.
