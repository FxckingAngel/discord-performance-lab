# Track A pristine reference package

Date: 2026-10-07

## Package acquisition

The first legacy download URL returned an access error. The current official
Discord download page exposes the stable x64 installer through the distribution
endpoint below. The installer was downloaded to the private, untracked staging
directory:

`benchmarks/private/pristine-reference-20261007/DiscordSetup.exe`

The file was not executed, installed, opened, or used to modify the active
Discord installation.

## Sanitized provenance

- Channel: Official stable Windows x64
- Package version in the official redirect: `1.0.9260`
- Embedded file version: `1.0.9260`
- Embedded product version: `1.0.9260`
- Embedded product/company: `Discord - https://discord.com/` / `Discord Inc.`
- Size: 146,031,032 bytes
- SHA-256: `BE1DEE4C52227F743BC277A33A47620B6FF119E1387FE899205A8FE5D6575A90`
- Authenticode status: Valid
- Signer: Discord Inc.
- Active official/Vencord installation touched: No
- Installer executed: No

Sources:

- https://discord.com/download
- https://discord.com/api/downloads/distributions/app/installers/latest?arch=x64&channel=stable&platform=win

## Gate status

This closes package acquisition and signature verification only. It does not
prove that the installer can be installed into an isolated directory, that its
native modules match its host, or that the resulting frontend is pristine at
runtime. Do not benchmark it or authenticate it yet.

The next step is a separately approved isolated installation/profile check. It
must not select the active PTB/Vencord directory, copy cookies or profile data,
or restart the user's active official Discord client. The existing pristine
reference gate remains open until the complete package and native-module set
are verified.
