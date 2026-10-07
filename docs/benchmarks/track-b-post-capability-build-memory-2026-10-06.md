# Track B post-capability-build memory check

Date: 2026-10-06

This is a read-only memory-source check after rebuilding the shell with diagnostic-only download and screen-capture event observers. The normal shell does not register those observers. The route was not manually confirmed, so this is not an acceptance benchmark.

Three synchronized samples were taken at 15-second spacing against one seven-process root. The first `Get-Counter` private values were unavailable during instance warm-up and are preserved as unavailable rather than treated as zero. Later samples matched WMI exactly.

| Sample | Private working set | Private bytes | Source agreement |
| --- | ---: | ---: | --- |
| 1 | 191.74 MiB | 271.22 MiB | counter row unavailable during warm-up |
| 2 | 187.27 MiB | 266.75 MiB | exact |
| 3 | 187.22 MiB | 266.71 MiB | exact |

Raw samples are in `benchmarks/raw/track-b-post-capability-build-memory-repeat-1.json`, `-2.json`, and `-3.json`.

This does not establish a regression caused by the event observers. The normal shell was freshly restarted for the rebuild, and the earlier synchronized 256.59 MiB point was from a different settled profile state. The result does establish that post-build memory must be remeasured after settling; the diagnostic handlers are not enabled in the normal shell and no event behavior was changed.
