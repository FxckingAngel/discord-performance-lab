# Track B Phase 2 Windows counter capture

Date: 2026-10-06

This is a read-only fallback counter capture from the current authenticated Track B shell. It supplements the private-memory and CDP attribution work. It is not an ETW/WPR trace and does not provide call stacks or thread-wakeup attribution.

## Capture

- Scenario: authenticated settled shell, untouched during capture
- Root PID: 38760
- Duration: 123.8 seconds
- Requested interval: 5 seconds
- Samples: 25
- Process-tree count: 7 at every sample
- Raw data: `benchmarks/raw/track-b-phase2-windows-counters-20261006.json`
- Counter rows: 22 observations per PID. Three samples had no resolved performance-counter row; those values are preserved as unavailable and were excluded from medians and percentiles.

The process roles were preserved separately in the raw capture. The tree was the native shell, WebView2 browser, one renderer, GPU process, network utility, storage utility, and crashpad.

## Results

- GPU engine utilization: 0% median and 0% p95 in the sampled counter values.
- Dedicated GPU memory: 17.49 MiB median.
- Process-tree page faults: 0 median. The highest observed per-process p95 values were 125.80 faults/sec for the WebView2 browser process, 143.49 for the renderer, and 8.91 for the GPU process. These are short-lived sampled rates, not sustained averages.
- Process-tree I/O: 0 median read and write bytes/sec for all roles. The largest single counter value was 43,558 bytes/sec, so the capture does not show sustained disk activity.
- Median thread counts: browser 57, renderer 28, GPU 47, network utility 23, storage utility 9, shell 12, crashpad 11.
- No process appeared or disappeared during the capture.

## Interpretation

This settled sample does not support disk I/O, GPU engine saturation, process churn, or sustained hard-fault activity as the cause of the remaining private-bytes gap. It also does not explain thread wakeups or CPU call stacks. The current evidence still points to resident renderer/runtime allocations rather than an active background workload, so renderer attribution remains the next optimization gate.

The missing counter rows are a measurement limitation. They are not converted to zero. A future ETW/WPR run, if Windows tracing policy permits it, is still required for reliable wakeup, context-switch, and stack attribution.

## Safety and scope

No Discord files, authentication state, network protocol, sandbox setting, hardware-acceleration setting, working set, or process priority was changed. The shell was not restarted for this capture.
