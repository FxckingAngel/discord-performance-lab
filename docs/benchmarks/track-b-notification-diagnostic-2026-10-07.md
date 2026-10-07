# Track B notification diagnostic contract

WebView2 already provides a host notification event through `CoreWebView2.NotificationReceived`. Track B keeps that event behind the existing isolated `--diagnostic-capability-events` mode and leaves WebView2's default notification behavior unchanged.

The diagnostic handler records only the event type and sender origin. `tools/Test-TrackBNotificationDiagnostic.ps1` checks that the source does not read title, body, message, or tag fields, starts the isolated mode on loopback port 9231, verifies that the shell remains responsive, and rejects those content fields if any diagnostic log is emitted. The test does not create a notification and does not expose `DiscordNative` in the normal shell.

This is a host telemetry contract, not a desktop notification parity result. Receiving and opening a real Discord notification remains a manual functional checkpoint.
