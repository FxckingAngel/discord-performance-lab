# Track B blank versus current renderer allocation-rank delta: 2026-10-07

This is a sanitized rank-based comparison between the blank WebView2 renderer and the live Track B renderer classification. Allocation-base addresses are not treated as identities because address-space layout is randomized between processes.

Sources:

- Blank renderer: `artifacts/track-b-blank-resident-types-20261007/resident-types/pid-25460.json`
- Current renderer: `artifacts/track-b-live-current-20261007-014226/renderer-memory-types.json`

## Rank comparison

| Resident rank | Blank resident | Current resident | Delta | Current committed | Current regions |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 2.65 MiB | 79.38 MiB | +76.73 MiB | 80.75 MiB | 13 |
| 2 | 0.53 MiB | 42.30 MiB | +41.77 MiB | 43.88 MiB | 5 |
| 3 | 0.50 MiB | 19.15 MiB | +18.65 MiB | 19.56 MiB | 5 |
| 4 | 0.22 MiB | 10.66 MiB | +10.44 MiB | 11.25 MiB | 1 |
| 5 | 0.18 MiB | 9.13 MiB | +8.96 MiB | 10.00 MiB | 1 |

The top three rank groups therefore account for approximately **137.15 MiB of additional resident memory** in the current loaded renderer compared with blank. This strengthens the conclusion that Discord-loaded state creates large private-writable renderer allocations rather than those allocations being part of the blank WebView2 floor.

## Limits

Rank matching does not prove that a blank rank and a current rank are the same allocator arena. It also does not identify Blink, Skia, compositor, media, WebView2, or Discord ownership. The result is a differential lead for the next static-versus-media workload comparison, not an optimization by itself.

No renderer behavior or Discord functionality was changed.
