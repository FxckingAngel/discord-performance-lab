# Track B authenticated CDP attribution: 2026-10-06

This diagnostic used the existing `--diagnostic-authenticated` mode and a loopback Chromium DevTools Protocol endpoint. It collected aggregate runtime facts only. No page text, account identifiers, cookies, tokens, heap objects, or raw profiles were written to the repository.

## Conditions

- Profile: Track B authenticated WebView2 profile
- Diagnostic root: separate authenticated diagnostic launch
- CDP target: one page target at the Discord application route
- Process capture: 30.2 seconds, six samples at approximately five-second intervals
- Process tree: seven processes, one renderer
- Raw local artifacts: `artifacts/diagnostic-authenticated-cdp.json` and `artifacts/diagnostic-authenticated-cdp-process.json`

## Runtime attribution

| Measurement | Result |
| --- | ---: |
| V8 heap used | 30.9 MiB |
| V8 heap total | 49.8 MiB |
| V8 embedder heap used | 9.1 MiB |
| V8 backing storage | 16.7 MiB |
| DOM nodes | 1,038 from the performance domain; 974 document elements from the aggregate probe |
| Documents | 5 |
| Frames | 3 |
| Page targets | 1 |
| Image/video/canvas elements in the inspected document | 0 / 0 / 0 |

The final process sample reported 117.63 MiB renderer private working set and 132.12 MiB renderer private bytes. Subtracting V8 used heap gives an approximately 101 MiB residual lower bound, but that residual must not be labeled Blink, native Chromium, media cache, or GPU memory without more direct attribution.

## Other process roles at the final sample

| Role | Private working set | Private bytes |
| --- | ---: | ---: |
| WebView2 browser | 33.02 MiB | 41.38 MiB |
| GPU process | 15.03 MiB | 56.13 MiB |
| Network service | 8.14 MiB | 13.28 MiB |
| Storage service | 3.02 MiB | 7.58 MiB |
| Crashpad | 1.86 MiB | 3.05 MiB |
| Native shell | 8.62 MiB | 12.15 MiB |

## Interpretation

The renderer's approximately 132 MiB private allocation is not a 132 MiB JavaScript heap. The measured V8 used heap accounts for roughly 31 MiB, leaving a large unclassified renderer-resident remainder. This supports the next Phase 2 work item: use sanitized allocation and compositor diagnostics to distinguish Blink/DOM, native Chromium, decoded media, and shared-buffer allocations before changing renderer behavior.

The CDP probe did not produce a useful allocation-sampling profile in this run (`sampleCount=0`), so no allocation-owner claim is made from sampling. The diagnostic mode was closed after capture and does not alter normal-shell behavior.
