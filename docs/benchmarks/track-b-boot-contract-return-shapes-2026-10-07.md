# Track B boot-contract diagnostic return shapes

The diagnostic atomic candidate now preserves two sanitized views of contract activity:

- `contractCallSequence`: the first observed method calls in order.
- `contractReturns`: the method path, JavaScript result type, and whether the result was promise-based.

The recorder does not retain return values, object contents, strings, URLs, IDs, messages, tokens, clipboard data, or file data. Rejected promises are recorded as contract errors and rethrown to preserve the candidate's behavior.

This improves boot-contract discovery without changing the normal shell. It does not make the atomic candidate valid for Discord activation. The candidate still remains diagnostic-only until every observed startup dependency has a genuine native implementation and the authenticated Discord application mount initializes normally.

Runtime verification of the updated candidate was not completed in this turn because the local execution policy rejected launching the diagnostic GUI process from the shell. The C# project build passed with zero errors. No official Discord process or profile was modified.
