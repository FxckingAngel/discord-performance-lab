# Track B native-family lifecycle capture

Date: 2026-10-07

Artifact: `artifacts/track-b-native-family-lifecycle-20261007-final`

This is a read-only Track B diagnostic capture. The official Discord client
was not modified, restarted, or included. The route was not manually confirmed
as the canonical static DM/channel, so these numbers are initialization and
lifecycle evidence rather than an acceptance benchmark.

## Renderer identity

The renderer PID was `42688` at startup, frontend, and Friends checkpoints.
The selector matched the Track B WebView2 host identity and the renderer role,
not a remote-debugging-port argument that WebView2 does not consistently place
on renderer command lines.

## Measured checkpoints

| Checkpoint | Complete-tree private WS | Renderer private WS | V8 used heap | DOM nodes | Application ready |
| --- | ---: | ---: | ---: | ---: | --- |
| startup-5s | 656.36 MiB | 539.87 MiB | 176.08 MiB | 4,687 | yes |
| frontend-15s | 576.42 MiB | 396.24 MiB | 114.07 MiB | 5,069 | yes |
| Friends-40s | 469.56 MiB | 331.11 MiB | 105.47 MiB | 4,658 | yes |

The renderer and complete-tree resident footprint declined during this
initialization sequence while the renderer PID remained stable. This is not
evidence that the memory is reclaimable in a normal settled static channel;
that requires a manually confirmed route and repeated settled captures.

## Largest private allocation-base groups

These are address-based groups from read-only VirtualQueryEx and working-set
classification. They are not subsystem names and must not be called Blink,
Skia, media, or allocator arenas without stack or module evidence.

| Checkpoint | Group | Resident | Committed | Regions |
| --- | --- | ---: | ---: | ---: |
| startup-5s | `0x23100000000` | 238.94 MiB | 253.25 MiB | 1 |
| startup-5s | `0x279C00000000` | 55.04 MiB | 56.88 MiB | 1 |
| startup-5s | `0x682800000000` | 41.78 MiB | 43.43 MiB | 21 |
| frontend-15s | `0x23100000000` | 47.75 MiB | 48.50 MiB | 12 |
| frontend-15s | `0x279C00000000` | 32.34 MiB | 33.12 MiB | 9 |
| frontend-15s | `0x682800000000` | 17.72 MiB | 17.72 MiB | 4 |
| Friends-40s | `0x23100000000` | 44.62 MiB | 45.00 MiB | 9 |
| Friends-40s | `0x279C00000000` | 31.96 MiB | 32.88 MiB | 10 |
| Friends-40s | `0x682800000000` | 17.72 MiB | 17.72 MiB | 4 |

The largest group changed substantially during startup, but this capture does
not establish ownership or prove that it can be safely released. The next
comparison must use the same renderer through a manually confirmed static
route, a media-heavy route, and a return to the static route.

## Tooling change

`Invoke-TrackBNativeFamilyLifecycle.ps1` now selects a renderer by the
Track B WebView2 host identity, renderer role, and process lifetime. It no
longer assumes that the remote-debugging port appears in every renderer
command line. The change is covered by the performance-tool validation suite.

## Verification boundary

- No authentication, network protocol, or Discord behavior was changed.
- No working-set trimming, forced paging, or forced garbage collection was used.
- Raw process and memory artifacts remain local/private.
- The capture does not identify the allocation-base groups as specific
  Chromium or Discord subsystems.
