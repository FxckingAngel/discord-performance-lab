# Track B memory-infra boundary: 2026-10-06

Status: diagnostic tooling result. The route and workload were not independently verified, and no application behavior was changed.

The settle-aware aggregate CDP trace requested a detailed Chromium memory dump and received 15 memory-dump-related events. After filtering to numeric fields that could represent size, resident bytes, private bytes, committed bytes, allocation size, or object counts, the trace exposed zero usable metrics.

The stream exposed allocator-graph importance metadata, but allocator graph identifiers and importance values are not memory ownership or byte totals. They are intentionally excluded from the sanitized report.

The verification trace completed with no data loss. Its selected activity counters remain available in `artifacts/track-b-cdp-trace-memory-filter-test-20261006.json`.

## Decision

Do not use WebView2 memory-infra trace output as a category-level renderer memory census on this runtime. Continue using private working set, private bytes, V8 heap usage, sanitized allocation samples, virtual-memory classification, and per-process role attribution as separate evidence. A future category census would require a stronger native diagnostic source; it must not be inferred from allocator IDs.
