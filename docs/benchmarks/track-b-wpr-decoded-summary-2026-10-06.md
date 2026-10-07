# Track B decoded WPR summary

Date: 2026-10-06

Windows `tracerpt.exe` decoded the elevated ETL into aggregate event metadata without exporting raw event payloads. The source trace remains private in `artifacts/track-b-wpr-elevated-20261006/`.

## Capture quality

- Events processed: 10,989,877
- Events lost: 0
- Buffers processed: 1,102
- Trace duration reported by `tracerpt`: 46 seconds, including trace setup and rundown
- CPU samples: 128,025
- Stack walks: 2,021,610
- Hard-fault events: 22,806
- Disk reads: 25,683
- Disk writes: 2,629
- Process start events: 64
- Process end events: 64
- Thread ready events: 541,911

The profile therefore contains usable system-level sampling, scheduler, page-fault, disk, and process/thread event streams. These counts are not Track B-specific yet. The current aggregate file explicitly records that process-tree filtering has not been applied, so none of these totals are used as Discord ownership claims.

## Reproduction

Run `tools/Summarize-TrackBWprEtw.ps1` against a completed ETL. It creates a local `tracerpt-summary.txt`, `tracerpt-report.xml`, and sanitized `wpr-aggregate-summary.json`. The report and summary can include machine/process metadata and remain local. Raw event payloads and heap/message content are not published.

The next analysis step is to correlate event process IDs with the Track B root PID captured for the same scenario. Until that correlation is performed, this is trace-quality evidence rather than an optimization decision.
