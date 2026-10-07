# Track B normal-shell current diagnostic

Date: 2026-10-07  
Capture: `artifacts/track-b-normal-current-post-preload-20261007.json`  
Scenario: normal shell, visible and responding, 1920x1080 at 60 Hz

This was a read-only 30-second process-tree capture after the preload-contract review. It did not expose CDP, so it has no `applicationReady` proof and is not an authenticated acceptance benchmark.

## Observed state

- Process count: 8 throughout the capture.
- Renderer PID: 43892.
- GPU PID: 28660.
- Renderer private working set: approximately 259–307 MiB across the recorded samples.
- Renderer private bytes: approximately 363–366 MiB.
- GPU private working set: approximately 34–41 MiB.
- Complete-tree private working-set sum from the recorded per-process rows: approximately 347–406 MiB.
- The shell window remained visible, responding, and unminimized.

The renderer remained the dominant private-resident process. The sample also shows that its private working set moved by tens of MiB during a short settled observation, so a route-verified repeated baseline is still required before accepting a small optimization.

## Interpretation

This is evidence about the current normal shell, not proof that the target Discord route was fully initialized. It is consistent with the previously observed high-memory Track B state and does not use the incomplete ≈121 MiB lifecycle control as a comparison win.

No renderer settings, Chromium switches, media behavior, or desktop capability exposure were changed for this capture. The official Discord control remained untouched.

