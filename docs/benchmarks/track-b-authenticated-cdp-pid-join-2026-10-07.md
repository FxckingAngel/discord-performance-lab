# Authenticated CDP to renderer PID join

Date: 2026-10-07

The normal shell was closed through its window-close path. The diagnostic shell then reused the existing `WebView2UserData` profile and exposed loopback CDP on port 9232. Windows process attribution, the WebView2 native process inventory, and CDP were collected during the same diagnostic session. The diagnostic shell was then closed normally and the standard shell was restored.

PID identity:

| Source | Renderer PID |
| --- | ---: |
| Windows rooted process tree | 34340 |
| WebView2 `GetProcessInfos()` inventory | 34340 |

The renderer identity matched exactly. This validates the native inventory-to-process-tree join for this diagnostic session. The earlier normal-shell `webview-process-info.json` was stale and was correctly not used for that state.

The synchronized diagnostic sample measured:

- complete-tree private working set median: 113.32 MiB
- renderer private working set median: 76.16 MiB
- CPU median: 0.027%
- one CDP page target at `https://discord.com/app`

The low memory result is not an optimization or acceptance result. This diagnostic state was not manually verified as the canonical static route, and it may differ in frontend settlement or route state from the normal shell baseline. It is evidence that PID association is now trustworthy when CDP and native inventory are captured together.

Raw synchronized artifacts remain local at `artifacts/track-b-authenticated-cdp-join-20261007/`.
