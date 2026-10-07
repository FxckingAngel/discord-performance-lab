# Track B renderer lifecycle capture tooling

Date: 2026-10-07  
Status: implemented and focused-validated; no production behavior changed

## Purpose

`tools/Invoke-TrackBRendererLifecycleCapture.ps1` adds a separate diagnostic-only lifecycle capture for the current Track B shell. It records the transition from a blank WebView2 document through Discord navigation, application-shell readiness, a manually confirmed canonical route, and one-, five-, and ten-minute settled checkpoints.

Each checkpoint preserves:

- complete-tree samples from the existing process sampler, including one row per PID, role, parent PID, working set, private working set, private bytes, CPU, page faults, I/O, handles, threads, lifetime, window state, and display state;
- aggregate CDP values for V8 heap usage, DOM counters, selected performance metrics, document/frame/image/video/canvas counts, and the conservative Discord readiness predicate;
- a read-only `VirtualQueryEx` and `QueryWorkingSetEx` capture for every renderer PID and GPU PID present in the final process sample, including committed/resident type totals and largest private-writable allocation-base groups.

The default process-capture interval is one second inside the five-second checkpoint window. This yields multiple samples for CPU and process-state summaries instead of relying on a single interval-sized sample.

The supplied canonical URL is validated as an HTTPS Discord URL and used only for local navigation. It is not written to the output. Raw output remains under the caller's local artifact directory.

## Safety and gating

The tool launches only `--diagnostic-authenticated-no-bridges` on a lifecycle-specific CDP port. It refuses to run while a Track B shell is already open, asks for `CAPTURE` unless `-Automatic` is used, and asks for `READY` before the canonical-route checkpoint unless `-Automatic` is used. Application checkpoints require the existing aggregate readiness predicate: Discord route class, complete document, populated `#app-mount`, and at least 2,000 DOM elements.

It does not modify the normal shell, expose a partial `DiscordNative` object, clear caches, force garbage collection, trim working sets, alter media behavior, write credentials, export page content, or interact with official Discord. The blank checkpoint is a diagnostic runtime-floor state and cannot count as an application performance result.

## Validation performed

Focused validation ran against the new files:

1. PowerShell parsed `Invoke-TrackBRendererLifecycleCapture.ps1` with no syntax errors.
2. Node syntax checking passed for `Probe-TrackBRendererLifecycleCdp.mjs`.
3. `-PlanOnly` produced the seven expected checkpoints: blank, navigation, application-shell, canonical-route, settled-1m, settled-5m, and settled-10m.
4. The plan confirmed the diagnostic launch argument, canonical-route redaction, and the no-cache/no-GC/no-trim policy.

The full seven-checkpoint capture was not run in this validation pass because it requires replacing the current Track B shell for up to ten minutes and a user-confirmed authenticated route. No official Discord process was stopped or changed.
