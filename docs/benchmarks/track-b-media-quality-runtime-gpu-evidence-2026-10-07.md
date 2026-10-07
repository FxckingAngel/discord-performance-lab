# Track B runtime media/GPU evidence

Date: 2026-10-07

Status: diagnostic evidence only. This is not a media-quality parity pass.

The rebuilt Track B shell was restarted into `--diagnostic-authenticated-capability-events` and observed through loopback CDP. The sanitized media probe captured 131 images and reported device-pixel ratio 1. The WebView2 CDP endpoint rejected or omitted `GPU.getInfo`, so the probe recorded no GPU feature-status object and the media-quality acceptance comparison correctly remains false.

A separate read-only Windows process-tree inspection of the restored normal shell found eight processes, including one `msedgewebview2.exe` `gpu-process`, one renderer, browser, network/storage/audio utilities, and crashpad. No `--disable-gpu` or `--in-process-gpu` flag was present in the inspected tree.

The GPU process is host-side evidence that a GPU process exists. It is not treated as proof that every compositor or decode feature is hardware accelerated. The final media gate still requires paired official/Track B probe evidence and a non-software GPU feature result where the runtime exposes one.

No official Discord process was restarted, modified, injected, or reconfigured during this check. No account data, message content, URLs, image pixels, tokens, or private identifiers were written to the artifact.
