# Track B current unverified process observation

Date: 2026-10-07

This was a read-only observation of the already-running ordinary Track B shell,
root PID 40832. It did not control the window, navigate Discord, restart the
shell, or touch the active official Discord installation.

## Measurement

- Duration: 60 seconds
- Interval: 5 seconds
- Samples: 10
- Process count: 8 in every sample
- Private working set median: 301.66 MiB
- Private working set range: 298.84–305.22 MiB
- Total working set median: 453.76 MiB
- CPU median: 0.2643% of total logical CPU
- CPU p95: 0.7499% of total logical CPU

The raw process-tree capture remains local at
`artifacts/track-b-current-unverified-20261007.json`.

## Interpretation

This is current process evidence, not a settled acceptance benchmark. The exact
Discord route, authentication state, visible media, call state, window state,
and display state were not independently verified. The 0.2643% CPU median must
not be treated as a regression or a pass/fail result without a matched workload
and a fixed settle condition.

The result does confirm that the ordinary shell stayed at a stable eight-process
tree during the observation. Private working set remains the primary resident
metric; total working set is reported separately and is not treated as unique
physical memory.

Official Discord was not stopped, restarted, modified, or included in this
observation.
