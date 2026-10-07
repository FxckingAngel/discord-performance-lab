# Track B primary-monitor baseline

Date: 2026-10-07

This is the corrected primary-monitor baseline for the fully initialized authenticated no-bridge Track B state. The second monitor is treated as a control-surface visibility issue, not as a product optimization variable.

## Capture conditions

- Display: primary 1920x1080 monitor at 60 Hz
- Track B window: 1280x720
- Window: visible, foreground, and responding
- Process count: 8 for all 7 samples
- Root PID: 20164
- Duration: 42.7 seconds
- Sampling interval: 5 seconds
- Official Discord: untouched

## Results

| Metric | Median | P95 |
| --- | ---: | ---: |
| Complete-tree working set | 832.24 MiB | 839.50 MiB |
| Complete-tree private working set | 437.20 MiB | 442.96 MiB |
| Complete-tree shareable working set | 396.58 MiB | 396.65 MiB |
| Complete-tree private bytes | 616.45 MiB | 661.94 MiB |
| Complete-tree CPU | 0.066% | 0.273% |
| Renderer private working set | 322.55 MiB | not separately reported |
| Renderer private bytes | 369.48 MiB | not separately reported |
| GPU private working set | 47.07 MiB | not separately reported |

## Interpretation

The renderer remains the dominant private-resident owner. CPU median remains below the 0.2% idle target. This is a valid primary-monitor diagnostic baseline, not an acceptance result, because the official same-route comparison and active-use matrix are still incomplete.

The earlier secondary-monitor comparison used a different window height and was rejected as a causal display experiment. No production behavior or display setting was changed based on it.

Raw process data remains under `artifacts/track-b-primary-1280x720-20261007`.
