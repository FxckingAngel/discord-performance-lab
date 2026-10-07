# Track B corrected live attribution baseline

Date: 2026-10-07  
Root PID: 39116  
Renderer PID: 28160  
Capture: 7 samples over approximately 30 seconds using the Phase 2
attribution sampler

The same eight-process tree remained present. The window handle was unchanged,
the shell was minimized and responsive, and the display was 1920x1080 at 60
Hz.

## Complete tree

| Metric | Median | P95 |
| --- | ---: | ---: |
| Process count | 8 | 8 |
| Total working set | 497.52 MiB | 499.46 MiB |
| Private working set | 310.18 MiB | 312.10 MiB |
| Shareable working set | 187.55 MiB | 187.67 MiB |
| Private bytes | 689.05 MiB | 691.52 MiB |
| CPU | 0.016% | 0.112% |

## Per-role results

| Role | Private working set | Working set | Private bytes |
| --- | ---: | ---: | ---: |
| Renderer | 254.92 MiB | 292.10 MiB | 432.81 MiB |
| Browser | 21.52 MiB | 58.45 MiB | 51.85 MiB |
| GPU process | 22.34 MiB | 47.52 MiB | 157.09 MiB |
| Network service | 7.95 MiB | 35.91 MiB | 18.32 MiB |
| Native shell | 0.98 MiB | 19.11 MiB | 10.55 MiB |
| Audio service | 0.93 MiB | 15.55 MiB | 7.86 MiB |
| Crashpad | 0.34 MiB | 15.06 MiB | 2.85 MiB |
| Storage service | 1.18 MiB | 13.84 MiB | 7.82 MiB |

CPU already meets the 0.2% median target. Memory remains above the 250 MiB
target by 60.18 MiB complete-tree private working set, with the renderer as
the dominant owner.

The earlier `track-b-current-followup-live.json` observation was produced by
the byte-based process sampler and was incorrectly passed to the MiB-based
Phase 2 summarizer. Its summary is invalid and is excluded from this report.
The corrected raw capture and sanitized summary are:

- `artifacts/track-b-current-followup-live-corrected.json`
- `artifacts/track-b-current-followup-live-corrected-summary.json`

No renderer behavior, Chromium flag, working-set trim, or forced collection
was used.
