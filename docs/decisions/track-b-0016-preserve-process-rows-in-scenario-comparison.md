# Decision 0016: preserve process rows in scenario comparisons

## Decision

Scenario attribution comparisons now include the per-PID summary rows from both runs, tagged as `baseline` or `candidate`. The comparison explicitly does not match PIDs across runs.

## Reason

The static-versus-media experiment needs to show renderer count and individual renderer ownership. Matching Windows PIDs across separate launches would be misleading because PID values are local to a run and may be reused. Keeping each row intact preserves the evidence without inventing cross-run identity.

## Verification

The performance-tool suite passes. A local comparison smoke using the Phase 2 schema capture produced separate baseline and candidate process rows and retained the no-PID-matching interpretation.
