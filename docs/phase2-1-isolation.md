# Phase 2.1: stock isolation pass

Phase 2.1 answers why the stock foreground renderer can retain about 1 GiB and sustain several percent of total CPU while the user considers Discord idle. It does not modify Discord, add scheduling flags, or accept an optimization.

## Required repetitions

Run each scenario three times after Discord has settled. Ten minutes is the default duration. The operator must set the visible Discord state before each repetition because the measurement tools do not send messages, join calls, scroll, play media, or change account state.

```powershell
.\tools\Invoke-DiscordPhase21Scenario.ps1 `
  -RootPid 36604 `
  -Scenario static-text-channel `
  -DurationSeconds 600 `
  -IntervalSeconds 5 `
  -Repetitions 3 `
  -RequireReadyEachRepetition `
  -OutputDirectory .\benchmarks\raw\phase2-1\static-text-channel
```

`-RequireReadyEachRepetition` pauses before every repetition and requires the literal `READY` after the operator has restored the exact scenario state. Use it for the static-versus-media gate so route, viewport, call, and media state are explicitly rechecked between runs.

Use these scenario labels:

- `static-dm-or-text`: static DM or text channel, with no call, stream, video, GIF in the viewport, typing, or scrolling;
- `ordinary-server-text`: normal server text channel with ordinary messages;
- `media-heavy`: animated GIFs, stickers, or embeds visible;
- `minimized-static`: the same static channel with the Discord window minimized;
- `settings-untouched`: User Settings left untouched;
- `voice-silent`: connected to voice with nobody talking;
- `voice-active-speech`: connected to voice with active speech.

Each repetition keeps separate `attribution.json`, `windows-counters.json`, and `role-map-local.json` files. The attribution sampler preserves every renderer PID rather than combining renderer rows. Role-level aggregation can be performed later from those raw files. The role map contains command lines and is ignored by Git; it must stay local because launch metadata can contain user-data paths and other sensitive details.

The manifest records the root PID, whether the main window is visible or minimized, the presence of a window title, and the current display adapter refresh rate. The current stock adapter observation is 60 Hz at 1920x1080. A 120 Hz comparison is not available on the currently reported adapter, so no refresh-rate recommendation is made.

## Measurements and interpretation

For every repetition retain:

- renderer count and individual renderer PID;
- working set, private bytes, CPU, page faults, handles, and threads per renderer;
- GPU process working set/private bytes, CPU, GPU engine utilization, and dedicated GPU memory;
- window visibility/minimized state and display refresh rate;
- voice, video, screen-sharing, and media state supplied by the scenario label;
- process role/PID mapping in the local-only artifact.

Compare `static-dm-or-text` with `media-heavy` before selecting an optimization. A large CPU or GPU delta supports an animation, compositor, decode, or media-cache hypothesis. A similar result across static and media-heavy states points toward timers, retained application state, layout work, or another background source. Renderer memory is not labeled JavaScript memory until heap evidence separates V8 from Blink, native Chromium, and GPU/shared allocations.

## Safe Chromium diagnostic research

The current stock PTB launch has no `--remote-debugging-port` or `--inspect` flag, and localhost ports 9222, 9229, and 8315 were not listening in the current check. Electron documents `--remote-debugging-port` as enabling HTTP remote debugging, and the Chrome DevTools Protocol documents `/json/version` and `/json/list` as the discovery endpoints. A future diagnostic run can use a loopback-only port during a controlled restart, then stop the process and restore the stock launch. It must not expose the endpoint beyond localhost.

The diagnostic client must use read-only CDP domains and keep all deep artifacts local and ignored:

- `Runtime.getHeapUsage` for V8 used and total heap;
- `Performance.getMetrics` for document, frame, node, layout, style, task, and script metrics where the target exposes them;
- `DOM.getDocument` and `DOM.getNodeForLocation` only for aggregate node/frame counts, not text or attributes;
- `HeapProfiler.startSampling` and `HeapProfiler.takeHeapSnapshot` only on a disposable private run;
- `Tracing.start` only for short diagnostic windows, with sanitized aggregate findings extracted locally.

The current diagnostic implementation is `Invoke-DiscordPhase2CdpDiagnostics.ps1`. During a loopback-only launch it collects `Runtime.getHeapUsage`, supported `Performance.getMetrics` values, aggregate DOM/image/video/canvas/frame counts, sanitized animated-image hints, playing-video count, video ready-state counts, and a sanitized allocation-sampling summary. The allocation profile itself is never written. Run it only while the temporary debugging port is active:

```powershell
.\tools\Invoke-DiscordPhase2CdpDiagnostics.ps1 `
  -Port 9222 `
  -DurationSeconds 10 `
  -OutputPath .\benchmarks\raw\phase2-1\cdp\aggregate-10s.json
```

Compare the CDP V8 result with the preserved per-renderer process result using `Summarize-DiscordPhase21MemoryBuckets.ps1`. Its residual is a lower bound, not a claim about a specific allocator:

```powershell
.\tools\Summarize-DiscordPhase21MemoryBuckets.ps1 `
  -CdpInputPath .\benchmarks\raw\phase2-1\cdp\aggregate-10s.json `
  -RoleSummaryPath .\benchmarks\raw\phase2-1\cdp\role-summary-30s.json `
  -OutputPath .\benchmarks\raw\phase2-1\cdp\memory-buckets.json
```

Do not call `Runtime.evaluate` to read message contents, tokens, local storage, cookies, or account state. Do not publish heap snapshots or trace payloads. Do not enable a debugging port in the normal launcher. A CDP endpoint is a local control surface, so it must be closed after each run and treated as a diagnostic exception, not a product feature.

The current controlled evidence is recorded in [the blank-versus-loaded CDP/native comparison](benchmarks/track-b-blank-vs-loaded-cdp-native-2026-10-07.md) and [the blank-versus-loaded renderer trace](benchmarks/track-b-blank-vs-loaded-cdp-trace-2026-10-07.md). Those runs show that the loaded renderer adds approximately 293 MiB of private writable resident memory over the blank renderer floor and performs sustained layout, paint, timer, and animation work. They are unverified-route diagnostics, not acceptance results. The next acceptance-quality comparison must use the manual READY workflow above with a static route and a media-heavy route.

The attribution report must keep these buckets separate:

1. V8 JavaScript heap;
2. Blink DOM, layout, and style memory;
3. image, GIF, and media caches;
4. Chromium native allocations;
5. GPU and shared texture allocations;
6. WebRTC, audio, and video allocations.

Official references:

- [Electron command-line switches](https://www.electronjs.org/docs/latest/api/command-line-switches)
- [Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/)
- [Electron application debugging](https://www.electronjs.org/docs/latest/tutorial/application-debugging)
