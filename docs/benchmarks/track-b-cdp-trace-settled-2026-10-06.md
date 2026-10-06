# Track B settled CDP trace: 2026-10-06

Status: aggregate diagnostic evidence only. The route and workload were not independently verified, and no renderer or Discord behavior was changed.

Source: `artifacts/track-b-cdp-trace-settled-current-20261006.json`

The diagnostic shell was allowed to settle for 45 seconds before a 20-second CDP trace. Raw trace events were discarded by the collector. The trace completed without data loss.

## Selected activity

| Signal | Count in 20 seconds |
| --- | ---: |
| RunTask | 5,173 |
| FunctionCall | 597 |
| Incremental V8 GC events | 1,209 |
| Incremental GC embedder-tracing events | 401 |
| AnimationFrame | 392 |
| UpdateLayer | 1,728 |
| Style/layout updates | 201 |
| Paint | 136 |
| CompositeLayers | 0 |
| DrawFrame | 0 |
| Timer fires | 208 |
| EvaluateScript | 0 |

The trace also recorded lifecycle and compositor work, including 201 `UpdateLayoutTree`/layout events, paint lifecycle activity, compositing commits, and layerization. A memory dump was requested successfully, but the trace summary does not expose a category byte total.

## Interpretation

The post-settle diagnostic still shows recurring incremental GC, animation frames, timers, layout, paint, and layer work. This makes GC, animation/compositor scheduling, and retained application activity reasonable investigation leads. The counts do not prove that any of these activities owns a specific amount of private resident memory or that disabling them would preserve Discord functionality.

The earlier startup trace had heavy resource parsing and buffer loss. This settle-aware run removes that startup ambiguity but remains an unverified diagnostic profile. Do not disable animations, force collection, alter Discord's frontend, or change runtime flags based on event counts alone. The next candidate needs a paired process-tree memory result and functional checks.
