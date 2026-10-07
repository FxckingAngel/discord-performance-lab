# Track B cross-process resident-page accounting

Date: 2026-10-06

## Capture

The normal Release shell was running with root PID `2556` at 60 Hz and 1920x1080. The read-only `Measure-DiscordWorkingSetPages.ps1` collector followed eight processes and queried each process working set through PSAPI.

Artifact: `artifacts/track-b-current-cross-process-pages-20261006.json`

| Measure | Result |
| --- | ---: |
| Process count | 8 |
| Summed resident pages | 1,037.668 MiB |
| Pages with PSAPI shared flag | 199.422 MiB |
| Pages without PSAPI shared flag | 208.914 MiB |
| Pages with share count above one | 3.410 MiB |
| Pages with share count of one | 404.926 MiB |

The process-level roles were:

| Role | Resident pages |
| --- | ---: |
| Renderer | 600.7 MiB |
| Browser | 149.4 MiB |
| GPU process | 108.8 MiB |
| Native shell | 54.2 MiB |
| Network utility | 50.5 MiB |
| Audio utility | 28.1 MiB |
| Crashpad | 22.1 MiB |
| Storage utility | 23.8 MiB |

## Interpretation

The renderer remains the largest process-level owner in this capture. The PSAPI shared flag and share count are useful corroborating classifications, but neither exposes a cross-process physical page identity. Summing the single-owner or non-shared categories therefore does not establish the application's unique physical RAM footprint.

The result does establish that a large part of the summed working-set number is not safely attributable to one private owner. Future acceptance reports must continue to show private working set and private bytes separately, while retaining the ordinary summed working set. This capture must not be used to claim that the 250 MiB target has been met.

## Next attribution boundary

The remaining high-value question is still the renderer's private resident footprint. The next useful comparisons are blank WebView2, Discord app shell, static text, media-heavy content, voice, video, and screen sharing with the same per-PID resident classification and CDP aggregates. No renderer optimization is accepted until those deltas identify a feature-dependent allocation that can be reduced without removing Discord functionality.
