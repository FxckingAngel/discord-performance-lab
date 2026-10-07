# Track B authenticated-profile diagnostic

Date: 2026-10-07

The reversible `--diagnostic-authenticated-no-bridges` wrapper ran against the
Track B WebView2 profile with a 30-second settle period and a 30-second CDP and
process-tree capture. It closed only Track B, then restored the normal shell;
the restored shell was responsive and running under a new PID. Official
Discord was not touched.

Raw private artifacts:

- `artifacts/track-b-authenticated-current-20261007/process-tree.json`
- `artifacts/track-b-authenticated-current-20261007/cdp.json`

The exact route, authentication readiness, and visible workload were not
manually confirmed. The tool therefore recorded this as
`unverified-route-and-workload`; it is diagnostic evidence, not an acceptance
baseline or an optimization result.

The capture contained eight processes in all seven samples:

| Metric | Observed range |
| --- | ---: |
| Complete-tree private working set | 435.75–483.20 MiB |
| Complete-tree working set | 851.32–899.18 MiB |
| Renderer private working set | 317.38–365.09 MiB |
| GPU private working set | 42.34–48.77 MiB |
| Summed CPU samples | 0.000–0.622% |

The final CDP diagnostic sample reported:

| Diagnostic | Value |
| --- | ---: |
| V8 used heap | 101.12 MiB |
| V8 total heap | 106.88 MiB |
| V8 backing storage | 22.52 MiB |
| Documents / frames | 13 / 13 |
| DOM nodes | 6,038 |
| JavaScript event listeners | 2,173 |
| Image elements | 147 |
| Video elements / playing videos | 3 / 0 |
| RTCPeerConnections | 0 |

The renderer remains the dominant private-resident owner. The measured V8
heap explains only part of its private working set, but native sampling covered
only a small sampled allocation set, so this capture does not identify a safe
renderer optimization by itself.
