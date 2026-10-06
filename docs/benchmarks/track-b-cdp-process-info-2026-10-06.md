# Track B CDP process mapping: 2026-10-06

The diagnostic-only `tools/Probe-TrackBCdpProcessInfo.mjs` uses the Chromium DevTools Protocol browser endpoint and `SystemInfo.getProcessInfo`. The protocol documents this method as returning process type, process identifier, and cumulative CPU time. The probe records only those aggregate fields and keeps the raw result local.

## Result

The authenticated diagnostic reported five Chromium process entries:

| CDP type | CDP process ID | Cumulative CPU time |
| --- | ---: | ---: |
| browser | local-only | 1.318 s |
| renderer | local-only | 0.948 s |
| GPU | local-only | 0.357 s |
| network service | local-only | 0.512 s |
| storage service | local-only | 0.061 s |

The CDP identifier is retained only in the local artifact because the browser endpoint did not expose a separate `osProcessId` field in this WebView2 build. The Windows rooted process sampler remains the authority for local PID, private memory, working set, handles, threads, and parentage.

## Interpretation

This gives a protocol-level role inventory that can be paired with the Windows process-tree sample without recording command lines or account data. It confirms that the authenticated diagnostic profile had one renderer at the time of the CDP probe. The earlier four-renderer capture therefore represents a different authenticated shell state and must not be generalized to every route or profile state.

Source: [Chrome DevTools Protocol SystemInfo](https://chromedevtools.github.io/devtools-protocol/tot/SystemInfo/)
