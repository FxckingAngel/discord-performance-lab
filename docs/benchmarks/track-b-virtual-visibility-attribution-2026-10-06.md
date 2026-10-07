# Track B virtual-memory visibility attribution

Date: 2026-10-06  
Build: current `Verified` production shell  
Root PID: 39764  
Method: read-only `VirtualQueryEx` classification of committed regions for the complete Track B process tree

## Scope

The initial pair was a controlled foreground/minimized capture on the same authenticated shell process. The window was minimized for about 30 seconds, the minimized snapshot was captured, and the window was restored. The process remained responsive. No production binary or Discord content was changed.

Three additional foreground/minimized repetitions were captured after the shell had settled. Each minimized capture used about 22 seconds of minimized state and the process was restored afterward. These repetitions are the stronger evidence for a stable visibility effect.

The classifier reports virtual committed-region categories. `privateBytes` and `privateWritableCommittedBytes` are commit/accounting values, not a replacement for resident working-set measurements. They cannot by themselves identify JavaScript, Blink, media, WebRTC, or GPU allocations.

Raw captures, kept local/private:

- [foreground capture](../../benchmarks/raw/track-b-virtual-foreground-20261006.json)
- [minimized capture](../../benchmarks/raw/track-b-virtual-minimized-20261006.json)
- repeat captures are local/private under `benchmarks/raw/track-b-virtual-visibility-repeat{1,2,3}-{foreground,minimized}-20261006.json`

## Renderer result

| Metric | Foreground | Minimized | Change |
|---|---:|---:|---:|
| Private bytes | 132.04 MiB | 108.13 MiB | -23.91 MiB |
| Private writable committed | 119.80 MiB | 95.90 MiB | -23.90 MiB |
| Writable private regions | 1,142 | 947 | -195 |
| Regions above 1 MiB | 15 | 14 | -1 |
| Largest writable region | 17.25 MiB | 17.25 MiB | unchanged |

The renderer is the only process with a material change in this pair. The result is consistent with foreground rendering or related renderer activity retaining roughly 24 MiB of private committed memory. It does not show that one large allocation is responsible: the largest writable region stayed at 17.25 MiB, while the number of writable regions fell by 195.

## Repeated settled visibility check

| Repeat | Foreground renderer private | Minimized renderer private | Change | Writable committed change |
|---:|---:|---:|---:|---:|
| 1 | 108.50 MiB | 108.14 MiB | -0.36 MiB | -0.36 MiB |
| 2 | 108.17 MiB | 108.14 MiB | -0.03 MiB | -0.03 MiB |
| 3 | 108.14 MiB | 108.14 MiB | 0.00 MiB | 0.00 MiB |

The repeated settled captures do not reproduce the initial 23.91 MiB drop. The earlier pair therefore represents transient settling or allocation timing, not a stable minimized-state saving. The largest writable region remained 17.25 MiB in every repeated renderer capture.

## Other roles

The native shell changed from 12.24 MiB to 12.16 MiB of private bytes, and from 7.99 MiB to 7.91 MiB of private writable committed memory. The other process roles did not produce a comparable change in the captured pair. Their raw per-process values remain in the captures above.

## Interpretation

The initial pair was useful for finding a visibility-related lead, but the repetitions show no stable memory saving once the renderer is settled. This is not enough evidence to implement a renderer optimization or to claim that minimizing is a valid idle optimization. Minimized state is not the required settled-idle acceptance state, and the user-facing application must remain responsive and fully functional while visible.

The result also reinforces the existing allocation gate: do not add forced garbage collection, working-set trimming, hardware-acceleration changes, unmeasured Chromium flags, or page-level UI changes until a specific removable renderer-owned workload is identified.

Next diagnostic step: repeat this attribution over multiple settled foreground/minimized repetitions while preserving ordinary resident/private working-set measurements, then correlate the renderer changes with CDP task, animation, compositor, and media observations. Keep the complete-app 250 MiB private-memory and 0.2% idle-CPU targets unchanged.
