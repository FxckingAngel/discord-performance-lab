# Track B integrated resident-page capture

Date: 2026-10-06

## Harness change

`Invoke-TrackBUnverifiedCurrentAttribution.ps1` now accepts an allowlisted diagnostic mode and an opt-in `-CaptureResidentTypes` switch. After the process-tree and CDP capture, it classifies each PID in the final process-tree sample with the read-only `VirtualQueryEx` plus `QueryWorkingSetEx` collector. The output is a sanitized manifest of per-PID result paths and does not include command lines, page content, or account data.

The runner supports:

- `--diagnostic-authenticated-no-bridges` on CDP port 9230
- `--diagnostic-blank` on CDP port 9223

Only those two modes are accepted. Arbitrary process arguments are not passed through.

## Integrated authenticated capture

The first integrated run used a 30-second settle and a 20-second measurement window. Its route and workload were not independently verified, and the short settle produced higher memory and CPU than the long settled baseline. It is harness evidence, not an acceptance result.

The final per-PID resident classification covered all eight processes. The renderer result was:

| Category | Resident |
|---|---:|
| Private writable | 321.60 MiB |
| Private executable | 0.02 MiB |
| Private other protection | 1.00 MiB |
| Mapped | 30.03 MiB |
| Image-backed | 79.34 MiB |

The corresponding process-tree median over the short window was 474.66 MiB private working set, with 0.459% median CPU. The difference between the final page classification and the process-tree median reflects different read times and Windows API accounting; neither should be substituted for the established long settled measurement.

## Next use

Future manually prepared scenario captures can use the same runner and switch to preserve:

1. complete-tree process counters;
2. CDP V8, DOM, media, and native sampling;
3. per-PID resident page categories.

This provides the required fixed-runtime versus Discord-state and feature-transition ledger without injecting arbitrary page code or changing authentication or network behavior.
