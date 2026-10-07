# Decision 0003: adaptive profile scope

## Status

Accepted for explicit background-idle experiments. Rejected as a general minimized-window optimization.

## Decision

The stock Discord launch remains the default for active use. The adaptive watcher may be used only after active voice, video, and media work has ended and the user intentionally places Discord in an idle background state.

Minimizing the window alone is not sufficient evidence that Discord is idle. The watcher preserves system-managed QoS for the GPU and audio roles, but that boundary did not prevent a CPU regression during active voice/media use.

## Evidence

A paired minimized active-use run on 2026-10-06 compared stock system-managed QoS with media-safe adaptive QoS. Stock measured 0.770% CPU; adaptive measured 7.588% CPU. Process count remained six, and adaptive memory was also higher. The comparison failed the five-percent regression gate.

The adaptive transition itself passed: visible state selected system-managed QoS, minimized state selected EcoQoS for non-media roles, and restoring the window returned the full tree to system-managed QoS. This proves transition mechanics only.

## Consequences

- Adaptive QoS must not be presented as an active-use or foreground optimization.
- The user must end active voice, video, and media work before using the background profile.
- Any broader scope requires a new paired workload and full functional acceptance.
- No process is terminated, no client files are patched, and no account or network behavior is changed.
