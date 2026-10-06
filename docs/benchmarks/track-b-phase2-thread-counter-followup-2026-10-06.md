# Track B thread-counter follow-up

Date: 2026-10-06

The Phase 2 Windows counter sampler now has an opt-in `-IncludeThreadCounters` mode. It queries the Windows `Thread(*)` performance object and aggregates `Context Switches/sec` by process ID for rooted Track B descendants.

The first live opt-in run was stopped after the query path exceeded the expected sampling interval. The existing process/GPU sampler was then rerun with thread counters disabled and completed normally in 18.8 seconds for four samples over a requested 15-second window. The thread query is therefore not included by default and cannot distort the established CPU, fault, I/O, GPU, handle, or process-lifetime measurements.

A follow-up attempt to wrap the query in a PowerShell background job was also abandoned: stopping the job did not return promptly. No timeout guarantee is claimed, and the normal sampler was left on the previously validated direct-query implementation.

The opt-in output fields are `threads[].contextSwitchesPerSecond` and `threads[].threadCounterInstances`, with `threadCountersEnabled` recorded at the capture root. Missing or slow thread-counter data must remain explicitly unavailable. A future context-switch capture needs a separate slow-diagnostic schedule or a lower-overhead ETW provider; it must not be compared directly with the normal sampler's timing-sensitive results.

No Discord process, priority, memory policy, security setting, or user state was changed. The failed opt-in run was terminated as a measurement process only.
