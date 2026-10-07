# Track B post-restart Windows-counter follow-up

Date: 2026-10-06

This was a read-only fallback counter capture against the live Track B shell. It collected 13 samples over 64.7 seconds with thread counters disabled. It is supplementary evidence, not an ETW trace and not an authenticated acceptance benchmark.

WPR was attempted first and Windows rejected the recording policy with `0xc5585011`. No system policy was changed. The thread-counter mode was also tested separately, but its query path exceeded the expected interval and was stopped as a measurement process so it could not distort Discord.

The fallback capture retained eight rooted processes. The renderer PID was 5820. Its counter-derived median was approximately 289.99 MiB private working set, 358.50 MiB private bytes, 6.88 page faults/sec, and 220.2 read bytes/sec. GPU counters reported 0% engine utilization for the rooted GPU process and approximately 58.6 MiB dedicated GPU memory in the final sample.

The renderer page-fault rate differs substantially from the direct process sampler's p95 spike in the preceding capture. This is a measurement-method discrepancy, not evidence of paging or a cause. ETW/WPR or a slower dedicated diagnostic schedule is required before interpreting page-fault ownership.

The normal shell remained responsive and no process priority, memory policy, Discord state, or security setting was changed.

Raw capture: `artifacts/track-b-post-restart-counter-followup-60s.json`.
