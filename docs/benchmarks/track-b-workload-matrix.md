# Track B workload matrix

The idle floor is not the whole product acceptance target. Each workload must preserve normal Discord behavior and be compared with pristine Official Discord on the same machine and state. Active-workload RAM limits are intentionally unset until those baselines exist.

| Workload | Required state | Private WS | Total WS | Derived shareable WS | Private bytes | CPU median/p95 | GPU/memory | Processes | Responsiveness | Functional result |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | ---: | --- | --- |
| Settled idle | Static route, untouched | pending canonical | pending | pending | pending | pending | pending | pending | pending | pending |
| Active text/chat | Navigate, type/send, reactions, embeds/images | pending | pending | pending | pending | pending | pending | pending | pending | pending |
| Channel navigation | Fixed route sequence and settled transitions | pending | pending | pending | pending | pending | pending | pending | pending | pending |
| Scrolling | Scroll channel/history at a fixed rate | pending | pending | pending | pending | pending | pending | pending | pending | pending |
| Media-heavy channel | Visible GIFs, stickers, images, embeds | pending | pending | pending | pending | pending | pending | pending | pending | pending |
| Voice idle | Connected audio, nobody speaking | pending | pending | pending | pending | pending | pending | pending | pending | pending |
| Active voice | Incoming/outgoing speech and microphone processing | pending | pending | pending | pending | pending | pending | pending | pending | pending |
| Video call | Camera/video and device controls | pending | pending | pending | pending | pending | pending | pending | pending | pending |
| Screen sharing | Capture and share controls active | pending | pending | pending | pending | pending | pending | pending | pending | pending |
| Notifications | Receive and open a normal notification | pending | pending | pending | pending | pending | pending | pending | pending | pending |
| Gaming background | Same game and background Discord state | pending | pending | pending | pending | pending | pending | pending | pending | pending |

The approximately 250 MiB design target applies to settled idle private working set. Do not establish arbitrary active-workload RAM limits before trustworthy same-workload pristine Official Discord baselines. Video and screen sharing require separate GPU, frame-stability, latency, encoder, and responsiveness analysis rather than an idle comparison.

No workload may pass by disabling visible GIFs, stickers, media, voice, video, notifications, or screen sharing. Diagnostic static states are not production optimizations.
