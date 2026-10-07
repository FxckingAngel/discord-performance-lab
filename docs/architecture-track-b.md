# Track B architecture: replace the Electron desktop shell

The project now has two tracks:

- Track A measures and researches stock Discord's Electron desktop client.
- Track B evaluates a lightweight standalone Windows shell that hosts Discord's own web client.

The long-term architectural boundary is: replace the Electron desktop shell, not Discord itself.

Track B has two co-equal hard gates: the full-tree performance target and desktop-environment parity. The shell must make Discord's frontend see only desktop capabilities that are genuinely implemented underneath it. It must not rely on a generic browser fallback, blanket Electron spoofing, protocol changes, or manually recreated Discord UI.

## First candidate

The first candidate is a native Windows WinForms host using the installed Microsoft Edge WebView2 Runtime. WebView2 is a testable starting point because it can use a system-serviced Chromium runtime instead of shipping a second complete Electron/Chromium bundle. That is a hypothesis, not a conclusion. WebView2 still creates browser, renderer, GPU, and utility processes, so the entire process tree must be measured.

The first proof of concept is intentionally small:

1. create a native Windows executable;
2. create an isolated WebView2 user-data folder;
3. navigate to `https://discord.com/app`;
4. allow normal interactive login and web navigation;
5. expose only the two tested, origin-restricted capabilities documented in the compatibility matrix;
6. avoid general-purpose host objects, protocol interception, account automation, and security bypasses.

The prototype is in `track-b/discord-shell`. It does not copy the official Discord profile or attempt to migrate credentials. A separate profile is a deliberate rollback and privacy boundary.

Track B's explicit design target is approximately 250 MiB total settled idle private working set / unique private resident RAM and 0.2% total idle CPU for the complete process tree. Private bytes/commit is reported separately and is not a second 250 MiB acceptance requirement. Summed working set and derived shareable working set remain secondary metrics, with shared resident pages kept separate where Windows exposes them. The minimum acceptable gate is under 500 MiB private resident RAM and under 1% CPU with a responsive UI and no major feature loss. The full acceptance contract and feature requirements are in [Track B performance goal](track-b-performance-goal.md). Visual parity is a separate gate documented in [Track B visual parity requirement](track-b-visual-parity.md), and the native capability boundary is documented in [Track B desktop compatibility layer](track-b-desktop-compatibility.md).

## Comparison contract

Track B must use the same machine, display, network state, window size, background applications, account state, channel, and settled duration as Track A. The current machine evidence is 1920x1080 at 60 Hz.

Every comparison counts the full process tree:

| Measure | Stock Discord | Lightweight shell |
| --- | ---: | ---: |
| First usable window | pending | pending |
| Settled working set | pending | pending |
| Settled private memory | pending | pending |
| Idle CPU | pending | pending |
| GPU activity/memory | pending | pending |
| Process count | pending | pending |
| Handles and threads | pending | pending |
| Responsive | pending | pending |

The table above is the original comparison contract. Current rebuilt-shell evidence is now available for Track B but is not an acceptance pass: the latest automated five-repeat unverified run measured 357.27 MiB median private working set and 0.033% median CPU, while the authenticated no-bridge capture measured a higher state-dependent footprint. Same-route pristine-official A/B parity and full functional validation remain pending.

The first milestone is architectural evidence, not feature completeness. The shell must first beat the under-500 MiB minimum on the same logged-in static-channel workload. If it cannot, the project must investigate the process/runtime ownership before investing heavily in native compatibility work.

## Runtime-floor gate

The diagnostic-only blank-page capture on 2026-10-06 measured 380.7 MiB working set and 147.5 MiB private bytes across seven WebView2-shell processes. This is not a Discord benchmark or a private-working-set acceptance result. Later same-build blank measurements were lower, so this historical capture is a runtime-floor observation rather than a fixed floor claim. The current Discord-loaded unauthenticated shell measured 836.2 MiB working set and 557.7 MiB private bytes.

WebView2 remains eligible for the under-500 MiB minimum only if the authenticated same-channel workload clears that gate without feature loss. The latest state-dependent rebuilt-shell captures do not establish that result. The approximately 250 MiB design target requires either a measured reduction in runtime overhead that preserves normal behavior or a different safe shell architecture with a lower full-tree floor. Do not hide this gap with working-set trimming, disabled hardware acceleration, removed media, or security changes.

The current Track A installation is documented as Vencord-patched. Existing official comparisons therefore represent Official Discord + Vencord and cannot isolate an Electron tax. A pristine official reference is required before publishing that comparison.

## Compatibility layer policy

Desktop features are evaluated one at a time after the core web shell has a baseline. For each feature, record what Discord expects, what WebView2 already provides, the smallest native bridge needed if any, the process and memory cost, and the functional result. Candidate areas include notifications, tray behavior, permissions, file dialogs, downloads, drag and drop, screen capture, audio devices, accessibility, deep links, and session persistence.

The normal prototype exposes only the tested window-action and display-count bridges. It must not expose a general-purpose native object to page JavaScript or use a bridge to bypass Discord permissions or account security. Additional features remain disabled until their behavior, origin boundary, process cost, rollback path, and functional result are measured.

## Decision gates

- Large reduction: continue Track B and restore desktop integrations incrementally.
- Moderate reduction: compare WebView2 with another system-runtime architecture before investing in a full compatibility layer.
- Little or no reduction: attribute the cost to the web client/runtime and keep Track B as a documented result.
- Missing critical feature: document the limitation instead of changing Discord's protocol or security model.

## Sources

- [WebView2 WinForms getting started](https://learn.microsoft.com/en-us/microsoft-edge/webview2/get-started/winforms)
- [WebView2 process model](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/process-model)
- [WebView2 platform components](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/platform-components)
- [WebView2 user-data folders](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/user-data-folder)
