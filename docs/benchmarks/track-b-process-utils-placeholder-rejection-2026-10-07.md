# Track B processUtils placeholder rejection

Date: 2026-10-07

The isolated atomic boot-contract candidate still marks
`processUtils.setMemoryInformation` as a placeholder. This report records why
that path is not being implemented as the next desktop capability.

## Evidence

The candidate's existing genuine process utility methods are read-only host
queries for processor count, current process CPU usage, and process uptime.
The unresolved method is different: its name and observed argument shapes
describe a setter, not a read-only query. The current candidate does not have
a source-backed native owner, exact argument contract, return contract, or
failure behavior for it.

The remaining atomic candidate also has unresolved IPC methods and requests
native voice, utility, and compression modules. Its activation probe leaves
the application mount empty. The candidate is therefore rejected as a whole;
adding a guessed implementation for one setter would not establish a valid
desktop contract.

## Rejection

Do not implement `setMemoryInformation` as a no-op. That would preserve a
placeholder while changing frontend control flow. Do not map it to Windows
working-set trimming, memory priority, paging, or another process-control API.
Those operations would change the benchmark and could reduce memory by
altering residency rather than reducing allocations.

No production bridge or normal-shell behavior was changed. The correct next
step is to obtain a source-backed method contract from a pristine desktop
reference, or to prove that the frontend can complete without this path. An
isolated read-only process utility can be tested independently, but it does
not authorize exposing a partial `DiscordNative` root.

Raw preload observations and native-module files remain local and private.
