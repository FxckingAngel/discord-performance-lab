# Track B renderer allocation-family lifecycle

Date: 2026-10-07  
Source: automatic authenticated lifecycle run, route-unverified  
Raw maps: local only under `artifacts/track-b-renderer-lifecycle-20261007-051130/`

This report correlates the largest private-writable allocation-base groups across the same renderer where possible. The family IDs are one-way hashes of local allocation-base values. Addresses are not published. A family ID is meaningful only within this run.

## Largest-family totals

| Checkpoint | Renderer PID | Largest family | Top three families | Interpretation |
| --- | ---: | ---: | ---: | --- |
| Blank | 35288 | 3.19 MiB | 4.29 MiB | Runtime-floor diagnostic; separate renderer |
| Navigation | 10448 | 220.66 MiB | 322.27 MiB | Large initialization allocation is present |
| Application shell | 10448 | 220.94 MiB | 322.62 MiB | Same renderer and same large families |
| Canonical route | 10448 | 220.94 MiB | 322.27 MiB | No further large-family growth at this checkpoint |
| Settled 1 minute | 10448 | 61.80 MiB | 106.89 MiB | Large initialization families have released most resident pages |
| Settled 5 minutes | 10448 | 65.25 MiB | 123.47 MiB | Families remain in the settled range |
| Settled 10 minutes | 10448 | 61.50 MiB | 128.09 MiB | Persistent native/private family floor remains |

## Stable family correlation

| Family ID | Application shell | Settled 1 minute | Settled 10 minutes |
| --- | ---: | ---: | ---: |
| `family-c1a5cc41b517` | 220.94 MiB | 61.80 MiB | 61.50 MiB |
| `family-7eb9c7822be1` | 57.40 MiB | 26.21 MiB | 48.84 MiB |
| `family-24d95f6dce34` | 44.29 MiB | 18.88 MiB | 17.75 MiB |
| `family-1f434937c137` | 11.07 MiB | 10.96 MiB | 10.13 MiB |
| `family-b897f70ee1db` | 7.54 MiB | 8.27 MiB | 9.39 MiB |

The largest family is therefore strongly associated with Discord initialization, but it is not permanently resident at its peak. Its settled size is still about 61.5 MiB. The second family partially contracts and later grows, so it must not be treated as a fixed cache without a longer route/media experiment.

## What this proves

- The large private-writable families are absent at the blank renderer floor and appear when Discord begins loading.
- The same renderer PID retains the family identities through application-shell, canonical-route, and settled checkpoints.
- Initialization creates a transient private-resident allocation set substantially larger than the settled set.
- A persistent settled family set remains, with the top three totaling about 128 MiB at 10 minutes.

## What this does not prove

The maps do not identify the allocator owner. These families have not been labeled as Blink, Skia, compositor, media, WebView2 infrastructure, V8, or Discord application state. No renderer behavior was changed based on this evidence.

The route was automatically selected and not manually confirmed as the exact static channel, so this is not the canonical acceptance baseline. The next attribution step is to repeat the same-family correlation on a manually confirmed static route and a media-visible route, then compare the family deltas with CDP paint/media metrics and GPU maps.

Policy: read-only VirtualQueryEx and QueryWorkingSetEx data only. No cache clearing, forced GC, working-set trimming, media disabling, protocol changes, or partial desktop bridge activation.
