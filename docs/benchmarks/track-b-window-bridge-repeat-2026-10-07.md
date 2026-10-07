# Track B isolated window bridge repeat

Date: 2026-10-07  
Mode: isolated `--diagnostic-bridge-pair`, loopback CDP port 9229

The existing narrow window bridge was exercised again after the current shell build. The probe called `focus`, `maximize`, `restore`, `minimize`, `restore`, and `focus` through CDP. Every call returned the expected local acknowledgement, and the diagnostic process was then terminated. The normal Track B shell remained running and responsive throughout.

This verifies the shell-owned single-window behavior again. It does not prove that Discord's frontend uses the group, and it does not authorize exposing `DiscordNative.window` by itself. The normal shell continues to expose no partial `DiscordNative` object. Official Discord was not modified.
