# Decision 0004: evaluate a lightweight standalone shell

Date: 2026-10-06

Status: accepted for research and prototype work

## Decision

The project will continue Track A stock Discord/Electron measurement and begin Track B, a private lightweight standalone Windows shell that hosts Discord's own official web client. The architectural boundary is to replace the Electron desktop shell, not Discord itself.

WebView2 is the first candidate because the machine already has the Evergreen Runtime installed and the runtime can be shared instead of bundling another complete Electron/Chromium distribution. WebView2 is not assumed to be the final architecture. The decision depends on full process-tree measurements and functional checks.

The explicit Track B design target is approximately 250 MiB total settled idle working set and 0.2% total idle CPU across the complete process tree. The minimum acceptable result is under 500 MiB and under 1% CPU with normal responsiveness and no major feature loss. The strong and stretch levels, measurement formula, and feature gate are defined in `docs/track-b-performance-goal.md`.

## Constraints

Track B must preserve normal official web-client behavior and must not recreate Discord's backend, alter its protocol, bypass authentication or entitlements, automate accounts, disable security protections, or redistribute Discord code or binaries. The repository remains private during development.

The first shell has no native bridge, injected scripts, protocol interception, or account-data migration. It uses a separate WebView2 user-data folder. Desktop integrations are added only after their requirement, safety boundary, measured resource cost, rollback path, and functional result are documented.

## Runtime-floor evidence

The first WebView2 runtime-floor capture used `about:blank` in a separate diagnostic profile and measured 380.7 MiB working set across the complete tree. The Discord-loaded unauthenticated shell measured 836.2 MiB in the latest rooted sample. These results do not replace the required authenticated A/B benchmark, but they show that the approximately 250 MiB design target cannot be assumed from replacing Electron with WebView2. The full evidence is in `docs/benchmarks/track-b-runtime-floor-2026-10-06.md`.

## Evidence so far

The first native shell built and opened a responsive window. Its corrected full process tree reached nine processes during startup. A short unauthenticated settled run measured about 1,058 MiB median working set and 839 MiB median private memory. This does not beat stock yet and cannot be compared fairly until both applications use the same logged-in account and channel state.

Track A remains authoritative for stock baselines. Its existing benchmark, rollback, attribution, and functional-checklist work is retained.

## Next gate

Run the same logged-in controlled workload against stock Discord and the shell, count every child process, and compare startup, settled working set, private memory, CPU median and p95, GPU activity, process count, handles, threads, responsiveness, and functional pass/fail. Track B must first clear the under-500 MiB minimum before substantial compatibility-layer work is justified. Only a result that also preserves the required functionality moves Track B beyond the prototype.

If the authenticated WebView2 result cannot clear the minimum, stop adding compatibility features to that prototype and evaluate a different safe runtime architecture. If it clears the minimum but remains materially above the design target, keep the result provisional and measure another runtime before calling the architecture validated.
