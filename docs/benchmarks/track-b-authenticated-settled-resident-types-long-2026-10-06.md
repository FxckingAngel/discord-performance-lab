# Track B long settled authenticated resident types

Date: 2026-10-06

## Scope

This diagnostic used a 60-second settle followed by a 120-second process/CDP capture and a final per-PID resident-page classification. The route and workload were not independently verified, so this is not an acceptance benchmark. The resident classifier runs after the process observation and is a final instantaneous reading, not a median.

Raw output: `artifacts/track-b-authenticated-settled-resident-types-20261006/`

## Process-tree observation

| Metric | Median | P95 |
|---|---:|---:|
| Process count | 8 | 8 |
| Total working set | 873.31 MiB | 882.00 MiB |
| Private working set | 446.73 MiB | 455.57 MiB |
| Shareable working set | 426.58 MiB | 428.10 MiB |
| Private bytes | 615.88 MiB | 640.42 MiB |
| CPU | 0.198% | 1.416% |

The process-tree values differ from the earlier 389.25 MiB settled capture, which confirms that the current diagnostic route/workload is not stable enough to serve as an acceptance benchmark without the manual same-route checkpoint.

## Final resident-page classification

| Role | Resident | Private writable | Private executable | Mapped | Image-backed |
|---|---:|---:|---:|---:|---:|
| Renderer | 439.15 MiB | 326.66 MiB | 0.02 MiB | 31.18 MiB | 80.22 MiB |
| Browser | 145.32 MiB | 34.52 MiB | 0 MiB | 9.46 MiB | 101.07 MiB |
| GPU process | 112.96 MiB | 42.84 MiB | 0.01 MiB | 6.45 MiB | 63.44 MiB |
| Native shell | 53.89 MiB | 5.59 MiB | 0 MiB | 11.71 MiB | 36.55 MiB |
| Network service | 50.50 MiB | 8.35 MiB | 0 MiB | 3.72 MiB | 38.32 MiB |
| Audio service | 28.01 MiB | 1.60 MiB | 0 MiB | 1.71 MiB | 24.63 MiB |
| Storage service | 23.88 MiB | 1.89 MiB | 0 MiB | 1.64 MiB | 20.29 MiB |
| Crashpad | 16.33 MiB | 0.87 MiB | 0 MiB | 0.90 MiB | 14.49 MiB |

The summed final resident reading was 870.04 MiB, with 422.32 MiB private writable and only 0.03 MiB private executable.

## CDP state

- V8 used heap: 108.14 MiB
- V8 total heap: 110.70 MiB
- DOM documents: 15
- DOM nodes: 6,287
- JavaScript event listeners: 2,235
- Image elements: 162
- Video elements: 3
- Canvas elements: 4

## Interpretation

The renderer's non-V8 resident remainder remains large even in a longer capture. The difference between this run and the earlier settled run is evidence that route/workload or settling state materially affects the number, not evidence that the memory disappeared. The next feature-specific captures must be manually held at an explicitly named static, media, voice, video, or screen-share state before comparing deltas.
