# Benchmark plan

## Purpose

Compare stock Discord with a candidate build on the same Windows installation and workload. The first milestone is a trustworthy baseline, not a target percentage.

## Test matrix

Record these fields for every run:

- date and local time;
- Windows version and build;
- CPU, logical processor count, RAM, GPU, display refresh rate, power mode;
- Discord channel/build identifier and launch arguments;
- account state and test server/channel identifiers, stored locally and redacted from published summaries;
- network condition and whether other heavy applications are closed;
- candidate commit or package hash;
- scenario name and run number.

Use at least three cold-start runs and three warm-start runs for each build and scenario. Increase the sample count when run-to-run variance is larger than the observed improvement.

## Scenarios

### Idle

Start Discord, wait for the fixed ready condition, then observe for 10 minutes without interaction. Report the median and p95 of the steady-state window after excluding startup.

### Background idle

Start Discord, wait for the fixed ready condition, close only the main window, and observe the remaining process tree for the fixed interval. Treat this as a separate workload from foreground idle. It may evaluate scheduling profiles intended for background work, but it does not prove that Discord's in-app Quit action works or that foreground behavior is preserved.

### Active text use

Navigate through a fixed set of text channels, scroll a fixed amount of history, and receive a controlled notification. Observe CPU, memory, process count, and responsiveness during the scenario.

### Media use

Play a fixed short media item, stop it, and measure the active and settled periods. Record playback, audio, and notification failures separately from resource numbers.

### Voice and screen sharing

Run only when the test environment supports the feature. Record join time, reconnects, audio/video quality, and screen-share startup in addition to resource data.

### Startup

Measure from process launch to a defined ready event. Report cold start after a reboot or equivalent clean state separately from warm start after a prior launch. Do not use an arbitrary fixed sleep as the only readiness signal.

## Metrics

| Metric | Collection rule | Interpretation |
| --- | --- | --- |
| Working set | Per-process samples, summed by PID tree | Resident RAM at the sample time; affected by OS trimming |
| Private bytes | Per-process samples, summed by PID tree | Memory private to the process tree |
| CPU | Process CPU time deltas over wall time, normalized by logical processors | Use medians and p95; distinguish idle from active windows |
| Process count | Live PIDs belonging to the launch tree | Count, names, and lifetime should be retained |
| Startup time | Launch timestamp to each readiness milestone | Report cold and warm distributions |
| Responsiveness | Input-to-visible-result timings for fixed actions | Guards against trading resource use for lag |
| Functional result | Pass/fail checklist per scenario | Any required-feature failure blocks acceptance |

Windows performance counters are sampled no faster than their supported diagnostic use warrants. When using process counters, prefer `Process V2` on Windows 11 to avoid instance-name collisions. For high-detail diagnosis, use a trace-based profiler rather than treating one-second counters as a profiler.

## Procedure

1. Reboot or establish the documented clean state.
2. Confirm power mode, display state, network, and background applications.
3. Launch the selected build through the same path.
4. Capture the process tree using PID and creation time.
5. Wait for the scenario's readiness condition.
6. Collect raw samples for the fixed window.
7. Run the functional checklist while the scenario is active.
8. Close Discord normally and verify all child processes exit within the allowed cleanup window.
9. Save raw data, environment metadata, and a human-readable summary.

## Reporting

Summaries must include median, p95, minimum, maximum, sample count, and the stock-to-candidate delta. Use absolute differences and percentages, but do not call a change meaningful unless it exceeds measurement noise and does not regress a protected function.

Do not publish account identifiers, message contents, tokens, crash dumps, or raw traces containing private data. Keep raw files private by default and publish only redacted summaries after review.

## Acceptance gates

A candidate can move beyond local experimentation only when:

- all required baseline scenarios complete without harness errors;
- no protected Discord function is missing or degraded;
- startup and cleanup are repeatable;
- resource changes are reproduced on a second run set;
- a background-only improvement is not promoted to a foreground or universal profile;
- rollback restores the stock behavior;
- the result is documented with raw-data references and known limitations.

## Sources

- [GitHub: Quickstart for repositories](https://docs.github.com/en/repositories/creating-and-managing-repositories/quickstart-for-repositories)
- [Microsoft: About performance counters](https://learn.microsoft.com/en-us/windows/win32/perfctrs/about-performance-counters)
- [Microsoft: Collecting performance data](https://learn.microsoft.com/en-us/windows/win32/perfctrs/collecting-performance-data)
- [Microsoft: Process Working Set](https://learn.microsoft.com/en-us/windows/win32/memory/process-working-set)
- [Microsoft: Reference sets](https://learn.microsoft.com/en-us/windows-hardware/test/wpt/wpa-reference-set)
