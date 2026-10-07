# Track B authenticated CDP/native follow-up

Date: 2026-10-06

The authenticated no-bridge diagnostic was run against the persisted WebView2 profile, then the normal shell was restored and verified responsive. This was a diagnostic environment, not a production shell change.

## CDP observations

- Documents: 14
- DOM nodes: 6,117
- JavaScript event listeners: 2,190
- User-agent-specific memory: unavailable in this WebView2 build
- Browser-target native sampling: unavailable (`Memory.startSampling` is not exposed)
- Renderer-target native sampling: available, but only 984,125 sampled bytes across 58 samples
- Native sampled module: `msedge.dll.pdb`
- Native sampled category: `chromium-native`

The sampled native bytes are a sampling signal, not a byte-for-byte renderer allocation total. They cannot explain the roughly 300 MiB private-writable resident renderer footprint and must not be subtracted from it.

## Diagnostic process-tree observation

The fresh diagnostic process tree ranged from 427.10 to 482.71 MiB summed private working set during seven samples. The renderer ranged from 312.92 to 366.74 MiB. This run is not a replacement for the settled normal-shell baseline because the diagnostic process had just been created and its route/workload was not independently confirmed.

## Decision

No renderer or WebView2 setting was changed. CDP provides useful DOM/listener and limited sampling signals, but Windows `VirtualQueryEx`/`QueryWorkingSetEx` remains the stronger source for the native/private resident accounting. The next attribution work should use feature-isolated state transitions and compare their per-region deltas.
