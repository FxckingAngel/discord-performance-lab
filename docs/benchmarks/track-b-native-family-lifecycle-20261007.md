# Track B native allocation-family lifecycle

Date: 2026-10-07

Status: automatic diagnostic evidence. The run used the current Release shell and one renderer PID, 35976. The route was not a manually confirmed canonical workload.

| Stage | Renderer resident total | Private-writable resident | Largest allocation-base family | Largest family committed | Regions |
| --- | ---: | ---: | ---: | ---: | ---: |
| Startup 5 seconds | 579.54 MiB | 488.34 MiB | 210.29 MiB | 220.25 MiB | 1 |
| Frontend 15 seconds | 414.11 MiB | 321.17 MiB | 47.51 MiB | 48.50 MiB | 13 |
| Friends 40 seconds | 585.31 MiB | 493.61 MiB | 247.54 MiB | 249.69 MiB | 17 |

The same renderer therefore changes allocation-family shape substantially during frontend startup and route navigation. This is evidence against treating the largest anonymous family as a fixed WebView2 floor. It is not enough to identify the owner: allocation-base addresses are ASLR-specific and the rank changes between stages. The next attribution step should correlate these families with the paired CDP/Windows stage, then compare a manually confirmed static route against a media-heavy route before any renderer behavior is changed.

No Chromium flags, renderer behavior, media behavior, authentication, or network behavior were changed. Official Discord was not touched. The normal Track B shell was relaunched after the capture.
