# Decision 0015: preserve per-PID attribution in Phase 2 summaries

## Decision

Phase 2 summaries now retain one statistical row per observed process ID in addition to the existing role and complete-tree totals. The row preserves the PID, parent PID, role, lifetime, working-set measures, private bytes, CPU, faults, I/O, handles, and threads with median and p95 values where applicable.

## Reason

Renderer totals must not hide whether one renderer or several renderers own the resident-memory cost. Raw captures already contained per-PID samples, but the derived summary exposed only role aggregates. That made downstream comparisons more likely to discard the identity needed for renderer-count and renderer-lifetime analysis.

## Boundaries

This is a reporting change only. It does not merge renderer rows, alter the shell, change WebView2 settings, or select an optimization. PID values are local diagnostic identifiers and command-line details remain outside published summaries.

## Verification

The performance-tool fixture now runs the Phase 2 summarizer and verifies that the renderer PID remains present as an individual row. The same summarizer was run against the local Phase 2 schema capture and produced eight per-process rows, including one renderer row.
