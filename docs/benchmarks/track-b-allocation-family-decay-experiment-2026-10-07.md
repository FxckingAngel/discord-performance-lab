# Track B allocation-family decay experiment

Status: implemented as a read-only diagnostic; no capture was started in this change because it requires two caller-supplied Discord routes and restarts only the Track B shell.

## Question

The existing lifecycle and media-transition reports show large private-writable renderer families during Discord initialization and a roughly 50 MiB renderer increase while a media-visible route is active. This experiment separates two cases without assigning an owner from address ranges alone:

- a family that expands during media and returns close to its static baseline is a media/compositor-dependent candidate;
- a family that remains close to its static baseline throughout the return curve is a persistent settled candidate.

## Capture design

`Invoke-TrackBAllocationFamilyDecay.ps1` keeps one diagnostic renderer alive and records five checkpoints:

1. `static-before`
2. `media-visible`
3. `static-after-30s`
4. `static-after-120s`
5. `static-after-300s`

At each checkpoint it stores aggregate CDP counters, complete-tree per-process samples, and read-only `VirtualQueryEx`/`QueryWorkingSetEx` maps for the renderer and GPU process. The orchestrator rejects the run if the renderer PID changes. Raw maps remain local. The CDP output omits URLs, page text, account data, IDs, tokens, cookies, and media pixels.

The companion `Summarize-TrackBAllocationFamilyDecay.ps1` hashes allocation-base values only for same-renderer correlation and emits sanitized family sizes. It ranks families by media delta and labels them with a conservative diagnostic heuristic. The labels are candidates, not allocator ownership claims.

## Interpretation rule

The classifier requires at least an 8 MiB media increase. A family is a `media/compositor-dependent candidate` when its 300-second value returns to within the larger of 4 MiB or 25% of its media increase from the static baseline. A family that starts at least 8 MiB and remains within that same tolerance of its static baseline is a `persistent settled candidate`. Other families are reported as residual or unresolved.

These thresholds are intended to exceed the observed map noise, not to prove byte ownership. The result must be correlated with the CDP image/video counts, GPU private and mapped resident memory, and complete-tree private working set before any optimization is proposed.

## Safety

This experiment does not clear caches, force garbage collection, trim working sets, disable media or GPU acceleration, change image quality, alter authentication or protocol behavior, or modify official Discord. It does not make a production change. The `finally` path restores the normal Track B shell after a capture.

Plan validation:

```powershell
pwsh -NoProfile -File .\tools\Invoke-TrackBAllocationFamilyDecay.ps1 `
  -StaticUrl https://discord.com/channels/@me `
  -MediaUrl https://discord.com/channels/@me `
  -PlanOnly
```

A real capture requires the exact manually confirmed static and media routes and the explicit `-AllowNormalShellRestart` switch. Official Discord does not need to be stopped or changed.
