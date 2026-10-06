# Experiment 002: disable crash reporting

## Status

Rejected.

## Change

The stock client was launched with the Chromium switch:

```text
--disable-breakpad
```

The switch propagated to the Discord root process. It was tested only as a private experiment and did not modify the installed package or user settings.

## Result

| Metric | Candidate result |
| --- | ---: |
| Working-set median | 680.54 MiB |
| Working-set p95 | 1,087.38 MiB |
| Private-memory median | 854.51 MiB |
| Total CPU median | 0.714% |
| Process-count median | 6 |
| Process-tree startup stabilization | 17.875 s |

The memory and CPU figures came from one idle run. The startup result is slower than the stock runs measured at 9.813 s and 13.007 s.

## Decision

Reject this candidate. Electron's current supported-switch documentation does not list `--disable-breakpad`, and the switch changes crash-reporting behavior. The startup regression and unsupported diagnostics change outweigh the single-run resource reduction. The functional checklist was not passed.
