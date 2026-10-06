# Track B performance and acceptance goal

Date: 2026-10-06

## Primary goal

Build a standalone Discord desktop shell that preserves essentially all normal Discord functionality while using dramatically fewer resources than official Discord.

The shell must replace the Electron desktop container, not Discord's web client, backend, authentication, authorization, or network behavior. Every resource result counts the complete application process tree, including the native host, every WebView2 helper, renderer, network service, audio service, GPU process, and crash handler.

The design target is approximately **250 MiB total settled idle working set and 0.2% total idle CPU** on the current comparison machine. This is a target for the whole Track B application, not only its main executable.

## Target levels

| Level | Settled idle working set, full tree | Total idle CPU | Required behavior |
| --- | ---: | ---: | --- |
| Minimum acceptable | under 500 MiB | under 1% | Responsive UI and no major feature loss |
| Strong goal | 250–350 MiB | about 0.1–0.5% | Fast startup and normal responsiveness |
| Stretch goal | 150–250 MiB | effectively 0% | No noticeable difference from official Discord during normal use |
| Design target | about 250 MiB | about 0.2% | Preserve normal functionality and avoid artificial trimming |

These levels are judged after the same account is logged in, the same static channel is visible, the window has settled for the same duration, and the same background conditions are present. A login page or unauthenticated web profile cannot pass the gate.

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

For each metric, report the absolute difference and percentage improvement over official Discord:

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

No Track B result is called successful until the full-tree performance gate and the required functional matrix both pass.
