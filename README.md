# Discord Performance Lab

Discord Performance Lab is a private research project for reducing Discord's resource use while retaining normal user-facing functionality.

The project starts with measurement, not patches. Each proposed change must be compared with stock Discord on the same machine, account, Discord channel state, and workload. A lower RAM number is not a win if it causes missing notifications, broken calls, unreliable media playback, damaged updates, or a poor user experience.

## Goals

- Reduce idle and active RAM use where the data shows a real opportunity.
- Reduce idle and active CPU use without making interaction or media less responsive.
- Reduce cold and warm startup time.
- Reduce unnecessary background processes without removing required functionality.
- Preserve normal Discord features, account safety, updates, accessibility, overlays, voice, video, screen sharing, notifications, and rich media.
- Keep the work auditable, reversible, and private until the build is stable and independently reproducible.

## Non-goals

- Bypassing Discord security, licensing, update, or account controls.
- Automating user accounts or modifying Discord's network protocol in ways that resemble a self-bot.
- DLL injection, arbitrary code injection, anti-cheat bypasses, or patching a running installation without a clear, safe boundary.
- Claiming official status or compatibility before testing supports that claim.

## Project status

This repository contains the project charter, architecture direction, and benchmark plan. No optimized build is claimed yet.

- [Architecture](docs/architecture.md)
- [Benchmark plan](docs/benchmark-plan.md)
- [Stock baseline](docs/baseline-2026-10-05.md)
- [Functional checklist](docs/functional-checklist.md)
- [Stock lifecycle result](docs/functional-results/stock-lifecycle-2026-10-05.md)
- [Experiment 001](docs/experiments/001-low-end-device-mode.md)
- [Experiment 002](docs/experiments/002-disable-breakpad.md)
- [Experiment 003](docs/experiments/003-ecoqos.md)
- [Client boundary decision](docs/decisions/0001-client-boundary.md)
- [EcoQoS profile decision](docs/decisions/0002-ecoqos-profile-scope.md)
- [Security and safety boundary](SECURITY.md)

## Baseline tooling

The first read-only collector is [tools/Measure-DiscordProcessTree.ps1](tools/Measure-DiscordProcessTree.ps1). Example:

```powershell
.\tools\Measure-DiscordProcessTree.ps1 -ProcessName DiscordPTB -DurationSeconds 60 -IntervalSeconds 5 -Scenario idle-observation -OutputPath .\benchmarks\raw\stock-discordptb.json
```

It records process-tree working set, private bytes, CPU time, handles, threads, parent PIDs, and timestamps. Raw benchmark files stay local by default.

For startup timing, use [tools/Measure-DiscordStartup.ps1](tools/Measure-DiscordStartup.ps1). It refuses to launch over an existing instance and records process-tree timing plus the first responsive main window and its title; it still does not prove that every Discord feature is ready.

Use [tools/Compare-DiscordBenchmark.ps1](tools/Compare-DiscordBenchmark.ps1) to apply the regression gate to two generated summaries.

The reproducible private profiles are launched with [tools/Launch-DiscordPerformanceProfile.ps1](tools/Launch-DiscordPerformanceProfile.ps1). The `stock` profile passes no extra switch; the `ecoqos` profile passes only `--enable-features=UseEcoQoSForBackgroundProcess`.

EcoQoS is currently supported only as an experimental background-idle profile. Two paired background runs passed the resource regression gate, but a foreground run showed higher CPU use and full Discord functionality has not been accepted. Do not treat it as a universal replacement for the stock launch. Example:

```powershell
.\tools\Launch-DiscordPerformanceProfile.ps1 -ExecutablePath 'C:\Path\To\DiscordPTB.exe' -Profile ecoqos
```

The stock profile remains the rollback path:

```powershell
.\tools\Launch-DiscordPerformanceProfile.ps1 -ExecutablePath 'C:\Path\To\DiscordPTB.exe' -Profile stock
```

## Evidence standard

Every performance claim should include the stock and candidate build identifiers, workload, machine state, sample count, raw data location, summary statistics, and any functional regressions observed. The benchmark plan defines the first comparison.

## License

No license has been selected yet. The repository remains private while the project scope and implementation boundary are validated.
