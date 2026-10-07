# Track B next phase

Track B remains active. The next phase has three concurrent workstreams. The
workstreams share one acceptance boundary: only a fully initialized Discord
state counts as a product result.

## 1. Renderer memory

The current authenticated reference is approximately:

- 419 MiB complete-tree private working set
- 313 MiB renderer private working set
- 113 MiB V8 used heap
- 37 MiB GPU private working set
- 0.108% CPU in the latest settled observation

The idle design target remains approximately 250 MiB complete-tree private
resident RAM and 0.2% median CPU. CPU is not an active optimization target
unless repeated controlled runs show a regression.

The renderer work will track the major allocation families individually,
including the approximately 73 MiB, 41 MiB, and 19 MiB families. Each family
must be followed through initialization, navigation, media use, and return to
a simple route before an optimization is selected. A family is not assigned to
Blink, media, compositor, or a cache without supporting evidence.

No memory result counts if it disables visible Discord behavior, reduces media
quality, forces working-set trimming, causes paging, or leaves the application
partly initialized.

## 2. Desktop compatibility

The normal shell remains free of a partial `DiscordNative` contract. Native
capabilities are implemented and tested in isolation, then exposed to Discord
only as a coherent boot-critical set whose methods, events, return values, and
failure behavior match the pristine official reference where applicable.

The clean official Discord client is read-only ground truth. It may be
observed through sanitized diagnostics, but it must not be patched, injected,
reconfigured, or changed to make Track B easier to match.

The compatibility boundary is:

Discord frontend -> Track B compatibility layer -> real Windows behavior

It is not an Electron impersonation layer. A capability is reported only when
the native implementation behind it works.

## 3. Real-use benchmarking

After the authenticated manual checkpoint confirms one canonical route, the
benchmark matrix will compare pristine official Discord and Track B on the
same machine, display, account state, route, window geometry, and workload.
The matrix covers:

- settled authenticated idle
- active texting
- channel and DM navigation
- sustained scrolling
- image, GIF, sticker, and embed-heavy use
- quiet voice
- active voice conversation
- video
- screen sharing
- notifications
- gaming with Discord in the background

Each scenario records complete-tree private working set, renderer private
working set, private bytes, CPU median and p95, GPU usage and memory, process
count, responsiveness, and functional pass/fail. Active-use RAM limits will
be derived from pristine measurements rather than invented in advance.

Incomplete `/app` states, loading pages, route-unverified captures, and
diagnostic shells with deliberately missing capabilities remain useful
diagnostic evidence but are excluded from product acceptance claims.
