# Track B unauthenticated Discord renderer region map

This capture used the isolated unauthenticated `--diagnostic-discord` profile. The process tree, CDP aggregates, and renderer resident-memory classification were captured during the same diagnostic run. No credentials, account data, page content, or raw command lines were published.

## Renderer result

| Metric | Value |
| --- | ---: |
| Renderer private working set | 221.43 MiB |
| Private-writable resident | 218.46 MiB |
| Committed private-writable | 234.45 MiB |
| V8 used heap | 22.48 MiB |

The measured private-writable resident outside V8 is approximately 196 MiB in this sample. It cannot be labeled Blink, Chromium native, Discord state, or media without stack or lifecycle ownership evidence.

## Leading allocation-base groups

| Group | Resident |
| --- | ---: |
| `0x1D200000000` | 86.34 MiB |
| `0x296000000000` | 31.04 MiB |
| `0x427400000000` | 16.45 MiB |
| `0x360000000000` | 6.66 MiB |
| `0x7FFEC31C0000` | 3.01 MiB |

Allocation addresses are process-local and may change between runs. The presence of several large anonymous groups in a no-media Discord state makes media decoding an unlikely complete explanation for the loaded renderer footprint. These groups remain correlation targets, not ownership claims.

Raw artifacts remain local under `artifacts/track-b-discord-frontend-cdp-20261007-repeat/`.
