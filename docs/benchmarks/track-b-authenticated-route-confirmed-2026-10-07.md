# Track B authenticated route confirmation

Date: 2026-10-07  
Track B diagnostic mode: `--diagnostic-authenticated-no-bridges`  
Profile: existing Track B WebView2 profile  
Official control: isolated vanilla PTB profile, manually authenticated to Friends

## Route evidence

The Track B CDP diagnostic reported:

| Field | Result |
|---|---|
| Route class | `discord-app` |
| Target origin | `https://discord.com` |
| Authenticated profile | Yes, the app route loaded rather than the login route |
| Renderer behavior | Existing frontend initialized with no partial native bridge |

The official reference independently reported the Friends route at `https://ptb.discord.com/channels/@me`. Track B's current diagnostic route is authenticated but not yet pinned to that exact Friends path, so the paired measurements remain diagnostic rather than final same-route acceptance evidence.

## Follow-up Track B capture

After route confirmation, the normal client-hints shell was restored and measured for ten samples at five-second intervals.

| Metric | Result |
|---|---:|
| Complete-tree private working set | 429.32–486.17 MiB |
| Complete-tree private working set average | 450.45 MiB |
| Renderer private working set | 321.44–364.85 MiB |
| Renderer private working set average | 340.35 MiB |
| Process count | 8 throughout |

The memory decline and later rise show that lifetime state is still affecting the result. No renderer behavior, feature, media path, or security setting was changed.

## Next gate

Use a controlled navigation checkpoint to place Track B on the same Friends route as the official reference, then repeat the settled process-tree capture. Do not use the current percentage difference as the final A/B claim until that exact route pairing is recorded.
