# ChatGPT project context

This directory is a local mirror of the ChatGPT project “Github”.

- Treat every file under `sources/` as read-only reference material.
- Do not edit, rename, move, or delete synced project files.
- These files may be replaced the next time a task is created from this ChatGPT project.


## Project instructions

## Primary engineering objective

Track B is the main engineering goal:

> Track B target: approximately 250 MiB total settled idle RAM and 0.2% total idle CPU across the complete process tree, while preserving normal Discord functionality.

Treat this as the primary optimization objective for implementation decisions, experiments, and acceptance criteria. Measure the complete Track B process tree, including the native shell and every WebView2 helper, renderer, GPU, network, audio, storage, and crash process. Do not count a result as successful if it only reduces one process, trims the working set artificially, causes paging or responsiveness regressions, or loses normal Discord functionality.

Track A remains supporting benchmark and research work. Use it to establish comparable official-Discord baselines, attribute resource ownership, and verify functional and performance regressions, but judge Track B work against the full-tree target above.

Current workflow status: Track B goal ACTIVE. Authenticated Track B checkpoint CAPTURED; official same-route A/B pairing and parity validation remain pending. Missing UI automation does not pause or block unrelated Track B engineering.

Desktop-environment compatibility is a second hard Track B requirement. Discord's own frontend must recognize and use Track B as a genuine desktop-capable environment rather than falling back to a generic browser experience. Provide only the smallest audited native equivalents for capabilities that actually work. Do not blindly spoof Electron objects, authentication, authorization, entitlements, network behavior, or security state. Visual and functional parity with official Discord Desktop must be demonstrated on the same account, route, call state, window, display, and workload before Track B can pass.

The shell's desktop identity begins with the audited Discord Desktop user-agent signal. That signal may be present in the normal shell, but it must not be used to claim unsupported native capabilities. Add each capability only after its native implementation works and is independently tested.

Production functionality is a hard constraint. Do not reach the memory target by disabling, pausing, or changing normal Discord behavior that official Discord provides. Visible GIFs, stickers, animations, video, media, notifications, voice, and other expected features must continue to work when active. Static or no-media states are diagnostic benchmarks only, not production optimizations. Media work may reclaim decoded or offscreen resources only when visible behavior is unchanged, using measures such as lazy loading, bounded caches, releasing resources outside the viewport, reclaiming resources after navigation, and avoiding duplicate decoded copies. If a change must disable a feature or alter visible behavior to reduce memory, count it as a failed optimization.

Workload performance is a first-class acceptance requirement, not an idle-only extension. Keep the settled-idle floor at approximately 250 MiB complete-tree private working set, which is the primary unique/private resident RAM KPI, and approximately 0.2% median CPU. Also measure fully initialized active DM/text messaging, channel navigation, sustained history scrolling, media-heavy channels, quiet voice, active voice, video, screen sharing, notifications, and gaming with Discord in the background. Do not set arbitrary active-workload RAM limits until trustworthy same-workload pristine Official Discord baselines exist. Every workload comparison reports private working set, total working set, derived/shareable working set, private bytes, CPU median/p95, GPU usage/memory where applicable, process count, responsiveness, and functional pass/fail. These measurements do not authorize feature reduction.

The fully initialized gate is mandatory before a result can count toward acceptance: the exact route must be manually confirmed, the frontend must be visibly loaded, navigation must be complete, the renderer PID and WebView2 inventory must be synchronized, process count must be stable, and the route must remain unchanged for the measurement. A loaded URL or incomplete diagnostic state is not a performance win.

Track A results from the current Vencord-patched official installation must be labeled Official Discord + Vencord. Do not use them to isolate an Electron or desktop-container tax. Create a pristine Official Discord reference before making that claim. Official Discord is the user's actively used comparison target; do not restart or stop it without confirmation.

Official Discord is the user’s actively used comparison target. Do not restart or stop official Discord without the user’s confirmation. Track B test-shell restarts remain allowed for in-scope engineering diagnostics.
