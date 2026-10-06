# Functional run

- Date: 2026-10-06
- Operator: User-authorized local test
- Client build: Discord PTB 1.0.1223
- Profile and launch arguments: stock launch, no optimization switches
- Windows version: not recorded
- Scope: stock

## Results

| Checklist area | Result | Evidence |
| --- | --- | --- |
| Identity and lifecycle | pass | Computer Use found the single Discord PTB window titled `@xoxo - Discord`; the window responded to state capture |
| Navigation and messaging | not tested | No server, channel, or message action was performed |
| Voice, video, and media | not tested | No call or media action was performed |
| User-facing behavior | pass | Computer Use captured the live Discord window without restarting or modifying the client |

## Notes

The process tree remained at six processes during the read-only check. The accessibility tree exposed the server sidebar, direct-message list, Friends, User Settings, voice controls, camera, screen sharing, soundboard, and media controls. Those controls were observed but not activated. The client remained on the stock profile. No messages, settings, permissions, or account data were changed.
