# Decision 0002: EcoQoS profile scope

## Status

Accepted for background-idle experiments. Rejected as a universal foreground default.

## Decision

The project may provide a private EcoQoS launch profile using:

```text
--enable-features=UseEcoQoSForBackgroundProcess
```

The profile is intended for a Discord session that remains running while its main window is closed or otherwise idle. The stock launch path remains the default and rollback path.

The profile must not be presented as an official Discord build or as a replacement for normal foreground use until foreground performance and the full functional checklist pass.

## Evidence

Two paired background-idle runs passed the five-percent regression gate. Compared with stock, the EcoQoS profile improved CPU by 75.9% at the median and 72.1% at p95, working-set p95 by 2.4%, and private-memory p95 by 3.5%. Process count stayed at six.

A paired foreground run failed the same gate because CPU increased by 13.8%. The main-window close used to create the background workload is not equivalent to Discord's in-app Quit action, and account-level functionality has not been fully tested.

## Consequences

- The profile can be used for measurable background-idle experiments.
- The stock profile remains the safe default for active Discord use.
- A future change to foreground status requires new paired measurements and full functional acceptance.
- No client files, credentials, protocol behavior, authorization state, update path, or security behavior are changed by this profile.
