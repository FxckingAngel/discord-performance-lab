# Phase 2 status

Date: 2026-10-06

## Completed

- Preserved the Phase 1 rooted benchmark and stock rollback path.
- Added per-process attribution sampling for working set, private memory, paged memory, CPU, page faults, I/O, handles, threads, and lifetime.
- Added role-level aggregation and ranking across multiple renderer or utility instances.
- Added WPR start/stop wrappers for CPU, Disk I/O, GPU, Handle, and Resident Set profiles.
- Added a WebView2 shell architecture research document without implementing or endorsing that architecture.

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

## ETW status

`wpr.exe` is installed, but the local run was denied with Windows error `0xc5585011`, “Failed to enable the policy to profile system performance.” WPA, xperf, and tracelog are not installed. No ETL trace is claimed from this run. The Phase 2 wrappers remain ready for a session with the Windows performance-recording privilege or an installed equivalent ETL reader.

The read-only attribution sampler remains usable without that privilege and is not a substitute for stack-level ETW evidence. It must be run separately for each required scenario.

## Remaining Phase 2 work

1. Capture the full scenario matrix: foreground idle, background idle, text scrolling, voice, video, screen sharing, media-heavy channel, notification, startup, and settled state.
2. Obtain ETW/WPA access or an equivalent trace reader and attribute wakeups, context switches, faults, disk I/O, GPU engines, and process lifetime.
3. Inspect renderer/V8/Blink retention, media/GIF caches, React trees, timers, animation, WebRTC buffers, and GPU texture/cache behavior using safe diagnostic methods.
4. Rank opportunities by measured ownership and test one narrow, reversible change at a time.
5. Keep the repository private and do not call a candidate an official-quality build until the full functional matrix passes.
