# Track B manual functional checkpoint

Track B goal: **ACTIVE**.

Before the checklist prompts begin, `tools/Invoke-TrackBFunctionalCheckpoint.ps1` now requires exactly one responsive `KoroneDiscordShell` process. The report records that process's root PID, window title, and responsiveness at capture time. A missing or unresponsive shell cannot produce a functional result file.

The performance target is not sufficient by itself. Use `tools/Invoke-TrackBFunctionalCheckpoint.ps1` while the same manually prepared Track B session is visible. The checklist records only `PASS`, `FAIL`, `UNTESTED`, and short sanitized notes. Do not enter account identifiers, message content, tokens, screenshots, or profile data.

The final functional gate requires passing results for:

- login and session persistence;
- servers, channels, DMs, threads, and search;
- messaging, editing, reactions, attachments, and downloads;
- images, GIFs, stickers, embeds, and media;
- notifications;
- voice, microphone/output selection, and push-to-talk;
- camera/video;
- screen and window sharing;
- file dialogs, clipboard, drag/drop, and uploads;
- titlebar/window behavior, tray/startup behavior, keyboard navigation, scaling, themes, and accessibility.

An `UNTESTED` or `FAIL` result keeps the functional gate open. A performance result must not be called a successful Track B build until the functional checklist, visual parity review, desktop compatibility matrix, and full-tree benchmark all pass.
