# Track B rooted WPR PID-filtered evidence

Date: 2026-10-06

The private ETL decoder uses Microsoft's `Microsoft.Diagnostics.Tracing.TraceEvent` library to read the rooted WPR ETL and filter typed kernel events to the eight PIDs recorded in `root-process-tree-before.json`. It emits aggregate counts only. No command lines, stack frames, raw event payloads, or Discord content are included in the filtered result.

## Filtered event counts

- Track B sampled-profile events: 1,921
- Track B hard-fault events: 142
- Track B disk reads: 143
- Track B disk writes: 14

Per-PID ownership:

- Renderer PID 39048: 1,547 samples, 85 hard faults, 85 reads
- GPU PID 39764: 294 samples, 23 hard faults, 23 reads
- Network service PID 4928: 41 samples, 20 hard faults, 22 reads, 12 writes
- Browser PID 8644: 17 samples, 8 hard faults, 7 reads, 2 writes
- Native shell PID 28156: 14 samples, 5 hard faults, 5 reads
- Storage service PID 1080: 6 samples, 1 hard fault, 1 read
- Crashpad PID 35584: 1 sample
- Audio service PID 39600: 1 sample

## Sampled module attribution

The decoder also correlates sampled instruction pointers with kernel image-rundown ranges, using module basenames only:

- Renderer PID 39048: `msedge.dll` 1,242 samples, unmapped 275, `ntdll.dll` 25, `KernelBase.dll` 3, `DWrite.dll` 2
- GPU PID 39764: `msedge.dll` 86 samples, `nvwgf2umx.dll` 40, unmapped 132, `ntdll.dll` 27, `d3d11.dll` 4, remaining Windows UI modules 5
- Native shell PID 28156: `coreclr.dll` 10, `clrjit.dll` 1, `kernel32.dll` 1, unmapped 2

The renderer's mapped samples are therefore predominantly in `msedge.dll`, while the GPU has a measurable NVIDIA driver sample group. Unmapped samples are retained and are not assigned speculatively.

The renderer accounts for 80.5% of the filtered sampled-profile events, 59.9% of hard faults, and 59.4% of reads. The GPU accounts for 15.3% of samples and 16.2% of hard faults. The module mapping confirms that the sampled renderer work is primarily Chromium/WebView2 native code rather than the WinForms host.

## Interpretation boundary

Sampled-profile counts are a statistical CPU attribution signal, not a direct CPU-percent calculation. Hard-fault events are system fault events and do not by themselves prove paging or a memory cause. Disk counts are event counts, not transferred-byte totals. These results strengthen the renderer/GPU priority for deeper attribution, but they do not justify a renderer change by themselves.

The aggregate output is preserved at `artifacts/track-b-wpr-rooted-20261006/track-b-filtered-events.json`. The decoder source is private diagnostic tooling under `benchmarks/private/TrackBEtlFilter/`.

Reference: https://github.com/microsoft/perfview/blob/main/documentation/TraceEvent/TraceEventLibrary.md
