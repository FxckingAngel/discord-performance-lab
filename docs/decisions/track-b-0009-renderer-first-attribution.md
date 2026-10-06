# Decision 0009: renderer-first attribution

Date: 2026-10-06

## Evidence

The latest 615-second authenticated Track B run measured 255.20 MiB median private bytes across seven processes. The separated role medians were:

| Role | Private bytes |
| --- | ---: |
| Renderer | 120.31 MiB |
| GPU | 58.20 MiB |
| WebView2 browser | 41.77 MiB |
| Native shell | 11.38 MiB |
| Network service | 13.13 MiB |
| Storage service | 7.52 MiB |
| Crashpad | 2.89 MiB |

The current blank-profile floor measured 146.69 MiB median private bytes. The loaded-minus-blank delta was approximately 109.63 MiB, with approximately 100.94 MiB of that delta in the renderer. GPU, browser, network, storage, crashpad, and native-shell values were at or below their blank-profile scale rather than owning the loaded delta.

The local CDP snapshot measured 27.7 MiB V8 used heap, 52.67 MiB aggregate heap-snapshot self size, and 28.23 MiB of `native` heap-snapshot entries. A 60-second idle performance window recorded effectively zero script, layout, and style-recalculation time.

## Decision

Track B's next optimization work will target renderer allocation ownership first. It will not change renderer isolation, disable hardware acceleration, force garbage collection, trim working sets, or add unmeasured Chromium switches.

The next candidate must identify a specific renderer-owned category, measure its effect on private bytes and functionality, and include a rollback path. A page-level change is not accepted merely because it lowers a diagnostic heap number; it must preserve normal Discord behavior and be compared against the separated-role settled baseline.

The GPU and native shell remain secondary attribution targets. They are not the first optimization target because their loaded deltas are small or their process costs are already near the runtime floor.

This decision does not claim that WebView2 is final or that the 250 MiB target has been met. It only fixes the order of evidence-backed work.
