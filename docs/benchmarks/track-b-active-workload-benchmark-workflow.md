# Track B active-workload benchmark workflow

This workflow prepares comparable measurements without changing either client. The official Discord installation is a read-only stock control. Do not stop, restart, patch, inject into, or change its settings. Track B may be restarted between runs when a fresh process tree is required.

## Run order

1. Generate a run plan with `tools/New-TrackBActiveWorkloadMatrix.ps1`.
2. Use the same physical monitor, window size, Windows scaling, network state, account, route, and call state for both builds. Measure official Discord first, then Track B. Keep official Discord in its normal state.
3. For each build, manually prepare the workload and confirm the checkpoint. The checkpoint must establish that the Discord frontend is fully initialized, the route is stable, the process inventory is synchronized, and the window is responsive.
4. Exercise the listed action for the planned duration. A record with no exercised action is `UNTESTED`, not a pass.
5. Capture the complete process tree. Preserve individual PIDs and roles in the raw artifact, but publish only sanitized aggregates.
6. Validate the completed records with `tools/Test-TrackBActiveWorkloadMatrix.ps1`. Missing readiness, metrics, action, functional status, window dimensions, refresh rate, or display scaling is a validation failure. The official and Track B environment values must match for each workload.
7. Run the same validator with `-Acceptance` for a product decision. Acceptance mode requires both builds to be responsive and functionally passing, requires exercised actions to pass, requires Track B private working-set median to be lower than the untouched official control for every workload, and enforces the 250 MiB / 0.2% settled-idle targets.

8. For `media-heavy`, `video`, and `screen-sharing`, acceptance also requires sanitized Track B evidence that source resolution, raster quality, hardware acceleration, and visual quality are comparable. A lower-quality media result is a failure even if the resource numbers improve.
9. Acceptance records must also carry matching sanitized route and network-state fingerprints. Voice, video, and screen-share records must carry matching sanitized call-state fingerprints. These fingerprints must not contain account IDs, channel IDs, message content, URLs, or tokens.

## Workload preparation

| ID | Manual state and action |
| --- | --- |
| `settled-idle` | Fully initialized static DM or text channel; leave untouched after settling. |
| `active-text` | Navigate, type, send, edit or react to a test message, and verify the result. Do not record message content. |
| `channel-navigation` | Navigate through the predetermined channel/DM sequence and return to the final route. |
| `scrolling` | Scroll the same history range at a repeatable pace, then settle. |
| `media-heavy` | Keep visible GIFs, stickers, images, and embeds enabled and visible; verify they render at normal quality. |
| `voice-idle` | Connect to voice with nobody speaking; verify audio controls and chat remain usable. |
| `active-voice` | Use normal microphone input and incoming speech; verify voice remains intelligible and responsive. |
| `video` | Use the same camera/call state and verify device controls, video, frame stability, and latency. |
| `screen-sharing` | Share the same window or display and verify capture quality, controls, encoder behavior, and latency. |
| `notifications` | Receive and open a normal notification; record only sanitized status and timing. |
| `gaming-background` | Use the same game and Discord background state; record responsiveness and resource impact without changing game settings. |

## Required record shape

Each official and Track B record must follow `track-b-active-workload-matrix-schema.json`. The complete-tree metrics are the primary comparison boundary:

- private working set median and p95;
- total working set median and p95;
- private bytes median and p95;
- CPU median and p95;
- GPU usage and GPU memory where applicable;
- process count;
- responsiveness;
- functional pass/fail.

The readiness gate is separate from functional status. A responsive window or a loaded URL alone is insufficient. A workload with an incomplete frontend, unstable route, unsynchronized PID inventory, or `UNTESTED` action cannot be used as an acceptance result.

Video and screen sharing are workload-specific comparisons. Do not compare their resource totals directly with settled idle. Do compare the same call/capture state between official Discord and Track B, including frame stability, latency, controls, and functional status.

No production change may disable visible GIFs, stickers, animations, video, media, notifications, voice, or screen sharing. Static/no-media runs explain a measurement but do not justify a production optimization.

The schema and helper intentionally do not collect message text, account identifiers, channel IDs, tokens, private URLs, clipboard contents, file contents, or screenshots.
