# Architecture direction

## Principle

The safest path is to work at a supported application boundary and keep the stock Discord installation intact. The first implementation phase is therefore an evidence and harness phase. It does not assume that rebuilding or modifying Discord is permitted, practical, or necessary.

## Candidate layers

### 1. Measurement harness

The harness launches a selected Discord build, records its process tree, collects resource samples, timestamps readiness milestones, and exports raw data plus metadata. It must identify processes by PID and creation time rather than by process name alone.

Measurements should use Windows process APIs or the `Process V2` performance counter set where available. Working set is useful for resident RAM, but it is a momentary view and must not be treated as the application's complete memory cost. Private bytes, process count, and the process tree should be reported alongside it.

### 2. Workload driver

The driver defines repeatable scenarios without automating account behavior or sending messages as a bot. Initial scenarios are:

- launch and idle on the normal home view;
- browse a text channel and scroll history;
- play and stop a short media item;
- join and leave a voice call;
- use screen share only when the test machine and account support it;
- receive a notification and return to the app.

Each scenario has a fixed duration, a readiness condition, and a cleanup step. Manual checkpoints are acceptable for flows that cannot be safely automated.

### 3. Candidate build boundary

Candidate changes must have a clear private distribution and rollback story. A performance-only local client experiment is allowed by Decision 0001, but it must preserve the stock launch path and must not access credentials, tokens, private messages, encrypted transport, authorization state, or feature entitlements. Do not weaken update or signature checks as a way to make a prototype run.

The first candidate is an external Chromium launch switch, not a package rewrite. If a later candidate needs a client-side patch, keep it isolated, source-controlled, reversible, and limited to measurable performance work.

Before implementation, the project will verify the current Discord client distribution terms and any applicable API or developer requirements. The result belongs in a project decision record.

The current boundary is recorded in [Decision 0001](decisions/0001-client-boundary.md). The installed Discord client is treated as an external dependency, not as source code for this repository.

### 4. Functional verification

Performance tests are not sufficient. A candidate is rejected when it loses or degrades ordinary Discord behavior, including authentication, server and channel navigation, messaging, notifications, voice, video, screen sharing, media, accessibility, settings, updates, and clean uninstall or rollback.

## Proposed repository layout

```text
docs/
  architecture.md
  benchmark-plan.md
  decisions/
benchmarks/
  raw/
  summaries/
src/
tests/
tools/
  Measure-DiscordProcessTree.ps1
  Measure-DiscordStartup.ps1
  Compare-DiscordBenchmark.ps1
  Launch-DiscordPerformanceProfile.ps1
```

The initial repository intentionally contains no client-modification code. The benchmark harness should land before optimization changes so that every later change has a baseline.

The current collector is read-only. It observes an already running process tree and does not change Discord files, settings, network behavior, or account state.

## Decision gates

1. Baseline data is repeatable across at least three runs per scenario.
2. A candidate has a documented boundary and rollback path.
3. Performance changes are statistically and practically meaningful, not noise from startup or memory trimming.
4. Functional verification passes for the supported scope.
5. Packaging, update behavior, and recovery are tested before wider use.
