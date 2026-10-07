# Korone's Discord Performance Lab

## Project status: Research concluded

This repository preserves an engineering study of Discord desktop resource usage and a lightweight Windows/WebView2 replacement shell. Active development has ended. The project does not claim an optimized official-quality Discord build or a finished alternative client.

This work is unofficial, is not affiliated with or endorsed by Discord, and does not ship Discord proprietary code, binaries, preload bundles, account data, or private user data.

## What the project tested

The original hypothesis was that Electron was the main reason Discord Desktop used substantial memory. Track A measured official Discord. Track B replaced the desktop shell with a native Windows/WebView2 host while continuing to use Discord's own frontend.

The study preserved normal frontend behavior, media quality, hardware acceleration, authentication and network behavior, and security boundaries. It rejected changes that disabled visible media, notifications, voice, video, screen sharing, or other normal functionality.

## Main finding

Replacing Electron reduced some surrounding shell overhead, but it did not remove the largest fully initialized Discord cost. The strongest matched Friends-route evidence recorded approximately:

| Measurement | Private resident working set |
| --- | ---: |
| Pristine official Discord complete tree | 539.56 MiB |
| Track B complete tree | 483.14 MiB |
| Official renderer | 378.99 MiB |
| Track B renderer | 370.68 MiB |

A blank WebView2 shell was much lighter. Loading Discord's complete frontend restored most of the memory cost. Electron contributes overhead, but Discord's frontend and rendering state are the larger limiting factor.

Track B reached very low settled-idle CPU in several controlled runs. CPU was not the limiting metric by the end of the study. Memory and frontend state were.

## Why the 250 MiB target was not reached

The design target was approximately 250 MiB complete-tree settled-idle private resident RAM and 0.2% median CPU. The shell alone could not consistently reach that target while preserving the normal Discord frontend, functionality, media quality, hardware acceleration, and security boundaries.

Further reductions might require changing or replacing Discord frontend behavior. That would introduce licensing, compatibility, maintenance, update-breakage, and redistribution concerns, turning this experiment into a separate unofficial client or frontend fork. The project therefore stops at the research boundary.

## Repository contents

- `track-b/discord-shell/` contains the Windows/WebView2 shell source written for this project.
- `tools/` contains the benchmark and validation scripts.
- `docs/` contains architecture decisions, methodology, sanitized benchmark summaries, and accepted or rejected experiment reports.
- `SECURITY.md` defines the privacy and safety boundary.

Raw ETL captures, heap snapshots, WebView2 profiles, browser caches, screenshots, Discord binaries, copied proprietary source, and account-derived artifacts are excluded from publication.

## Build

On Windows with the .NET SDK and WebView2 runtime installed:

```powershell
.\tools\Build-TrackBShell.ps1
```

The project intentionally keeps the normal shell free of a partial `DiscordNative` object. Isolated native capability experiments are diagnostic evidence only and are not a claim of desktop parity.

## License

The license in this repository applies only to original project code and documentation. It does not grant rights to Discord, Electron, WebView2, or any other third-party software or service.
