# Decision 0007: do not synchronously dispose WebView2 during form close

Date: 2026-10-06

## Experiment

The shell was changed temporarily to call `webView.Dispose()` from the `FormClosed` handler, with the aim of guaranteeing that WebView2 helper processes exited with the native window.

## Result

The diagnostic blank shell remained alive and responsive after `CloseMainWindow()` for more than 10 seconds. Its WebView2 browser, renderer, GPU, network, storage, and crashpad children also remained attached. The explicit disposal call was removed.

The restored build passed the real executable smoke test for `--diagnostic-blank` and `--diagnostic-capability-events`. After both normal closes, there were zero diagnostic roots and zero matching WebView2 children. The normal shell restarted and remained responsive.

## Decision

Do not synchronously dispose the WebView2 control from `FormClosed`. The current close path remains the rollback baseline until a non-blocking shutdown design is measured. This experiment did not change the normal shell resource target or claim a cleanup improvement.
