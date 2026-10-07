# Phase 2: resource attribution and deeper profiling

## Scope

Phase 2 keeps the Phase 1 benchmark harness and stock rollback path. It does not add more scheduling switches. The purpose is to identify which process and workload own CPU wakeups, memory, I/O, GPU work, and long-lived allocations before any deeper optimization is attempted.

The installed machine exposes `wpr.exe` and `logman.exe`. WPA, xperf, and tracelog are not installed, so WPR records are created locally and require WPA or an equivalent ETL reader for graph-level inspection. The wrappers are read-only with respect to Discord: they start and stop system tracing, and they never change Discord files, settings, account state, or network behavior.

## Per-process attribution

Run the rooted sampler against a known Discord root PID:

```powershell
.\tools\Measure-DiscordPhase2Attribution.ps1 `
  -RootPid 12345 `
  -DurationSeconds 600 `
  -IntervalSeconds 5 `
  -Scenario foreground-idle-10m `
  -OutputPath .\benchmarks\raw\phase2\foreground-idle-10m.json
```

Each sample reports sanitized role, PID, parent PID, process lifetime, working set, private memory, paged memory, handles, threads, CPU percent of total, page faults per second, and read/write I/O rates. It follows only the selected root and descendants. Raw output contains no command lines, account identifiers, message contents, tokens, or crash data.

For Windows performance-counter evidence that complements the sampler, run:

```powershell
.\tools\Measure-DiscordPhase2WindowsCounters.ps1 `
  -RootPid 12345 `
  -DurationSeconds 600 `
  -IntervalSeconds 5 `
  -Scenario foreground-idle-10m `
  -OutputPath .\benchmarks\raw\phase2\foreground-idle-10m\windows-counters.json
```

This records process-instance CPU, private and private working-set bytes, page faults, read/write I/O, and thread count. It also maps the Windows GPU Engine utilization and GPU Process Memory counters back to rooted PIDs. Counter instances are sampled read-only and may be absent on a machine with different drivers or performance-counter policy. The counter file is supplementary; it does not replace an ETW trace or provide call stacks and context-switch attribution.

Summarize and rank ownership by role:

```powershell
.\tools\Summarize-DiscordPhase2Attribution.ps1 `
  -InputPath .\benchmarks\raw\phase2\foreground-idle-10m\attribution.json `
  -OutputPath .\benchmarks\raw\phase2\foreground-idle-10m\role-summary.json
```

The summarizer combines multiple renderer or utility instances by role before calculating medians and p95 values. The working-set rank is an opportunity ranking, not proof that the allocation is removable.

For a paired Track B rooted tree and sanitized CDP diagnostic, use `tools/Summarize-TrackBCdpAttribution.ps1`. It reports the final process-tree totals, renderer/GPU private ownership, measured V8 heap, and the renderer private-memory lower bound outside measured V8. The lower bound is intentionally not labeled Blink or native memory until a stronger attribution method proves that split.

The Phase 1 active voice baseline provides an initial attribution hypothesis:

| Role | Approximate working set observed | Initial opportunity rank |
| --- | ---: | --- |
| Renderer | 605–695 MiB | 1 |
| Browser/main | 176–179 MiB | 2 |
| GPU | 149–157 MiB | 3 |
| Audio service | 58 MiB | 4 for voice-specific work |
| Network service | 68 MiB | 5 |
| Crashpad | 36 MiB | 6 |

These are single-session observations, not allocation attribution. The renderer owns most of the active footprint and is the first place to investigate retained channel history, image/GIF caches, React trees, timers, animation, and V8/Blink memory. GPU and WebRTC-related work must be separated from ordinary renderer memory before proposing a change.

## ETW/WPR tracing

Start a trace after the target process is ready:

```powershell
.\tools\Start-DiscordPhase2Trace.ps1 `
  -RootPid 12345 `
  -OutputDirectory .\benchmarks\raw\phase2\foreground-idle-10m `
  -SessionName KoroneDiscordForegroundIdle
```

Stop it after the scenario and keep the ETL private:

```powershell
.\tools\Stop-DiscordPhase2Trace.ps1 `
  -OutputPath .\benchmarks\raw\phase2\foreground-idle-10m\trace.etl `
  -SessionName KoroneDiscordForegroundIdle
```

The wrapper requests WPR's CPU, Disk I/O, GPU, Handle, Resident Set, and Heap profiles. WPR's CPU profile supplies sampled CPU and scheduler context; the process sampler supplies rooted per-process counters and lifetime. The trace review must extract:

- CPU samples by process, thread, and stack;
- context switches, ready time, and wakeup-heavy threads;
- hard/page faults and resident-set changes;
- disk and file I/O by process;
- GPU engine activity and process ownership;
- working set, private bytes, handles, and threads;
- process creation, exit, and lifetime.

WPR is an ETW recorder, not a Discord-specific profiler. All graphs must be filtered to the rooted Discord PID tree after capture. A trace that cannot be tied to the root PID and scenario is not evidence for an optimization decision.

## Required scenario matrix

Each scenario needs a stock run first and a candidate run second, with the same account state, channel state, display, power mode, and background applications. Manual checkpoints are allowed; sending messages or joining calls must remain user-controlled.

| Scenario | Duration | Required observations |
| --- | ---: | --- |
| Foreground idle | 10 minutes | settled memory, CPU samples, wakeups, faults |
| Background idle | 10 minutes | minimized/hidden behavior, wakeups, resident set |
| Text/channel scrolling | fixed history and scroll path | renderer CPU, heap growth, paint/compositor work |
| Voice call | 10 minutes | audio service, renderer, network, faults, latency notes |
| Video call | 10 minutes | camera, GPU, renderer, audio, network, GPU engines |
| Screen sharing | 10 minutes | capture, encoder/GPU, renderer, network, frame stability |
| GIF/video/media-heavy channel | fixed media set | cache growth, GPU, disk I/O, decode work |
| Notification receive/open | controlled notification | wakeups, renderer work, notification latency |
| Startup and settled state | startup plus 10 minutes | process lifetimes, first window, settled ownership |

## Attribution decision rule

Rank opportunities by resident/private memory ownership, sustained CPU samples, wakeup density, page-fault cost, I/O volume, and functional scope. A large allocation is not automatically removable. The next decision must identify:

1. the owning process and workload;
2. the measured resource and time window;
3. the likely mechanism, such as retained objects, media cache, WebRTC buffer, timer, or GPU texture;
4. the smallest safe experiment;
5. the rollback and functional checks.

No Phase 2 optimization is accepted from a single trace or a 2–4% change. The first target is an explanation of the renderer's large footprint and the wakeup sources that sustain it.

## Current Track B evidence: 2026-10-07

The latest unverified-route attribution measured 403.65 MiB complete-tree private working set median and 0.084% median CPU. The renderer accounted for 300.14 MiB private working set, 0.084% median CPU, 59 median page faults per second, and 2,451 page faults per second at p95. A matched blank-versus-loaded diagnostic comparison measured 69.72 MiB versus 416.69 MiB private working set, leaving an approximately 347 MiB loaded delta. V8 used heap was approximately 102 MiB, so the remaining renderer delta cannot be called JavaScript memory.

## Lifecycle attribution gate

The current settled baseline is approximately 310.18 MiB complete-tree private working set, 254.92 MiB renderer private working set, and 0.016% median CPU. CPU is below the current idle target and is not the active optimization bottleneck. The next renderer subgoal is approximately 195 MiB private working set, which would leave the non-renderer footprint near the 250 MiB complete-tree target.

Short steady-state VirtualAllocation traces are interval evidence only. They cannot explain allocations acquired before the trace began. The next attribution question is therefore when the renderer acquires its retained footprint. `tools/Invoke-TrackBLifecycleAttribution.ps1` records synchronized process-tree, aggregate CDP, and renderer virtual-memory checkpoints from WebView endpoint readiness through Discord load, session restoration, application-shell visibility, a manually confirmed static route, and settled 30-second, 60-second, and five-minute states. Raw artifacts remain private. The blank runtime floor remains a separate `--diagnostic-blank` measurement.

For each checkpoint, compare renderer private working set and private bytes with V8 used/backing storage, DOM/frame counts, GPU memory, and the private-writable allocation-base groups. A group that appears during Discord load and changes with a media route is Discord-dependent evidence. A group that appears during WebView initialization and remains fixed across blank, static, and media states is runtime-floor evidence. Neither result alone authorizes a renderer change; the first optimization still requires a repeatable, attribution-backed A/B.

`Measure-TrackBResidentMemoryTypes.ps1` now emits `allocationBaseGroups` directly alongside the detailed region list. These groups are a per-process resident correlation view, not allocator ownership and not cross-process unique-RAM accounting.

The loaded aggregate trace recorded sustained animation-frame, paint, style/layout, timer, and microtask activity while the blank trace did not. The current interpretation is a renderer-owned workload involving retained Discord state and Blink/compositor/native work. It is not yet safe to attribute the allocation to one removable feature. The next acceptance-quality gate is three repeated manually confirmed static-channel captures paired with three media-heavy captures, retaining per-renderer PIDs and the aggregate CDP media fields.

## Sources

- [WPR command-line options](https://learn.microsoft.com/en-us/windows-hardware/test/wpt/wpr-command-line-options)
- [WPR built-in recording profiles](https://learn.microsoft.com/en-us/windows-hardware/test/wpt/built-in-recording-profiles)
- [Recording for resource-based analysis](https://learn.microsoft.com/en-us/windows-hardware/test/wpt/recording-for-resource-based-analysis)
- [WPR/ETW sessions](https://learn.microsoft.com/en-us/windows-hardware/test/wpt/sessions)
- [Electron process model](https://www.electronjs.org/docs/latest/tutorial/process-model)
