# Track B user-agent-specific memory boundary

Date: 2026-10-06

## Scope

The CDP diagnostic now probes `performance.measureUserAgentSpecificMemory()` and retains only aggregate category sizes when the API is available. The probe was run after a 60-second settle period with a 30-second process capture.

Raw local output:

- `artifacts/track-b-ua-memory-20261006/cdp.json`
- `artifacts/track-b-ua-memory-20261006/process-tree.json`

## Result

The API returned no result in the Track B WebView2 page, so the aggregate user-agent-specific memory breakdown is unavailable in this environment. No DOM, JavaScript, shared-memory, or page data was inferred from the missing result.

The same capture still reported ordinary V8 counters:

- V8 used heap: 102.62 MiB
- V8 total heap: 116.07 MiB
- Embedder heap: 25.78 MiB
- Backing storage: 22.74 MiB

## Interpretation

This diagnostic interface cannot separate Blink/DOM bytes from other renderer categories for this WebView2 target. The project must continue using the independently measured private working set, V8 counters, DOM/resource counts, heap-type summaries, and native sampling while keeping the missing API explicitly marked unavailable.

No production behavior was changed.
