# Track B authenticated browser-media path

Date: 2026-10-07

Diagnostic mode: `--diagnostic-authenticated-no-bridges` on loopback port 9230  
Profile: the existing Track B WebView2 profile  
Official Discord: untouched

## Page readiness

The sanitized page-state probe reported a complete document, a populated Friends route, 353 scripts, 598 stylesheets, and a non-empty application body. This is an authenticated, fully initialized diagnostic state rather than a blank or loading shell.

## Browser media capability surface

The media probe recorded only aggregate capability data:

| Capability | Result |
| --- | --- |
| `navigator.mediaDevices` | present |
| `getUserMedia` | present |
| `getDisplayMedia` | present |
| Audio inputs | 1 |
| Audio outputs | 1 |
| Video inputs | 1 |
| Device labels exposed | 0 |
| Microphone permission | `prompt` |
| Camera permission | `prompt` |
| Notifications permission | `prompt` |

No permission was granted automatically and no device labels, account data, URLs, messages, tokens, or media were retained.

## Settled process-tree observation

The 30-second observation used the complete Track B tree and retained per-process measurements locally in `artifacts/track-b-browser-media-capabilities-20261007/process-tree.json`.

| Metric | Result |
| --- | ---: |
| Process count | 8 |
| Complete-tree private working set median | 407.70 MiB |
| Complete-tree private working set range | 400.70–418.57 MiB |
| Renderer private working set median | 302.60 MiB |
| Renderer private working set range | 297.02–311.32 MiB |
| Complete-tree private bytes median | 543.81 MiB |
| GPU private working set, final sample | 36.59 MiB |

The renderer remains the dominant private-resident owner. CPU samples were low during this observation, but this was not a voice, video, or screen-sharing workload and must not be reported as an active-media benchmark.

## Media-quality observation

The sanitized media probe found 133 decoded images and three decoded 320x320 video elements in the Friends state. All observed images were complete and decoded. WebView2 did not provide the optional GPU feature-status result through this diagnostic endpoint, so hardware-acceleration parity remains unverified.

## Decision

The browser/WebRTC route is a viable capability candidate and avoids importing Electron/Node voice binaries. It is not yet accepted for Track B desktop parity. The next required evidence is an authenticated end-to-end voice, video, and screen-sharing test with explicit user consent, followed by the same process-tree and media-quality measurements. No native desktop contract is enabled in the normal shell.
