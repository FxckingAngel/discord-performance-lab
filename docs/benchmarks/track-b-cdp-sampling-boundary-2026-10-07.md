# Track B CDP allocation-sampling boundary

Date: 2026-10-07

This report compares the existing private CDP diagnostic summaries. Raw heap
snapshots remain local and are not published.

## What the samples show

Across the settled authenticated captures:

- V8 used heap was approximately 101–107 MiB.
- V8 backing storage was approximately 22–23 MiB.
- DOM nodes were approximately 6,247–6,286, with 14 documents and about
  2,198–2,366 JavaScript event listeners.
- The renderer private-working-set measurements were approximately 287–331
  MiB in the corresponding long-settle captures.
- Short native allocation-sampling windows collected approximately 0.9–1.3
  MiB of sampled bytes, with `msedge.dll` as the mapped module.

This leaves a large resident boundary outside the measured live V8 heap and
outside the short native sampling window. It must not be labeled JavaScript
memory.

## Recurring sampled leads

The heap allocation samples repeatedly included `unpack`, `aF`, `az`,
`useState`, and message/update-related functions such as `onMessage` and
`GUILD_MEMBER_UPDATE`. These are investigation leads only. Sampling is
statistical, and the sampled bytes are far smaller than the renderer’s
resident footprint, so they do not prove retained ownership or justify a code
change by themselves.

## Current interpretation

The evidence supports three separate buckets:

1. Live V8 and backing storage, about 120–130 MiB in the sampled states.
2. A large renderer-native/Blink/compositor/application-state remainder.
3. GPU and cross-process graphics allocations that cannot be assigned from the
   renderer CDP session alone.

The next safe attribution step is longer or repeated feature-isolation
sampling paired with the per-PID resident classifier. Forced GC and generic
Chromium switches remain unjustified by this evidence.
