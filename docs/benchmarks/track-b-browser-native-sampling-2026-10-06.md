# Track B browser-target native sampling boundary

Date: 2026-10-06

Artifact: `artifacts/track-b-browser-sampler-check-20261006/cdp.json`

The diagnostic connected to the WebView2 browser CDP target successfully, but the browser target rejected `Memory.startSampling` with CDP error `-32601: 'Memory.startSampling' wasn't found`. The browser profile therefore remains unavailable through this interface.

The diagnostic now records:

- whether a browser CDP target was present;
- whether browser-target sampling was available;
- the exact aggregate-only unavailable status when the method is unsupported.

No browser command line, page text, URL, account data, or raw allocation profile is written. Renderer-side sampling remains available through the page target. This is an interface limitation, not evidence that the browser process has no native allocations.
