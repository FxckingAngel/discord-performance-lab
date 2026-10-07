# Track A isolated official reference installation

Date: 2026-10-07

## Installation result

The verified official stable installer completed successfully. Squirrel ignored
the temporary `LOCALAPPDATA` override and used its normal stable location:

`<local Discord installation>`

That stable tree did not exist before acquisition. It is separate from the
active PTB/Vencord tree:

`<local DiscordPTB installation>`

The installer launched the new stable client on first run. It was not logged in,
and it was stopped after package verification. The active PTB/Vencord client was
not stopped, restarted, modified, or used as a source of profile data.

## Verified package contents

- Release channel: `stable`
- Architecture: Windows x64
- Version: `1.0.9260`
- `resources\app.asar`: present, 3,613,330 bytes
- `resources\app.asar` SHA-256: `F3144E8B8DB5E0EA70E94F41FB2EB3CEFBC4C0C1E5BCC9474DD94225970AB664`
- `modules\discord_desktop_core-2\discord_desktop_core\core.asar`: present, 1,722,352 bytes
- `core.asar` SHA-256: `32C40C40CCCB48F8756933E75D04E99274E79FA7DD5FF3D72E10F7EAA8580AEB`
- Stable process tree after cleanup: none
- Active PTB process tree: left running
- Authentication performed: no
- Installed-tree filename scan: no `Vencord`, `BetterDiscord`, `patcher`, or
  plugin paths found

The required native desktop-core payload is present. This removes the missing-
native-module limitation from the earlier extracted `1.0.9260` package. The
filename scan is supporting evidence only; it does not inspect archive contents
or replace the later runtime provenance check.

## Remaining pristine gate

Package completeness and path isolation are now verified. The reference is not
yet an authenticated performance baseline. Before benchmarking, verify the
stable package's runtime provenance, use a fresh stable profile, log in manually
if authorized, and establish the same route, window, display, and workload as
Track B. Keep the active PTB/Vencord profile separate and untouched.

Raw installer, profile, process command lines, and account artifacts remain
private and are not committed.
