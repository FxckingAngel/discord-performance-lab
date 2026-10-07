# Track B paired renderer memory ledger

Date: 2026-10-07

This ledger joins the paired authenticated renderer resident classification
with its private CDP diagnostic summary. The raw snapshot and per-PID files
remain local.

## Paired measurements

Renderer PID: 38668

| Category | Measured |
| --- | ---: |
| Renderer working set | 433.18 MiB |
| Private-writable resident | 321.62 MiB |
| Private executable resident | 0.02 MiB |
| Private other resident | 1.06 MiB |
| Mapped resident | 30.03 MiB |
| Image resident | 79.34 MiB |
| V8 used heap | 101.19 MiB |
| V8 backing storage | 22.43 MiB |

Subtracting V8 used heap from the private-writable resident produces a
non-V8 lower-bound remainder of approximately 220.43 MiB. This is not a
perfect partition: V8 backing storage, native embedder memory, Blink objects,
and graphics resources can cross the diagnostic boundaries.

## What this rules out

The renderer’s resident footprint cannot be explained by V8 used heap alone.
Image and mapped pages are visible but do not account for all private-writable
resident memory. The native CDP sampling window is also too small to account
for the remainder.

## Next attribution boundary

The remaining work is feature-isolated paired capture of the same renderer
under blank, static text, media, voice, video, and minimized states. Each state
must preserve the per-PID resident classification and CDP counters before any
renderer or media change is implemented.
