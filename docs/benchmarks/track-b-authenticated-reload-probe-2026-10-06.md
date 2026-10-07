# Track B authenticated reload retention probe

Date: 2026-10-06

Artifact directory: `artifacts/track-b-release-auth-reload-refresh-20261006/`

This was an opt-in diagnostic-only probe. The authenticated-no-bridges shell was allowed to settle, then the page was reloaded through CDP before the measurement window. The route and workload were not manually verified, so this is not an acceptance benchmark.

After the reload and a short settling period:

- Renderer resident memory: 583.2 MiB
- Renderer private-writable resident: 476.1 MiB
- Complete-tree private working set reached 623.6 MiB in the final sample
- V8 used heap: 162.2 MiB
- DOM nodes: 7,109
- JavaScript listeners: 4,584

This did not demonstrate memory reclaim. The result was higher than the earlier authenticated capture, which had 332.3 MiB renderer private-writable resident and 117.3 MiB V8 used heap. Because the route/workload was not verified and the two captures did not converge to the same frontend state, this is not proof that reload increases steady-state memory. It does rule out treating a page reload as a validated memory optimization. No reload behavior was added to normal Track B operation.
