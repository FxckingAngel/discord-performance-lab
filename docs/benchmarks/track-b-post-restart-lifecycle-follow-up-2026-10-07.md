# Track B post-restart lifecycle follow-up

Date: 2026-10-07

Artifact: `artifacts/track-b-post-restart-tree-20261007.json`

Track B was restarted after the previous normal process was closed. This was a read-only process-tree observation; no renderer settings or Discord behavior were changed. Route readiness was not independently confirmed, so these numbers remain diagnostic.

Across the 18-second capture, the complete tree changed substantially while the renderer settled:

| Sample | Complete working set | Complete private working set | Complete private bytes | Renderer private working set | Renderer private bytes |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 977.8 MiB | 582.2 MiB | 735.0 MiB | 471.2 MiB | 529.9 MiB |
| 2 | 858.6 MiB | 454.9 MiB | 601.5 MiB | 344.2 MiB | 402.3 MiB |
| 3 | 837.9 MiB | 434.2 MiB | 574.9 MiB | 324.4 MiB | 377.9 MiB |

The renderer accounted for most of the decline. This confirms that short post-launch measurements can overstate settled memory and that a fixed settle condition is required. It does not prove that the final sample is fully initialized or authenticated.

The normal shell was relaunched at PID 10152 and remained responsive after the capture. The clean official Discord reference was not touched.
