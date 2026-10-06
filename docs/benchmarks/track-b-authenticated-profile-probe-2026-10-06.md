# Track B authenticated-profile probe

Date: 2026-10-06

The temporary `--diagnostic-authenticated` mode reused the ordinary `WebView2UserData` profile with localhost CDP port 9228. The ordinary shell was closed before each probe and restored afterward. No credentials, cookies, tokens, page text, or account identifiers were read or written.

The `/app` route created a page with 974 aggregate DOM nodes, 1,038 CDP performance nodes, 32 JavaScript listeners, 673 resources, and 32.5 MiB V8 heap used. The private CDP screenshot remained blank white after both 8-second and 20-second waits. Because the rendered state was not visible, this probe cannot establish whether the profile is logged in, which route state is shown, or whether a static channel is available.

The result is therefore inconclusive. It is not an authenticated benchmark and must not be used for visual parity or performance acceptance. The normal shell was restored and verified responsive after the probe.
