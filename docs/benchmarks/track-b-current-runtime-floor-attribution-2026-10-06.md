# Track B current runtime-floor attribution

Date: 2026-10-06

A diagnostic blank-page run used the current verified shell build and its isolated blank profile. The diagnostic root was closed after measurement by exact PID and command-line validation. No normal shell or Discord profile was modified.

Capture: 126.8 seconds, eight samples, 15-second interval, seven processes.

| Metric | Blank runtime median | Authenticated READY median | Loaded delta |
| --- | ---: | ---: | ---: |
| Summed working set | 370.03 MiB | 531.56 MiB | 161.53 MiB |
| Private working set | 67.14 MiB | 178.14 MiB | 111.00 MiB |
| Private bytes / commit | 146.69 MiB | 256.32 MiB | 109.63 MiB |
| Total CPU | 0.011% | 0.008% | not comparable as a workload cost |

The current loaded-minus-blank private-bytes delta is therefore approximately 109.63 MiB in this one-renderer state. It is not evidence that the page adds only JavaScript memory. The renderer's private bytes rise from 19.37 MiB to 120.31 MiB, while V8 and Blink/native attribution still require diagnostic evidence.

Role-level private-bytes medians:

| Role | Blank | Authenticated READY | Delta |
| --- | ---: | ---: | ---: |
| Browser/native shell group | 49.64 MiB | 54.17 MiB | +4.53 MiB |
| Renderer | 19.37 MiB | 120.31 MiB | +100.94 MiB |
| GPU | 56.16 MiB | 58.20 MiB | +2.04 MiB |
| Network service | 11.20 MiB | 13.29 MiB | +2.09 MiB |
| Storage service | 7.27 MiB | 7.55 MiB | +0.28 MiB |
| Crashpad | 3.12 MiB | 2.89 MiB | -0.23 MiB |

This narrows the next optimization question: the remaining private-bytes near miss is primarily in the Discord-loaded renderer, not in the GPU, network, storage, or crashpad services. The evidence still does not justify changing renderer isolation, disabling hardware acceleration, trimming memory, or adding unmeasured Chromium switches.

Raw inputs remain local and private:

- `benchmarks/raw/track-b-current-blank-floor-20261006-065937.json`
- `benchmarks/raw/track-b-current-blank-floor-20261006-065937-summary.json`
- `benchmarks/raw/track-b-ready-manual-checkpoint-20261006-064727-summary.json`
