# Discord process-tree audit

The stock Discord PTB 1.0.1223 session was inspected read-only on 2026-10-06. The rooted tree contained six processes:

| Role | Function boundary | Current decision |
| --- | --- | --- |
| browser | Main Discord client process | Required |
| crashpad-handler | Crash reporting and recovery support | Do not remove without a separate crash-reporting decision |
| gpu-process | GPU composition and media acceleration | Required for the tested graphics and media boundary |
| renderer | Discord UI and web content | Required |
| utility/NetworkService | Network service | Required for normal connectivity |
| utility/audio.mojom.AudioService | Audio capture and playback service | Required for voice and media |

The process count was six with the stock launch and remained six after the system-managed QoS rollback and live EcoQoS probe. No child process was terminated or disabled. Removing a role would change the client’s supported execution boundary and would require separate paired startup, active-use, voice, video, screen-sharing, media, notification, and cleanup tests.

The benchmark collector now records a sanitized `role` field alongside PID, parent PID, creation time, resource counters, and process count. It does not publish command lines, account identifiers, message contents, or crash data.
