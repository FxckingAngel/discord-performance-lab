# Track B Windows counter fallback follow-up: 2026-10-06

The rooted Windows performance-counter sampler ran against production Track B PID 35172. It collected 13 samples over 290.0 seconds while the process tree remained at seven processes.

## Result

The machine's performance-counter policy exposed no usable process-instance CPU, private-memory, page-fault, or I/O values for this run. It also exposed no per-thread context-switch values. These fields remain `null` in the raw artifact and are not interpreted as zero.

The GPU counters did expose the rooted GPU process. The final sample reported zero GPU-engine utilization and 17.5 MiB of dedicated GPU memory.

Raw artifact: `benchmarks/raw/track-b-foreground-idle-counters-followup-120s-20261006.json`

## Decision

This fallback cannot answer the wakeup-owner question on the current Windows configuration. The process sampler and loopback CDP trace remain the usable evidence sources. ETW/WPR remains the preferred path for scheduler and context-switch attribution, but the earlier WPR attempt was rejected by the system performance-profiling policy.
