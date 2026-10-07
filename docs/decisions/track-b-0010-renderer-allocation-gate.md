# Decision 0010: renderer allocation gate

## Current evidence

The settled one-renderer Track B state consistently places roughly 120–130 MiB of private bytes in the renderer. A recent aggregate CDP probe measured 33.9 MiB V8 used heap and 63.6 MiB allocated heap, while the browser did not expose `performance.measureUserAgentSpecificMemory()`.

The settled CDP performance window measured effectively zero script, layout, and style-recalculation time. The warmed trace showed task dispatch and I/O watcher activity but no sustained incremental or major GC activity and no paint/compositor events. Chromium allocation-sampling methods returned empty or aggregate-only results without stack frames. Minimizing the window reduced renderer private bytes by about 17 MiB, but the foreground allocation remained.

## Decision

Do not modify renderer isolation, force garbage collection, trim working sets, disable hardware acceleration, add unmeasured Chromium switches, remove desktop bridges, or inject page-level UI changes until a candidate identifies a specific removable renderer-owned allocation or workload.

The next renderer candidate must provide:

1. a local aggregate attribution for the allocation category or workload;
2. a foreground process-tree comparison against the settled seven-process baseline;
3. a rollback path that leaves the normal shell unchanged;
4. functional checks for messaging, notifications, media, voice, video, and screen sharing;
5. no page-out or forced-memory-pressure shortcut.

The target remains approximately 250 MiB private/unique resident RAM and 0.2% CPU for the complete foreground process tree. A result near 250 MiB from natural settling is evidence to preserve and reproduce, not permission to redefine the target or accept an unverified feature regression.
