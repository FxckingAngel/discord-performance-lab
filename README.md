# Korone's Discord Performance Lab

Korone's Discord Performance Lab is a private research project for evaluating a lightweight Discord desktop shell while retaining normal user-facing functionality.

The project starts with measurement, not patches. Each proposed change must be compared with stock Discord on the same machine, account, Discord channel state, and workload. A lower RAM number is not a win if it causes missing notifications, broken calls, unreliable media playback, damaged updates, or a poor user experience.

## Goals

- Reduce idle and active RAM use where the data shows a real opportunity.
- Reduce idle and active CPU use without making interaction or media less responsive.
- Reduce cold and warm startup time.
- Reduce unnecessary background processes without removing required functionality.
- Preserve normal Discord features, account safety, updates, accessibility, overlays, voice, video, screen sharing, notifications, and rich media.
- Keep the work auditable, reversible, and private until the build is stable and independently reproducible.
- Track B design target: approximately 250 MiB complete-tree settled idle private working set / unique private resident RAM and 0.2% total idle CPU. Private bytes are reported separately and are not a second 250 MiB acceptance requirement.

## Non-goals

- Bypassing Discord security, licensing, update, or account controls.
- Automating user accounts or modifying Discord's network protocol in ways that resemble a self-bot.
- DLL injection, arbitrary code injection, anti-cheat bypasses, or patching a running installation without a clear, safe boundary.
- Claiming official status or compatibility before testing supports that claim.

## Architecture tracks

- [Track B architecture decision](docs/architecture-track-b.md)
- [Track B performance goal](docs/track-b-performance-goal.md)
- [Track B visual parity requirement](docs/track-b-visual-parity.md)
- [Track B desktop compatibility layer](docs/track-b-desktop-compatibility.md)
- [Track B shell prototype](track-b/discord-shell/README.md)
- [Track B unauthenticated shell baseline](docs/benchmarks/track-b-unauthenticated-shell-2026-10-06.md)
- [Track B WebView2 runtime floor](docs/benchmarks/track-b-runtime-floor-2026-10-06.md)

## Project status

This repository contains the project charter, architecture direction, and benchmark plan. No optimized build is claimed yet.

- [Architecture](docs/architecture.md)
- [Benchmark plan](docs/benchmark-plan.md)
- [Stock baseline](docs/baseline-2026-10-05.md)
- [Functional checklist](docs/functional-checklist.md)
- [Functional result record template](docs/functional-results/README.md)
- [Stock lifecycle result](docs/functional-results/stock-lifecycle-2026-10-05.md)
- [Experiment 001](docs/experiments/001-low-end-device-mode.md)
- [Experiment 002](docs/experiments/002-disable-breakpad.md)
- [Experiment 003](docs/experiments/003-ecoqos.md)
- [Supported switch review](docs/experiments/004-supported-switch-review.md)
- [Rooted process QoS experiment](docs/experiments/005-process-qos-control.md)
- [Process-tree audit](docs/process-tree-2026-10-06.md)
- [Adaptive background QoS experiment](docs/experiments/006-adaptive-background-qos.md)
- [Client boundary decision](docs/decisions/0001-client-boundary.md)
- [EcoQoS profile decision](docs/decisions/0002-ecoqos-profile-scope.md)
- [Adaptive profile scope decision](docs/decisions/0003-adaptive-profile-scope.md)
- [Track B shell pivot decision](docs/decisions/0004-track-b-shell-pivot.md)
- [Memory-priority experiment](docs/experiments/007-memory-priority.md)
- [Background memory-priority profile](docs/experiments/008-memory-background-profile.md)
- [Current active voice-session baseline](docs/benchmarks/stock-active-voice-current-2026-10-06.md)
- [Current stock restart baseline](docs/benchmarks/stock-restart-current-2026-10-06.md)
- [Security and safety boundary](SECURITY.md)
- [Current project status](docs/status-2026-10-06.md)
- [Phase 2 resource attribution plan](docs/phase2-resource-attribution.md)
- [Phase 2.1 stock isolation pass](docs/phase2-1-isolation.md)
- [Phase 2 status](docs/phase2-status-2026-10-06.md)
- [WebView2 shell architecture research](docs/research/webview2-shell-architecture.md)
- [Track B feature-scenario checkpoint](docs/benchmarks/track-b-feature-scenario-checkpoint-2026-10-06.md)
- [Track B cross-process page accounting](docs/benchmarks/track-b-cross-process-page-accounting-2026-10-06.md)
- [Track B current private-writable refresh](docs/benchmarks/track-b-current-private-writable-refresh-2026-10-06.md)
- [Track B live renderer region attribution](docs/benchmarks/track-b-live-region-attribution-2026-10-06.md)
- [Track B repeated blank WebView2 floor](docs/benchmarks/track-b-release-blank-floor-repeated-2026-10-06.md)
- [Track B authenticated frontend delta refresh](docs/benchmarks/track-b-release-authenticated-delta-refresh-2026-10-06.md)
- [Track B blank-to-authenticated region delta](docs/benchmarks/track-b-blank-auth-region-delta-2026-10-06.md)
- [Track B authenticated reload probe](docs/benchmarks/track-b-authenticated-reload-probe-2026-10-06.md)
- [Track B browser-target native sampling boundary](docs/benchmarks/track-b-browser-native-sampling-2026-10-06.md)
- [Track B WPR privilege boundary](docs/benchmarks/track-b-wpr-privilege-boundary-2026-10-06.md)
- [Track B elevated WPR capture](docs/benchmarks/track-b-elevated-wpr-capture-2026-10-06.md)
- [Track B WPR tracerpt summary](docs/benchmarks/track-b-wpr-tracerpt-summary-2026-10-07.md)
- [Track B live memory refresh](docs/benchmarks/track-b-live-memory-refresh-2026-10-07.md)
- [Track B blank versus loaded resident delta](docs/benchmarks/track-b-blank-loaded-resident-delta-2026-10-07.md)
- [Track B renderer private-region leaders](docs/benchmarks/track-b-renderer-private-region-leaders-2026-10-07.md)
- [Track B CDP allocation-sampling boundary](docs/benchmarks/track-b-cdp-sampling-boundary-2026-10-07.md)
- [Track B paired renderer memory ledger](docs/benchmarks/track-b-renderer-memory-ledger-2026-10-07.md)
- [Track B renderer attribution ledger tool](tools/Summarize-TrackBRendererAttributionLedger.ps1)
- [Track B WPR heap-snapshot research](docs/benchmarks/track-b-wpr-heap-snapshot-research-2026-10-07.md)
- [Track B renderer WPR heap snapshot](docs/benchmarks/track-b-wpr-heap-snapshot-2026-10-07.md)
- [Track B post-heap-snapshot health check](docs/benchmarks/track-b-post-heap-snapshot-health-2026-10-07.md)
- [Track B WPR native-allocation ownership report](docs/benchmarks/track-b-wpr-native-ownership-report-2026-10-07.md)
- [Track B repetition variance analysis](docs/benchmarks/track-b-repetition-variance-2026-10-07.md)
- `tools/Decode-TrackBWprHeapSnapshot.ps1` decodes sanitized WPR heap-stack aggregates
- `tools/Invoke-TrackBSettledAttribution.ps1` gates measurements on a stable renderer/GPU memory window
- [Track B post-WPR settled baseline](docs/benchmarks/track-b-post-wpr-settled-baseline-2026-10-07.md)
- [Track B decoded WPR summary](docs/benchmarks/track-b-wpr-decoded-summary-2026-10-06.md)
- [Track B rooted WPR capture](docs/benchmarks/track-b-rooted-wpr-capture-2026-10-06.md)
- [Track B rooted WPR follow-up process baseline](docs/benchmarks/track-b-rooted-wpr-followup-process-tree-2026-10-06.md)
- [Track B current native memory breakdown](docs/benchmarks/track-b-current-native-memory-breakdown-2026-10-06.md)
- [Track B authenticated CDP/native follow-up](docs/benchmarks/track-b-authenticated-cdp-native-followup-2026-10-06.md)
- [Track B WebView2 memory API research](docs/benchmarks/track-b-webview2-memory-api-research-2026-10-06.md)
- [Track B rooted WPR PID-filtered evidence](docs/benchmarks/track-b-rooted-wpr-pid-filter-2026-10-06.md)
- [Track B renderer-native memory decision](docs/decisions/track-b-0021-renderer-native-floor.md)
- [Track B current post-restart follow-up](docs/benchmarks/track-b-current-unverified-followup-2026-10-07.md)
- [Track B current unverified 10-minute settling observation](docs/benchmarks/track-b-current-unverified-settling-2026-10-07.md)
- [Track B current native resident-memory breakdown](docs/benchmarks/track-b-current-native-breakdown-2026-10-07.md)
- [Track B current CDP/native attribution](docs/benchmarks/track-b-current-cdp-native-attribution-2026-10-07.md)
- [Track B blank versus loaded CDP/native comparison](docs/benchmarks/track-b-blank-vs-loaded-cdp-native-2026-10-07.md)
- [Track B blank versus loaded renderer trace](docs/benchmarks/track-b-blank-vs-loaded-cdp-trace-2026-10-07.md)
- [Track B current minimized isolation](docs/benchmarks/track-b-current-minimized-isolation-2026-10-07.md)
- [Track B current Phase 2 attribution](docs/benchmarks/track-b-current-phase2-attribution-2026-10-07.md)
- [Track B post-rebuild live baseline](docs/benchmarks/track-b-post-rebuild-live-baseline-2026-10-07.md)
- [Track B post-rebuild renderer classification](docs/benchmarks/track-b-post-rebuild-renderer-types-2026-10-07.md)
- [Track B post-rebuild full-tree native classification](docs/benchmarks/track-b-post-rebuild-full-native-types-2026-10-07.md)
- [Track B blank versus authenticated resident types](docs/benchmarks/track-b-blank-vs-authenticated-resident-types-2026-10-07.md)
- [Track B CDP memory boundary](docs/benchmarks/track-b-cdp-memory-boundary-2026-10-07.md)
- [Track B Verified blank floor](docs/benchmarks/track-b-verified-blank-floor-2026-10-07.md)
- [Track B Release versus Verified blank-floor comparison](docs/benchmarks/track-b-release-versus-verified-blank-floor-2026-10-07.md)
- [Track B Verified-build smoke results](docs/benchmarks/track-b-verified-build-blank-smoke-2026-10-07.md)
- [Track B Verified normal-shell baseline](docs/benchmarks/track-b-verified-normal-baseline-2026-10-07.md)
- [Track B Verified authenticated diagnostic attribution](docs/benchmarks/track-b-verified-authenticated-unverified-attribution-2026-10-07.md)
- [Track B Verified authenticated long-settle attribution](docs/benchmarks/track-b-verified-authenticated-unverified-long-2026-10-07.md)
- [Track B Verified post-attribution restore check](docs/benchmarks/track-b-verified-post-restore-2026-10-07.md)
- [Track B Verified sanitized heap summary](docs/benchmarks/track-b-verified-heap-summary-2026-10-07.md)
- [Track B renderer heap-to-resident boundary](docs/benchmarks/track-b-renderer-heap-to-resident-boundary-2026-10-07.md)
- [Track B live current attribution](docs/benchmarks/track-b-live-current-attribution-2026-10-07.md)
- [Track B renderer memory classification](docs/benchmarks/track-b-renderer-memory-classification-2026-10-07.md)
- [Track B renderer memory ledger](tools/Summarize-TrackBRendererMemoryLedger.ps1)
- [Track B renderer boundary capture](tools/Invoke-TrackBRendererMemoryBoundary.ps1)
- [Track B resident-region module correlation](tools/Correlate-TrackBResidentRegions.ps1)
- [Track B paired renderer boundary evidence](docs/benchmarks/track-b-renderer-boundary-paired-2026-10-07.md)
- [Track B live settled 120-second baseline](docs/benchmarks/track-b-live-settled-120s-2026-10-07.md)
- [Track B WebView2 memory API research](docs/benchmarks/track-b-webview2-memory-api-research-2026-10-07.md)
- [Track B reload and settled-state comparison](docs/benchmarks/track-b-current-reload-long-2026-10-07.md)
- [Track B pre-manual-gate baseline](docs/benchmarks/track-b-current-pre-manual-gate-2026-10-07.md)
- [Track B elevated WPR capture helper](tools/Run-TrackBWprCapture.ps1)
- [Track B WPR aggregate summarizer](tools/Summarize-TrackBWprEtw.ps1)
- [Track B ETL PID filter](tools/Invoke-TrackBEtlPidFilter.ps1)

## Baseline tooling

The first read-only collector is [tools/Measure-DiscordProcessTree.ps1](tools/Measure-DiscordProcessTree.ps1). Example:

```powershell
.\tools\Measure-DiscordProcessTree.ps1 -ProcessName DiscordPTB -DurationSeconds 60 -IntervalSeconds 5 -Scenario idle-observation -OutputPath .\benchmarks\raw\stock-discordptb.json
```

It records process-tree working set, private bytes, CPU time, handles, threads, parent PIDs, creation times, and timestamps. When a root PID is supplied, the collector follows only that PID and its descendants instead of every process with the same executable name:

```powershell
.\tools\Measure-DiscordProcessTree.ps1 -ProcessName DiscordPTB -RootPid 12345 -DurationSeconds 60 -IntervalSeconds 5 -Scenario idle-observation -OutputPath .\benchmarks\raw\stock-discordptb-rooted.json
```

Raw benchmark files stay local by default.

For startup timing, use [tools/Measure-DiscordStartup.ps1](tools/Measure-DiscordStartup.ps1). It refuses to launch over an existing instance and records process-tree timing plus the first responsive main window and its title; it still does not prove that every Discord feature is ready.

For a read-only view of the current launch profile, process count, root command line, and main-window responsiveness, use [tools/Get-DiscordPerformanceProfileState.ps1](tools/Get-DiscordPerformanceProfileState.ps1). It does not restart or modify Discord.

Use [tools/Compare-DiscordBenchmark.ps1](tools/Compare-DiscordBenchmark.ps1) to apply the regression gate to two generated summaries.

The reproducible private profiles are launched with [tools/Launch-DiscordPerformanceProfile.ps1](tools/Launch-DiscordPerformanceProfile.ps1). The `stock` profile passes no extra switch; the `ecoqos` profile passes only `--enable-features=UseEcoQoSForBackgroundProcess`; the opt-in `adaptive` profile launches stock Discord and attaches the background QoS watcher.

EcoQoS is currently supported only as an experimental background-idle profile. Two paired background runs passed the resource regression gate, but a foreground run showed higher CPU use and full Discord functionality has not been accepted. Do not treat it as a universal replacement for the stock launch. Example:

```powershell
.\tools\Launch-DiscordPerformanceProfile.ps1 -ExecutablePath 'C:\Path\To\DiscordPTB.exe' -Profile ecoqos
```

The adaptive profile keeps foreground use system-managed and applies EcoQoS only while the window is minimized or hidden:

```powershell
.\tools\Launch-DiscordPerformanceProfile.ps1 -ExecutablePath 'C:\Path\To\DiscordPTB.exe' -Profile adaptive -BackgroundIdleConfirmed
```

The confirmation is required because a minimized Discord window can still have an active call or media session.

The opt-in `memory-low` profile uses the same visible-versus-background boundary, applying low memory priority only after the main window has appeared and then been minimized or hidden. It restores normal priority when the window is visible:

```powershell
.\tools\Launch-DiscordPerformanceProfile.ps1 -ExecutablePath 'C:\Path\To\DiscordPTB.exe' -Profile memory-low -BackgroundIdleConfirmed
```

This profile is experimental. It is not the default and has not passed the full voice, video, messaging, media, notification, accessibility, settings, and cleanup checklist.

The stock profile remains the rollback path:

```powershell
.\tools\Launch-DiscordPerformanceProfile.ps1 -ExecutablePath 'C:\Path\To\DiscordPTB.exe' -Profile stock
```

For a live process-tree QoS experiment, use an observed root PID and keep the rollback command ready:

```powershell
.\tools\Set-DiscordProcessQoS.ps1 -RootPid 12345 -Mode ecoqos
.\tools\Set-DiscordProcessQoS.ps1 -RootPid 12345 -Mode system-managed
```

To inspect the current memory-priority hints without changing Discord, use [tools/Get-DiscordProcessMemoryPriority.ps1](tools/Get-DiscordProcessMemoryPriority.ps1):

```powershell
.\tools\Get-DiscordProcessMemoryPriority.ps1 -RootPid 12345
```

For a paired, reversible background-idle experiment, use [tools/Invoke-DiscordMemoryPriorityExperiment.ps1](tools/Invoke-DiscordMemoryPriorityExperiment.ps1). It requires explicit idle confirmation and restores normal priority before returning:

```powershell
.\tools\Invoke-DiscordMemoryPriorityExperiment.ps1 -RootPid 12345 -Priority low -BackgroundIdleConfirmed -OutputDirectory .\benchmarks\raw
```

## Building Track B

Use `tools/Build-TrackBShell.ps1` to build from a clean temporary source copy. By default it uses the portable SDK under `.tools/dotnet` and writes verified output under the ignored `track-b/discord-shell/bin/Verified` directory. The clean copy avoids stale generated files and does not need to stop a running shell instance.

## Evidence standard

Every performance claim should include the stock and candidate build identifiers, workload, machine state, sample count, raw data location, summary statistics, and any functional regressions observed. The benchmark plan defines the first comparison.

## License

No license has been selected yet. The repository remains private while the project scope and implementation boundary are validated.
