# Track B media-transition attribution

This is a sanitized diagnostic summary from the authenticated route-transition artifact. It is not an optimization result and does not change production behavior.

## Capture

The sequence was a static route, a media-visible route, then a return to the static route. All three readiness markers were present. The route was not promoted to an acceptance benchmark because functional and media-quality pass evidence was not supplied.

| Metric | Static before | Media visible | Static after | Media delta |
| --- | ---: | ---: | ---: | ---: |
| Complete-tree private working set | 428.10 MiB | 517.72 MiB | 461.99 MiB | +89.62 MiB |
| Renderer private working set | 319.59 MiB | 384.90 MiB | 342.66 MiB | +65.31 MiB |
| GPU private working set | 36.46 MiB | 60.50 MiB | 44.70 MiB | +24.04 MiB |
| Complete-tree CPU median | 0.034% | 1.643% | 0.034% | +1.609 pp |

The media-visible state increased both renderer and GPU private working set. The return-to-static state released part of the increase, but remained above the initial state. This is evidence of a media-dependent transition and possible retention. It does not identify the owning subsystem.

## Allocation-base deltas

Allocation-base identifiers are process-local diagnostic labels. They are not subsystem names and must not be called Blink, Skia, compositor, media, or cache without ownership evidence.

The largest observed family was `0x690400000000`:

| State | Resident |
| --- | ---: |
| Static before | 25.578 MiB |
| Media visible | 70.617 MiB |
| Static after | 9.703 MiB |
| Media delta | +45.039 MiB |
| Return delta | -15.875 MiB |

Other media-only families appeared at approximately 2.664 MiB and 1.734 MiB during the media-visible state. Their ownership is unresolved. The corrected summarizer preserves families that appear only in the media state or only after returning to the static route.

## Gate status

- Readiness: passed for all three captured states.
- Functional pass: not supplied.
- Media-quality pass: not supplied.
- Optimization eligible: false.
- Production behavior: unchanged.

The next valid step is a repeated transition with the same route and explicit functional/media-quality checks, followed by subsystem attribution. No cache bound, media release policy, renderer change, or GPU change should be selected from this capture alone.
