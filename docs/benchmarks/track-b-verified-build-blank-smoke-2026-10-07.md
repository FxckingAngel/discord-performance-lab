# Track B verified-build blank diagnostic smoke test

The rebuilt `track-b/discord-shell/bin/Verified/KoroneDiscordShell.exe` was launched with `--diagnostic-blank` while the existing normal Release shell remained untouched.

Result:

- The diagnostic window became responsive.
- The title was `Korone's Discord Shell (Runtime Baseline)`.
- The process closed through its normal window-close path.
- No recent WebView2 helper processes remained after shutdown.

This verifies startup and clean shutdown of the rebuilt binary's blank diagnostic mode. It does not verify authenticated Discord behavior or the 250 MiB performance target. The normal Release shell still needs to exit before the full single-instance smoke test and a clean Verified normal-shell benchmark can run.

The same Verified binary was also launched with `--diagnostic-capability-events`. It became responsive with the expected capability-probe title and closed normally. No capability-event log was created because the untouched diagnostic page generated no permission or notification events.
