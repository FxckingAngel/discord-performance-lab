# Track B performance and acceptance goal

Date: 2026-10-06

## Primary goal

Build a standalone Discord desktop shell that preserves essentially all normal Discord functionality while using dramatically fewer resources than official Discord.

The shell must replace the Electron desktop container, not Discord's web client, backend, authentication, authorization, or network behavior. Every resource result counts the complete application process tree, including the native host, every WebView2 helper, renderer, network service, audio service, GPU process, and crash handler.

The shell must also meet the separate [visual parity requirement](track-b-visual-parity.md). Discord's frontend must render the Discord application area, and the authenticated result must be visually and functionally almost indistinguishable from official desktop Discord under the same controlled state.

It must also provide a minimal, audited [desktop compatibility layer](track-b-desktop-compatibility.md). Discord's frontend must recognize only desktop capabilities that Track B genuinely implements underneath it. Capability reporting cannot be used to spoof unsupported Electron APIs or security state.

The design target is approximately **250 MiB of total settled idle private working set / unique private resident RAM and 0.2% total idle CPU** on the current comparison machine. This is a target for the whole Track B application, not only its main executable. Private bytes/commit is an additional diagnostic metric, not a second 250 MiB acceptance requirement. The ordinary summed working set and derived shareable working set remain required secondary metrics, but shared resident pages must not be counted repeatedly when judging the primary physical-RAM target.

## Current workflow status

**Track B goal: ACTIVE**

**Authenticated Track B checkpoint: CAPTURED; official same-route A/B pairing and parity validation pending**

An earlier prepared-session result measured 243.64 MiB median and 244.05 MiB p95 private bytes, 153.87 MiB median and 166.45 MiB p95 private working set, and 0.001% median/p95 CPU across seven processes. This is retained as historical diagnostic evidence, but it does not validate the current general client because the state was not shown to be a fully initialized equivalent Discord workload and private bytes are not the primary RAM KPI.

Later rebuilt-shell captures supersede that prepared-session result for current-state reporting. The repeated blank-shell floor measured 74.05 MiB median private working set and 145.64 MiB median private bytes. A later authenticated-no-bridge capture measured 608.82 MiB median private working set and 778.18 MiB median private bytes, with 341.91 MiB renderer private working set. A 30-second live-shell capture measured 427.4 MiB complete-tree private working set. These later captures were not manually verified same-route acceptance benchmarks, but they show that the earlier low prepared-session result is state-dependent and must not be treated as the current general Track B pass.

The authenticated benchmark is a manual UI checkpoint, not a blocked project goal. Use `tools/Invoke-TrackBManualCheckpoint.ps1` to launch or reuse Track B, then manually log in, navigate to the requested channel or DM, leave the state ready, and type `READY`. The script then measures the existing Track B process tree without UI automation. Official Discord does not need to be closed for this workflow.

Use `tools/Invoke-TrackBFunctionalCheckpoint.ps1` for the feature gate after the shell is visibly ready. It requires exactly one responsive Track B process before prompting for sanitized PASS, FAIL, or UNTESTED results, and records the root PID and window state. It cannot produce a functional report for a missing or unresponsive shell.

The final gate is `tools/Test-TrackBAcceptance.ps1`. It requires a complete Track B summary with private-working-set median and p95 at or below the resident-memory limit, CPU median at or below 0.2%, an all-PASS functional report, and a visual report with every comparison condition confirmed, screenshots present, and an explicit visual-review PASS. Private bytes and CPU p95 remain required reported metrics and are preserved in the gate output, but they are corroborating evidence rather than separate replacements for the primary resident-memory and settled-idle CPU criteria. Missing evidence produces a failed gate rather than being interpreted as success.

The minimized-WebView visibility candidate is documented separately in [Experiment 012](experiments/012-webview-visibility-candidate.md). It passed executable smoke tests but did not materially change settled foreground resource use, and its authenticated functional matrix is still unverified. The current `Verified` production binary remains the comparison baseline.

A 10-minute unauthenticated natural-idle diagnostic on 2026-10-06 reached a 221.95 MiB median private working set and 0.072% median total CPU, but its private-bytes median was 331.29 MiB and its p95 private working set was 266.93 MiB. This is encouraging runtime-floor evidence only; it does not satisfy the authenticated same-channel acceptance gate.

## Fully initialized benchmark gate

No Track B result counts toward acceptance merely because the Discord URL loaded. Before measurement, the benchmark must record a stable renderer PID, a synchronized WebView2 process inventory, a manually confirmed exact Discord route, a visibly loaded frontend, completed navigation/session restoration, a stable process count, and an unchanged route for the full settle and measurement interval. The checkpoint must confirm the intended Discord state without recording message, account, token, or command-line content. Incomplete states such as the earlier approximately 113 MiB authenticated diagnostic are initialization evidence only.

## Official reference policy

The current PTB installation is Vencord-patched. Its measurements must be labeled **Official Discord + Vencord** and must not be used to publish an exact Electron or desktop-container tax. Before calculating that delta, establish a pristine Official Discord reference using the same account, exact route, frontend state, window and display, activity, duration, and machine conditions as Track B. Historical results remain in the repository, but non-comparable or incompletely initialized results are explicitly superseded for acceptance decisions.

## Target levels

| Level | Settled idle private/unique resident RAM, full tree | Total idle CPU | Required behavior |
| --- | ---: | ---: | --- |
| Minimum acceptable | under 500 MiB | under 1% | Responsive UI and no major feature loss |
| Strong goal | 250–350 MiB | about 0.1–0.5% | Fast startup and normal responsiveness |
| Stretch goal | 150–250 MiB | effectively 0% | No noticeable difference from official Discord during normal use |
| Design target | about 250 MiB | about 0.2% | Preserve normal functionality and avoid artificial trimming |

These levels are judged after the same account is logged in, the same static channel is visible, the window has settled for the same duration, and the same background conditions are present. Record total working set, private working set, native shareable working set when Windows exposes it, and private bytes/commit separately. On this machine no native shared-working-set counter is exposed, so the harness labels `total working set - private working set` as a derived estimate only. A login page or unauthenticated web profile cannot pass the gate.

## Workload performance matrix

Settled idle is only one acceptance workload. Track B must also remain lighter than pristine Official Discord during normal use without disabling visible behavior. Do not set active-workload RAM limits until same-workload pristine Official Discord baselines exist:

| Workload | Required measurement and functional scope |
| --- | --- |
| Active DM/text messaging | Typing, sending, editing, reacting, navigation, private working set, total working set, private bytes, CPU median/p95, responsiveness, and functional pass/fail |
| Channel navigation and sustained history scrolling | Same route sequence and scroll duration in both clients, with memory growth/reclamation and responsiveness |
| Media-heavy channel | Visible GIFs, stickers, images, and embeds remain enabled; measure memory growth, GPU activity, CPU, reclamation after leaving the view, and functional pass/fail |
| Voice connected quiet and active conversation | Audio, microphone processing, chat, notifications, memory, CPU, GPU where applicable, latency, and functional pass/fail |
| Video call | RAM, CPU, GPU, frame stability, latency, device controls, and functional pass/fail separately from idle |
| Screen sharing | Capture quality, encoder/GPU/CPU cost, latency, controls, and functional pass/fail separately from idle |
| Notifications | Receive and open notifications while preserving normal behavior, with resource and functional measurements |
| Gaming with Discord in the background | Same game, display, account state, background conditions, and official-versus-Track-B comparison |

Maintain a workload matrix covering idle, active texting, scrolling, media-heavy channels, voice idle, active voice, video, screen sharing, and gaming in the background. Every official-versus-Track-B comparison reports complete-tree private working set, private bytes, CPU median/p95, GPU usage, process count, startup or settle time where relevant, responsiveness, and functional pass/fail. Video and screen sharing are not compared directly against idle because their workloads are fundamentally different.

## Measurement and comparison contract

The acceptance benchmark compares **Official Discord** with the **Track B Client** using:

- the same Discord account;
- the same server, channel, or DM;
- the same 1920x1080, 60 Hz display;
- the same window dimensions;
- the same machine, network state, power mode, and background applications;
- the same settled duration and workload.

Every result records:

- total working set and total private memory for the complete process tree;
- CPU median and p95 for the complete tree;
- process count;
- startup time to first usable responsive window and settled tree;
- GPU activity and GPU memory where available;
- handles and threads;
- UI responsiveness;
- functional pass/fail.

For each metric, report the absolute difference and percentage improvement over pristine Official Discord. Existing PTB/Vencord measurements must be labeled Official Discord + Vencord and cannot isolate an Electron/desktop-container delta:

`improvementPercent = (officialValue - trackBValue) / officialValue * 100`

Lower resource usage is not a pass if it causes navigation lag, delayed notifications, page-fault spikes, media stutter, call instability, broken permissions, or lost functionality.

## Prohibited shortcuts

The target must not be reached by:

- forcing repeated working-set trimming;
- constantly paging memory out;
- disabling hardware acceleration solely to improve one metric;
- disabling GIFs, media, voice, video, or screen sharing;
- removing required processes without feature testing;
- slowing navigation or background notifications;
- bypassing Discord security, authentication, authorization, entitlements, sandboxing, or protocol behavior.

The reduction must come from genuinely needing fewer resources in the shell and its runtime.

Official Discord may be used as the actively used comparison target, but it must not be restarted or stopped during testing without the user's confirmation. Track B test-shell restarts remain allowed for engineering diagnostics.

## Feature goal

The eventual application should preserve as much normal Discord desktop behavior as technically and safely possible:

- login and session persistence;
- servers, DMs, channels, threads, forums, search, messaging, editing, reactions;
- images, GIFs, stickers, embeds, media, uploads, and downloads;
- notifications;
- voice, video, screen sharing, microphone/camera/output selection;
- push-to-talk and global keybinds where practical;
- tray behavior, Windows startup, drag and drop, clipboard, accessibility;
- hardware acceleration;
- Rich Presence or game integration only through supported safe interfaces.

Each desktop capability is an independent compatibility item. Before adding it, record what Discord expects, whether WebView2 already supports it, the smallest safe native bridge if needed, its resource cost, rollback path, and functional result.

## Architecture gates

1. Build the minimal shell and establish a full-tree unauthenticated smoke baseline only as a feasibility check.
2. Log in normally through the shell and repeat the stock-versus-Track B benchmark on the same static channel.
3. If Track B cannot get below 500 MiB settled idle RAM, investigate the process/runtime ownership before investing heavily in native compatibility work.
4. If it reaches 250–350 MiB while preserving the required workload, validate the architecture strongly and restore desktop integrations one at a time.
5. If it reaches 150–250 MiB with normal functionality, record that as stretch success.
6. If a critical feature cannot be preserved safely, document the limitation instead of adding a protocol or security bypass.

No Track B result is called successful until the full-tree performance gate, required functional matrix, visual parity review, and desktop compatibility matrix all pass.
