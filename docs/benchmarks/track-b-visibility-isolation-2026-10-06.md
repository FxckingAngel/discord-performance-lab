# Track B foreground versus minimized isolation: 2026-10-06

This comparison used the same running Track B instance and the same persisted state. No restart or page interaction occurred between the two 180-second measurements. The window was minimized through the normal Windows window-state API for the second interval and restored afterward.

## Results

| Metric | Foreground median | Minimized median | Change when minimized |
| --- | ---: | ---: | ---: |
| Summed working set | 532.87 MiB | 518.52 MiB | 14.35 MiB lower |
| Private working set | 181.48 MiB | 165.04 MiB | 16.44 MiB lower |
| Private bytes / commit | 259.88 MiB | 243.05 MiB | 16.83 MiB lower |
| CPU p95 | 0.01% | 0.01% | no measurable difference at sampler resolution |

Both intervals contained 17 samples at 10-second intervals. Foreground p95 private bytes were 270.25 MiB; minimized p95 was 245.50 MiB. Raw samples are `benchmarks/raw/track-b-foreground-settled-isolation-180s-20261006.json` and `benchmarks/raw/track-b-minimized-settled-isolation-180s-20261006.json`.

## Role attribution

| Role | Foreground private bytes median | Minimized private bytes median | Change |
| --- | ---: | ---: | ---: |
| Renderer | 123.71 MiB | 106.67 MiB | 17.04 MiB lower |
| GPU process | 58.33 MiB | 58.39 MiB | unchanged |
| Browser | 42.10 MiB | 42.08 MiB | unchanged |
| Network service | 13.16 MiB | 13.14 MiB | unchanged |
| Native shell | 12.04 MiB | 12.11 MiB | unchanged |
| Storage service | 7.58 MiB | 7.69 MiB | unchanged |
| Crashpad handler | 2.98 MiB | 2.96 MiB | unchanged |

## Interpretation

Minimizing the window reduced almost the entire memory difference in the renderer, while GPU, browser, network, storage, crashpad, and native-shell allocations stayed flat. This makes foreground-only renderer state the leading Phase 2 optimization target. It does not prove that animation or compositor work caused the allocation: the trace showed no paint or compositor events, and CPU p95 was unchanged at this sampler resolution.

The result does not justify hiding the window, disabling rendering, changing Chromium process isolation, or trimming memory. Any renderer change must be tested against the visible foreground state and normal Discord functionality.
