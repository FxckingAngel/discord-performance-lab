# Track B authenticated renderer frame association

The diagnostic process snapshot was moved from WebView2 environment startup to navigation completion so renderer processes and frames are present before measurement.

The corrected authenticated no-bridge snapshot reported:

| Process kind | Process ID | Active associated frames |
| --- | ---: | ---: |
| Browser | 30020 | 0 |
| Renderer | 29952 | 2 |
| GPU | 22940 | 0 |
| Utility | 21224 | 0 |
| Utility | 37068 | 0 |

The matching short process sample measured the renderer at 584.7 MiB working set and 478.7 MiB private working set. This is a short, route/workload-unverified observation and is not an acceptance result. It does establish that the authenticated renderer has two active associated frames in this state, so frame lifecycle and retained-frame ownership are now measurable hypotheses.

The process snapshot records only process kinds, PIDs, and frame counts. It does not record frame URLs, text, account data, or tokens.
