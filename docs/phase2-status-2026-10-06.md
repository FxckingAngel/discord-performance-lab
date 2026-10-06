# Phase 2 status

Date: 2026-10-06

## Completed

- Preserved the Phase 1 rooted benchmark and stock rollback path.
- Added per-process attribution sampling for working set, private memory, paged memory, CPU, page faults, I/O, handles, threads, and lifetime.
- Added role-level aggregation and ranking across multiple renderer or utility instances.
- Added a Windows performance-counter sampler for process CPU, memory, page faults, I/O, threads, GPU engine utilization, and dedicated GPU memory by rooted PID.
- Added the Phase 2.1 repeatable isolation runner, local-only role/PID command-line map, window-state and display-refresh capture, and localhost-only CDP diagnostics.
- Added WPR start/stop wrappers for CPU, Disk I/O, GPU, Handle, and Resident Set profiles.
- Added a WebView2 shell architecture research document without implementing or endorsing that architecture.
- Added Track B's architecture decision, native WebView2 shell prototype, full-descendant process-tree measurement, and a non-comparable unauthenticated baseline.

## First attribution evidence

The six-sample `phase2-startup-settled-smoke-fixed` sample followed stock Discord PTB root PID 36604. At the final settled observation, the rooted tree contained seven processes, including two renderer instances.

| Role | Working-set median | Private-memory median | CPU median |
| --- | ---: | ---: | ---: |
| renderer, combined | 1,530.92 MiB | 1,380.92 MiB | 4.33% |
| gpu-process | 270.61 MiB | 459.56 MiB | 2.14% |
| browser | 188.08 MiB | 121.70 MiB | 0.11% |
| audio service | 94.23 MiB | 10.75 MiB | 0.04% |
| network service | 69.57 MiB | 21.16 MiB | 0.00% |
| crashpad-handler | 38.88 MiB | 9.35 MiB | 0.00% |

This sample identifies renderer retention and GPU/private allocation as the first Phase 2 research targets. It does not identify which JavaScript object, cache, texture, or WebRTC buffer owns those bytes.

A longer foreground-idle stock sample followed the same root for 13 samples over 70.093 seconds. Its role ranking was:

| Role | Working-set median | Private-memory median | CPU median |
| --- | ---: | ---: | ---: |
| renderer, combined | 1,207.96 MiB | 1,056.77 MiB | 4.85% |
| gpu-process | 265.80 MiB | 452.37 MiB | 2.25% |
| browser | 189.22 MiB | 121.85 MiB | 0.10% |
| audio service | 94.32 MiB | 10.78 MiB | 0.07% |
| network service | 69.58 MiB | 21.00 MiB | 0.00% |
| crashpad-handler | 39.05 MiB | 9.45 MiB | 0.00% |

This confirms the renderer and GPU as the first attribution targets in a settled foreground-idle workload. The raw sample is local at `benchmarks/raw/phase2/foreground-idle-60s-stock/`.

## Current Windows-counter evidence

A short read-only counter capture against the still-running stock root PID 36604 found seven rooted processes. The renderer PID 33552 was the dominant process in both samples at about 1,450 MiB private working set and about 1,581 MiB private bytes. Its CPU samples were 6.24% and 4.80% of total system capacity, with page-fault rates of 9,602.69 and 8,338.47 per second. The GPU process PID 6024 reported 2.62% to 8.56% aggregate engine utilization and about 313 to 388 MiB dedicated GPU memory across the two samples.

The counter capture is stored at `benchmarks/raw/phase2/current-foreground-counters-2026-10-06/windows-counters-fixed.json`. It is a short current-state observation, not the required 10-minute scenario result. The process and GPU mappings are now available for longer scenario captures without changing Discord state.

## Phase 2.1 diagnostic evidence

The ordinary stock launch had no `--remote-debugging-port` or `--inspect` flag, and ports 9222, 9229, and 8315 were closed. A controlled diagnostic-only restart with `--remote-debugging-port=9222` exposed one local page target for the first probe. The aggregate CDP capture reported:

- V8 heap used: 153.64 MiB;
- V8 heap capacity: 167.23 MiB;
- 5,797 performance nodes and 13 documents/frames;
- 2,044 JavaScript event listeners;
- 120 image elements, 3 video elements, and 4 canvas elements in the aggregate DOM query;
- zero active RTCPeerConnections at capture time;
- 25 allocation samples over 10 seconds, summarized locally without writing the profile.

The same diagnostic-only session had a single renderer at about 610 MiB median working set and 522 MiB median private memory over a 30-second sampler run. That is not directly comparable to the earlier 1 GiB renderer result because the channel/media state was not operator-labeled and the renderer tree changed across restarts. The diagnostic port was then removed, the ordinary stock launch was restored, and the restored process was responsive with six processes and no listening port.

This is useful separation evidence, not an optimization result. The Phase 2.1 seven-scenario matrix still requires three operator-labeled repetitions per scenario, and no renderer or GPU change has been made.

A paired Track B diagnostic launch on the same date ended with an eight-process tree at about 661.9 MiB working set and 364.1 MiB private bytes. Its renderer held 187.5 MiB private bytes while CDP reported 54.68 MiB V8 heap used, leaving at least roughly 133 MiB of renderer private residual outside measured V8 heap. The paired state had 1,174 DOM nodes, 695 JavaScript listeners, three image elements, no video elements, and no active RTCPeerConnections. This is unauthenticated evidence and narrows the next attribution work to Blink/native Chromium/resource allocations, but it is not sufficient to select an optimization.

A diagnostic-only CDP garbage-collection probe repeated three times released 39.2–40.6 MiB of renderer private bytes while V8 used heap fell by about 6.9 MiB each time. This is a lead for allocator/retention research, not permission to force collection in the normal shell. No GC or working-set trimming has been added to Track B.

The sanitized memory-bucket report for the diagnostic run separates 153.641 MiB of measured V8 heap from 521.73 MiB renderer private memory. The arithmetic leaves a 368.0 MiB non-V8 renderer residual lower bound. It is intentionally labeled unresolved and may include Blink, native Chromium, decoded media, shared buffers, or other allocations.

## ETW status

`wpr.exe` is installed, but the local run was denied with Windows error `0xc5585011`, “Failed to enable the policy to profile system performance.” WPA, xperf, and tracelog are not installed. No ETL trace is claimed from this run. The wrapper now requests the built-in profile names exposed by this Windows build: `CPU`, `DiskIO`, `GPU`, `Handle`, `ResidentSet`, and `Heap`. A session with the Windows performance-recording privilege or an installed equivalent ETL reader is still required to produce the trace.

The read-only attribution sampler remains usable without that privilege and is not a substitute for stack-level ETW evidence. It must be run separately for each required scenario.

## Remaining Phase 2 work

1. Capture the full scenario matrix: foreground idle, background idle, text scrolling, voice, video, screen sharing, media-heavy channel, notification, startup, and settled state.
2. Obtain ETW/WPA access or an equivalent trace reader and attribute wakeups, context switches, faults, disk I/O, GPU engines, and process lifetime.
3. Inspect renderer/V8/Blink retention, media/GIF caches, React trees, timers, animation, WebRTC buffers, and GPU texture/cache behavior using safe diagnostic methods.
4. Rank opportunities by measured ownership and test one narrow, reversible change at a time.
5. Keep the repository private and do not call a candidate an official-quality build until the full functional matrix passes.
