# Track B current authenticated follow-up

Date: 2026-10-07

## Scope

This is a private diagnostic capture of the authenticated no-bridge Track B shell. It is not an official-versus-Track-B acceptance benchmark and does not claim an optimization. The official Discord client was not stopped, restarted, modified, injected, or reconfigured.

Raw process and CDP artifacts remain local under `artifacts/track-b-cdp-current-20261007-113511`.

## Capture

- Scenario: `current-goal-followup`
- Display: 1920x1080 at 60 Hz
- Process count: 8 at every sample
- Window: visible, non-minimized, responding
- Route readiness: `discord-channels`, document and application mount ready
- Renderer identity: Windows PID 19844 for the capture
- Capture duration: 37.7 seconds
- Sampling interval: 5 seconds
- Diagnostic mode: authenticated no-bridge probe

The first three samples include startup settling. The later samples show the post-load state:

| Metric | Startup peak | Settled sample range |
| --- | ---: | ---: |
| Complete-tree private working set | 638.75 MiB | 448.00–469.01 MiB |
| Renderer private working set | 523.53 MiB | 331.01–354.11 MiB |
| GPU private working set | 38.64 MiB | 38.64–42.34 MiB |
| Complete-tree working set | 1036.55 MiB | 860.94–881.81 MiB |

The settled samples were not used to replace the canonical five-run baseline because this was a short diagnostic probe rather than the manually confirmed acceptance route. It does show that renderer memory naturally falls by about 190 MiB during startup without any trimming or feature disabling.

## Renderer state at the final CDP sample

- V8 used heap: 108.73 MiB
- V8 total heap: 217.70 MiB
- V8 backing storage: 22.85 MiB
- DOM nodes: 5,949
- Documents: 13
- Frames: 2
- JavaScript event listeners: 2,198
- Image elements: 143
- Video elements: 3, none playing
- Canvas elements: 4
- Application mount: present and populated
- App mount rectangle: 1280x768

The diagnostic heap sampler reported 4.04 MiB of sampled outstanding allocations across 123 samples. That is a sampled window, not a complete accounting of the renderer private working set.

## Interpretation

This capture strengthens the lifecycle hypothesis: a large portion of the renderer footprint is acquired during initialization and released or made non-resident as the page settles. It does not identify the owner of the remaining native allocation families. No production behavior was changed based on this result.

The next valid attribution step remains a matched same-session transition with a stable renderer identity: canonical static route, media-heavy route, return to canonical route, and settled checkpoints with per-region resident/commit data.
