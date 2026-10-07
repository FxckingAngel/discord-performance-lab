# Track B CDP and Windows attribution join: 2026-10-06

This run correlated the browser-level CDP process inventory with the rooted Windows process sampler during the same authenticated diagnostic session. The join uses the verified equality between CDP `id` and Windows PID for WebView2 process roles.

## Joined final sample

| Role | CPU time from CDP | Private working set | Private bytes |
| --- | ---: | ---: | ---: |
| Browser | 1.274 s | 36.52 MiB | 44.99 MiB |
| Renderer | 0.779 s | 112.57 MiB | 126.47 MiB |
| GPU | 0.333 s | 17.69 MiB | 58.77 MiB |
| Network service | 0.488 s | 8.75 MiB | 14.15 MiB |
| Storage service | 0.062 s | 3.11 MiB | 7.70 MiB |
| Native shell | not exposed by CDP | 9.06 MiB | 12.61 MiB |
| Crashpad | not exposed by CDP | 2.09 MiB | 3.38 MiB |

Five of seven Windows rows matched CDP process roles. The two unmatched rows are expected host-side processes: the native WinForms shell and crashpad. The join therefore preserves complete-tree accounting while adding Chromium role-level CPU data.

## Interpretation

The renderer was the largest private-memory owner in this diagnostic sample and also had the largest CDP cumulative CPU time among the WebView2 roles. The GPU's private bytes remained much higher than its private working set, so GPU commit and resident memory must remain separate metrics. No optimization was applied from this single sample.

Raw files remain local: `artifacts/join-cdp.json`, `artifacts/join-windows.json`, and `artifacts/join-result.json`.
