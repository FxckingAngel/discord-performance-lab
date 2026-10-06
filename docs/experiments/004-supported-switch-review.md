# Experiment 004: supported switch review

## Status

No additional candidate accepted.

## Review

The current Discord PTB client uses Electron 42.11.10. The official Electron switch list was reviewed for a safe foreground or background resource reduction:

- `--disable-http-cache` changes network and cache behavior. It is not a RAM-safe optimization and could increase network work.
- `--disable-renderer-backgrounding` explicitly prevents Chromium from lowering the priority of invisible renderers, which conflicts with the background-idle goal.
- `--no-sandbox` disables renderer and helper-process sandboxing. It is outside the project boundary and rejected without testing.
- `--force_low_power_gpu` changes graphics-device selection rather than reducing Discord work in a generally predictable way. This machine exposes only one adapter, an NVIDIA GeForce RTX 5060, so there is no lower-power adapter for the switch to select. It is excluded without testing.
- `--disk-cache-size` changes persistent cache policy, not the process-tree resource target, and could trade memory for network and disk work.
- Remote debugging and inspector switches add an exposed control surface and are not optimization candidates.

Electron states that unsupported command-line switches have no effect and that Chromium flags vary by the embedded Chromium version. The project therefore keeps the tested EcoQoS switch as the only current candidate and does not add speculative flags.

## `--disable-gpu` measurement

The switch was tested against the installed Discord PTB 1.0.1223 executable after an authorized restart. The main window appeared in 1.290 seconds and remained responsive. The process tree stabilized in 12.517 seconds at six processes, including a `gpu-process` role, so the switch did not meet the process-count objective. A short rooted sample recorded about 1,529.7 MiB working set and 1,108.6 MiB private memory at the final sample. No voice, video, messaging, or media action was performed during this candidate run.

Discord was then closed and relaunched without the switch. The stock rollback stabilized in 12.098 seconds at six processes with a responsive `@xoxo - Discord` window. The raw evidence is retained locally at `benchmarks/raw/disable-gpu-startup.json`, `benchmarks/raw/disable-gpu-stable.json`, and `benchmarks/raw/stock-after-disable-gpu-rejection.json`.

## Sources

- [Electron supported command line switches](https://www.electronjs.org/docs/latest/api/command-line-switches)
- [Chromium feature and switch guidance](https://www.electronjs.org/docs/latest/api/command-line-switches#chromium-features-relevant-to-electron-apps)

## Decision

No additional switch is accepted until a candidate has a clear security boundary, a supported interpretation for Electron 42.11.10, a rollback path, and paired performance and functional evidence.
