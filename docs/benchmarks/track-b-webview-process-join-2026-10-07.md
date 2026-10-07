# Track B Windows-to-WebView2 process join

Date: 2026-10-07

Added `tools/Join-TrackBWebViewProcessInfo.ps1` to join a Windows process-tree capture with the shell's refreshed WebView2 process inventory using local PIDs. The output contains only role, process kind, active-frame count, and aggregate memory fields.

A fresh verification produced:

- Windows process rows: 8
- WebView2 inventory rows: 6
- process-count delta: 2
- matched rows: 6
- renderer PID match: true
- WebView2 inventory contains no crashpad row, as expected

The count delta is reported explicitly because the two sources are snapshots and a utility process can exit between them. Renderer identity is considered valid only when exactly one Windows renderer and one WebView2 renderer are present and their PIDs match.

The utility does not access command lines, page content, cookies, tokens, heap objects, or network data.
