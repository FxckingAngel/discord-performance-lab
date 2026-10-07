# Track B live process-tree follow-up

Date: 2026-10-07

Artifact: `artifacts/track-b-live-tree-20261007.json`

This was a read-only 15-second capture of the already-running normal Track B shell. The authenticated route and frontend readiness were not independently confirmed, so this is diagnostic evidence only and is not a performance acceptance baseline.

The tree stayed at eight processes. The final sample reported:

| Process role | Private working set | Working set | Private bytes |
| --- | ---: | ---: | ---: |
| Native shell | 5.4 MiB | 21.4 MiB | 12.4 MiB |
| WebView browser | 25.0 MiB | 58.2 MiB | 49.5 MiB |
| Renderer | 224.6 MiB | 271.9 MiB | 339.4 MiB |
| GPU | 29.6 MiB | 54.6 MiB | 104.9 MiB |
| Network utility | 5.9 MiB | 28.1 MiB | 14.6 MiB |
| Storage utility | 2.1 MiB | 12.5 MiB | 7.8 MiB |
| Audio utility | 2.0 MiB | 9.0 MiB | 7.9 MiB |
| Crashpad | 1.0 MiB | 6.6 MiB | 2.9 MiB |
| **Complete tree** | **295.6 MiB** | **462.0 MiB** | **539.4 MiB** |

The renderer remains the dominant private-resident owner. GPU private bytes are materially larger than GPU private working set, which is another reason to keep resident and committed metrics separate. No optimization was applied from this capture.

## Diagnostic-launch note

An authenticated no-bridge CDP launch was attempted while the normal shell still owned the same WebView2 user-data profile. The diagnostic process remained responsive, but port 9230 was not available because WebView2 reused the existing browser process and its command line had no remote-debugging argument. This is a launch-isolation issue, not evidence about Discord readiness or memory. The normal shell was left running; no official Discord process was changed.
