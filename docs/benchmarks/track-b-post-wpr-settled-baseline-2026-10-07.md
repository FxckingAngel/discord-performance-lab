# Track B post-WPR settled baseline

Artifact directory: `artifacts/track-b-post-wpr-settled-baseline-20261007/`

The new settle gate required six consecutive samples with the same process identity and window state, with renderer and GPU private working-set variation no greater than 1%. It found a stable window after eight probes, then recorded 13 measurement samples over 60 seconds.

## Controls

- Root PID: 39116
- Renderer PID: 28160
- GPU PID: 6372
- Process count: 8 throughout
- Window: Korone's Discord Shell (Prototype), visible, responsive, minimized
- Window handle: 12061962
- Display: 1920x1080 at 60 Hz
- No renderer behavior changes
- Exact Discord route and media state: not recorded by the ordinary non-CDP shell and therefore not treated as controlled A/B metadata

## Complete-tree result

| Metric | Median | P95 |
| --- | ---: | ---: |
| Total working set | 554.22 MiB | 565.99 MiB |
| Total private working set | 329.89 MiB | 341.40 MiB |
| Total shareable working set | 223.69 MiB | 224.62 MiB |
| Total private bytes | 693.54 MiB | 706.67 MiB |
| CPU | 0.064% | 0.894% |

## Major processes

| Role | Private working set median / p95 | Working set median / p95 | Private bytes median |
| --- | ---: | ---: | ---: |
| Renderer | 270.92 / 282.85 MiB | 328.35 / 339.85 MiB | 439.84 MiB |
| GPU process | 23.46 / 23.53 MiB | 47.95 / 48.52 MiB | 158.30 MiB |
| Browser | 21.15 / 21.98 MiB | 65.91 / 66.74 MiB | 51.82 MiB |
| Native shell | 3.45 / 3.45 MiB | 24.13 / 24.13 MiB | 10.92 MiB |

This is the first baseline collected under the fixed settle rule. It does not establish whether the current state is static text, media-heavy, voice, or another authenticated workload because normal mode exposes no CDP route/media metadata. The next controlled A/B must use the diagnostic checkpoint and record that metadata alongside this same settle rule.
