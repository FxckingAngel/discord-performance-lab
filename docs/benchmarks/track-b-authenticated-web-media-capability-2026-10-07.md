# Track B authenticated WebView2 media capability checkpoint

Date: 2026-10-07  
Mode: diagnostic-only `--diagnostic-authenticated-capability-events`, loopback CDP port 9232

The existing authenticated Track B profile was inspected without starting a call, opening a camera, requesting microphone access, or selecting a capture source.

| Capability | Result |
| --- | --- |
| `navigator.mediaDevices` | present |
| `getUserMedia` | present |
| `getDisplayMedia` | present |
| audio input devices | 1 |
| audio output devices | 1 |
| video input devices | 1 |
| microphone permission | prompt |
| camera permission | prompt |
| notification permission | prompt |
| device labels retained | 0 |

This confirms that the authenticated WebView2 environment has the browser media primitives needed for a controlled voice/video investigation. It does not prove that Discord's current desktop-identity path uses them successfully. No device labels, media, account data, URLs, or permission grants were recorded.

The next checkpoint must manually test microphone permission, outgoing/incoming voice, camera, and screen sharing. The host should preserve explicit consent and WebView2's default media/capture flow while recording sanitized event metadata. No `DiscordNative` bridge is enabled in the normal shell.
