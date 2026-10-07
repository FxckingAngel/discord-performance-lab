# Experiment 012: explicit minimized WebView visibility

## Candidate

The candidate build sets the WinForms WebView control's `Visible` state from the native window state. It hides the WebView when the shell is minimized and shows it again when the shell is restored. The production `Verified` binary was not replaced during this experiment.

Microsoft recommends hiding a WebView when its app window is minimized because hidden pages can receive CPU and memory benefits. Source: [CoreWebView2Controller.IsVisible](https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2controller.isvisible).

## Verification

- Candidate build compiled successfully.
- Diagnostic blank and capability-event smoke tests passed.
- Duplicate normal launch, minimize, restore, and single-instance checks passed.
- The current production shell was restored after the candidate run.
- No authenticated functional checklist was recorded for the candidate.

## Resource comparison

The candidate was warmed for approximately 90 seconds, then sampled for 120 seconds in each state. The earlier production-build visibility isolation run is the comparison baseline.

| Metric | Production foreground | Candidate foreground | Production minimized | Candidate minimized |
| --- | ---: | ---: | ---: | ---: |
| Private bytes median | 259.88 MiB | 260.69 MiB | 243.05 MiB | 242.09 MiB |
| Private bytes p95 | 270.25 MiB | 269.96 MiB | 245.50 MiB | 245.11 MiB |
| Private working set median | 181.48 MiB | 181.30 MiB | 165.04 MiB | 152.53 MiB |
| CPU p95 | approximately 0.01% | 0.018% | approximately 0.01% | 0.073% |

Raw candidate samples: `benchmarks/raw/track-b-visibility-candidate-foreground-120s-20261006.json` and `benchmarks/raw/track-b-visibility-candidate-minimized-120s-20261006.json`.

## Decision

The candidate is a small standards-aligned behavior improvement, but this run does not prove a material settled resource reduction. It does not address the foreground renderer allocation or establish the 250 MiB acceptance target. Keep it separate from the production binary until the manual functional checkpoint confirms notifications, voice, video, screen sharing, and restore behavior.
