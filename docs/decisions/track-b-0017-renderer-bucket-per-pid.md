# Decision 0017: keep renderer memory buckets per PID

## Decision

The Phase 2 memory-bucket report now includes `rendererCount` and a `rendererAttribution` array. Aggregate renderer resident and private-byte buckets continue to come from the role summary, while each renderer PID retains its own median and p95 resource values.

## Reason

Discord can run more than one renderer. Selecting the first renderer would make a multi-renderer capture look smaller than it is and could hide the process responsible for a memory change. The report must preserve individual renderer evidence before any aggregate is interpreted.

## Verification

The performance-tool suite passes. Running the updated bucket summarizer against the local authenticated no-bridge capture produced one renderer row for PID 19484, 342.96 MiB aggregate renderer private working set, 110.912 MiB V8 used heap, and a 232.0 MiB non-V8 residual lower bound.

These values are attribution boundaries, not proof that the residual is removable. No renderer behavior was changed.
