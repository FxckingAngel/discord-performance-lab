# Track B active-workload checkpoint

`tools/Invoke-TrackBActiveWorkloadCheckpoint.ps1` adds a repeatable manual workflow for active Discord workloads. It is intended for states that cannot be safely driven by the measurement tools, including typing, scrolling, calls, and screen sharing.

The wrapper requires a running, responsive Track B shell and asks for `READY` once per repetition. Each repetition delegates to the existing feature-scenario collector, preserving the complete process-tree time series, per-PID resident classification, private bytes, CPU, handles, threads, and display/window metadata. It writes a sanitized `active-workload-checkpoint.json` manifest that records the workload contract and the private artifact directories.

Example for an active text workload:

```powershell
.\tools\Invoke-TrackBActiveWorkloadCheckpoint.ps1 `
  -Scenario active-text `
  -Repetitions 3 `
  -DurationSeconds 600 `
  -IntervalSeconds 10 `
  -RequireSettled
```

Supported active scenarios are:

- `active-text`
- `channel-navigation`
- `scrolling`
- `media-heavy`
- `voice-idle`
- `active-voice`
- `video`
- `screen-sharing`
- `notifications`
- `gaming-background`

The contract records whether voice, video, screen sharing, and visible media are expected. It also records that the same account, route, window, display, and fully initialized frontend are required, and that production feature reduction is forbidden. The contract is a readiness record, not a functional pass. Functional behavior must be checked separately and reported as pass, fail, or untested.

The runner does not start or stop official Discord, send messages, join calls, change account state, or publish raw process data. Raw captures stay under the local artifact directory and must not be committed.
