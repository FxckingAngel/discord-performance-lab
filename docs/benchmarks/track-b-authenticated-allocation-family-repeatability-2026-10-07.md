# Track B authenticated allocation-family repeatability

Date: 2026-10-07  
Source: renderer resident maps from the three five-minute authenticated repetitions

## Result

The largest private-writable allocation-base families recur at similar resident sizes in every fresh renderer lifetime. The virtual addresses differ, so the comparison uses rank and size rather than address identity.

| Run | Largest family (MiB) | Second (MiB) | Third (MiB) | Fourth (MiB) | Renderer private-writable resident (MiB) |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1 | 58.75 | 43.93 | 19.16 | 9.82 | 274.42 |
| 2 | 64.23 | 41.18 | 17.75 | 10.00 | 280.40 |
| 3 | 61.09 | 40.00 | 17.75 | 10.18 | 273.38 |

The first three families account for about 121.84 MiB, 123.16 MiB, and 118.84 MiB respectively. Their combined spread is small compared with the total renderer footprint:

- largest family range: **5.48 MiB**
- second-family range: **3.93 MiB**
- third-family range: **1.41 MiB**

The fourth family is also close in size across runs. The exact allocation bases change with each renderer lifetime, as expected for address-space allocation.

## Classification limits

These regions are committed private-writable pages observed through `VirtualQueryEx` and `QueryWorkingSetEx`. Their presence and size are established, but the current map does not identify the owning Chromium subsystem. The report does not label them as Blink, Skia, compositor, media, WebView2, or Discord state.

The repeated sizes make a purely transient measurement artifact less likely, but they do not prove that the families are an unavoidable WebView2 floor. They appeared in the fully initialized Discord state, not in the blank runtime control, so the next required comparison is workload-dependent rather than another fresh idle run.

## Engineering consequence

Do not change renderer behavior based on these families alone. The next diagnostic should keep one renderer alive while moving between a canonical static text route and a media-heavy route, recording these ranked families before and after each transition. A family that remains stable across that transition is a loaded frontend/runtime floor candidate; a family that expands with visible media and contracts after leaving it is a media/cache candidate.
