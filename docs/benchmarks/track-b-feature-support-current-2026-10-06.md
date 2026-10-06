# Track B authenticated feature-support probe

Date: 2026-10-06  
Build: current `Verified` shell  
Mode: diagnostic authenticated profile, loopback CDP port 9228

The normal shell was closed through its normal window path, the diagnostic profile was launched, and the normal shell was relaunched afterward as PID 5776 and verified responsive.

The probe evaluated only a fixed list of human-readable names through the page's local `DiscordNative.features.supports` entry point. It wrote boolean/error results only. No page text, URL, cookies, tokens, account identifiers, or native values were collected.

## Result

The inspected profile did not expose a callable `DiscordNative.features.supports` function. The result now records `registryAvailable: false` and marks every fixed candidate `registry-unavailable`, including window, display, capture, file-dialog, clipboard, power-monitor, and safe-storage names. No candidate is labeled unsupported by this run.

Raw local result: `benchmarks/raw/track-b-feature-support-current-20261006.json`

## Interpretation

This is an inconclusive registry result. It does not prove that Discord does not use these desktop capabilities, and it does not authorize Track B to expose guessed methods. The existing compatibility matrix remains unchanged: only the audited window and display-count bridges are implemented. Further desktop parity work requires behavior-level evidence from a pristine Electron reference or a manually verified Discord scenario, not additional name spoofing.
