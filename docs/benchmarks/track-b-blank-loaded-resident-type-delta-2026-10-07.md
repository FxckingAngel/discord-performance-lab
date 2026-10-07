# Track B blank versus Discord-loaded resident-page delta

Date: 2026-10-07

This matched diagnostic comparison uses the same read-only process-tree and `VirtualQueryEx`/`QueryWorkingSetEx` collection path. The loaded run used the authenticated no-bridge profile, but neither route was manually checkpointed, so this is attribution evidence rather than an acceptance benchmark. Official Discord was not touched.

## Complete-tree and renderer comparison

| Metric | Blank WebView2 | Discord-loaded diagnostic | Delta |
| --- | ---: | ---: | ---: |
| Complete-tree private working set median | 71.24 MiB | 399.64 MiB | +328.40 MiB |
| Complete-tree private working set p95 | 73.04 MiB | 407.43 MiB | +334.39 MiB |
| Renderer private working set median | 9.80 MiB | 293.77 MiB | +283.97 MiB |
| Renderer private-writable resident | 7.21 MiB | 289.16 MiB | +281.95 MiB |
| Renderer image-backed resident | 35.81 MiB | 75.83 MiB | +40.02 MiB |
| Renderer mapped resident | 2.85 MiB | 20.71 MiB | +17.86 MiB |

The renderer private-writable delta is the dominant part of the loaded-state increase. The blank runtime does not contain a comparable private-writable allocation arena.

## Allocation-base comparison

The loaded renderer's four largest allocation-base families account for approximately 146.97 MiB resident:

- `0x29600000000`: 69.86 MiB;
- `0x770800000000`: 46.14 MiB;
- `0x273000000000`: 18.85 MiB;
- `0x6CC000000000`: 12.12 MiB.

The blank renderer's largest family is only 2.65 MiB, followed by 0.53 MiB and 0.50 MiB families. None approaches the loaded four-family set.

## Interpretation

This is strong evidence that the large private-writable families are triggered by Discord frontend initialization or loaded Discord state, rather than being an unavoidable WebView2 runtime floor. It does not identify whether the owner is Blink, PartitionAlloc, V8 backing storage, media state, or Discord application state. Allocation-base addresses alone are not an ownership label.

The first real optimization target is therefore the Discord-loaded renderer state. The next comparison must hold a manually confirmed static route, then repeat the same page classification after media and voice transitions. No cache, arena, compositor, or feature is disabled based on this result alone.
