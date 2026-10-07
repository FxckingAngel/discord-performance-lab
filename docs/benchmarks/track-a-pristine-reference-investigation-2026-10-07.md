# Pristine Official Discord reference investigation

Date: 2026-10-07

## Result

The isolated extracted host is an authentic Discord Windows x64 package, but it cannot currently serve as a pristine runnable reference. The host package is missing the native module payload that its own bootstrap manifest requires, and the official module service returned no versions for this host build.

The control is therefore **blocked by an unavailable official dependency**. It is not valid to copy native modules or frontend state from the installed Discord PTB/Vencord tree and call the result pristine.

No Track B code, the active Discord installation, or the active Discord process was changed for this investigation. No newly downloaded binary was launched in this workstream.

## Verified host package

The extracted package reports:

```text
releaseChannel: stable
version: 1.0.9260
sentryDist: stable-win-x64
```

The installer and extracted `Discord.exe` both pass Windows Authenticode verification with signer `Discord Inc.` and certificate thumbprint `6C7552617E892DFCA5CEB96FA2870F4F1904820E`.

| Item | SHA-256 |
| --- | --- |
| `DiscordSetup-1.0.9260.exe` | `BE1DEE4C52227F743BC277A33A47620B6FF119E1387FE899205A8FE5D6575A90` |
| extracted `Discord.exe` | `DD3D7B9A55893153084BC75FC57436C792394705BB30CC7D5B80AC08CBE79B51` |
| extracted `resources/app.asar` | `F3144E8B8DB5E0EA70E94F41FB2EB3CEFBC4C0C1E5BCC9474DD94225970AB664` |

The extracted host is not itself evidence of a clean Discord frontend comparison. It contains the signed Electron/bootstrap host and `_app.asar`-equivalent bootstrap code, but no native module ZIPs.

## Native module evidence

The host's signed `resources/app.asar` contains this bootstrap manifest:

```json
{
  "discord_desktop_core": 0,
  "discord_erlpack": 0,
  "discord_notifications": 0,
  "discord_spellcheck": 0,
  "discord_utils": 0,
  "discord_voice": 0,
  "discord_zstd": 0
}
```

The official full package contains `resources/bootstrap/manifest.json`, but no `resources/bootstrap/<module>.zip` files and no installed `discord_*` module directories. This matches the host's module-loader design: bootstrap modules are installed from the resource directory when bundled, and later module versions are downloaded into the isolated per-host `modules` directory.

The isolated attempt created an updater log under the private diagnostic profile. Its sanitized outcome was:

- module install path: the isolated profile's versioned `modules` directory;
- bootstrap attempt: all seven module ZIP paths were absent;
- legacy module endpoint: `https://discord.com/api/modules/stable/versions.json`;
- response for `host_version=1.0.9260`: HTTP 200 with `{}`;
- result: no module update was available, so `discord_desktop_core` remained unavailable.

The signed bundle also contains the module URL construction used by the host:

```text
versions: https://discord.com/api/modules/stable/versions.json?host_version=<host>&_=<five-minute-bucket>
download: https://discord.com/api/modules/stable/<module>.x64/<version>?host_version=<host>
```

It contains a newer updater fallback rooted at `https://updates.discord.com/`, but the direct versions request for this old host returned HTTP 404 during this investigation. Neither endpoint supplied a usable module version for `1.0.9260`.

## Why the installed PTB tree is not a valid substitute

The existing `DiscordPTB\app-1.0.1223\modules` directory does contain official-looking native modules, including `discord_desktop_core`, but it belongs to a different PTB host build and the installed client is the user's Vencord-patched comparison target. Copying those files into the isolated stable tree would mix:

- stable host `1.0.9260` with PTB host `1.0.1223`;
- different release channels;
- different module versions and native ABI expectations;
- a modified local Discord environment into the proposed pristine control.

That would not establish a clean official reference, even if the process happened to start.

## Safe path if the reference is resumed

The only acceptable assembly path is to obtain a current official Discord package for one release channel, verify its Authenticode signature and build metadata, and let that package's own updater populate a new isolated profile. The resulting reference must be checked for:

- matching host and native-module versions;
- no Vencord, BetterDiscord, plugin, or injected patcher files;
- no reuse of the active user's Discord profile or credentials;
- signed host and recorded hashes for the exact files used;
- successful startup and a clean module inventory before any benchmark.

Launching that isolated installer or host requires a separate explicit approval. Until then, the exact `1.0.9260` control remains blocked by the unavailable module dependency. Do not copy from the active PTB/Vencord installation and do not publish an official-versus-Track-B comparison as pristine.

## Read-only state refresh

The available local Discord installation is still only:

```text
<local DiscordPTB installation>
```

Read-only inspection on 2026-10-07 found:

- `DiscordPTB.exe` is Authenticode-valid and signed by Discord Inc. with the previously recorded thumbprint.
- The installation contains `resources\app.asar`, `resources\_app.asar`, and `resources\bootstrap\manifest.json`.
- The bootstrap manifest requires seven native modules, while the installed `modules` directory contains PTB module directories from the active installation.
- The installed PTB package archive contains the host, `resources\app.asar`, and the bootstrap manifest, but no bundled native-module ZIP payloads.
- No separate clean Discord installation or complete same-build stable package was found in the existing local installation and package locations.
- No Discord binary was launched, stopped, restarted, patched, or modified during this refresh.

This does not change the control decision. The PTB tree remains unsuitable as a pristine reference because it is the user's Vencord-modified environment, and its native modules cannot be transplanted into another host without creating a mixed-build control. The clean same-build reference therefore remains unavailable without obtaining and explicitly launching a complete official package in a new isolated profile.
