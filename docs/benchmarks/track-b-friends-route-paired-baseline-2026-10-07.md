# Track B Friends-route paired baseline

Date: 2026-10-07  
Official control: isolated vanilla PTB 1.0.1223, manually authenticated  
Track B: normal Release shell with verified client hints  
Display: 1920x1080 at 60 Hz

## Route

The official control was confirmed at `ptb.discord.com/channels/@me` with the title `Friends`. Track B's separate diagnostic profile was navigated to `/channels/@me`; the sanitized checkpoint reported `discord-channels` on the `https://discord.com` origin. The normal Track B shell was then restored using that same profile and measured without a native Discord bridge.

## Settled measurement

The official control used ten samples at five-second intervals. Track B used a warm-up capture followed by a ten-sample follow-up after the exact-route checkpoint.

| Client | Complete-tree private working set | Renderer private working set | Process count |
|---|---:|---:|---:|
| Official vanilla | 516.62–548.05 MiB, median 539.56 MiB | median 378.99 MiB | 6 |
| Track B, Friends route | 464.78–507.83 MiB, average 483.14 MiB | average 370.68 MiB | 8 |

The Track B follow-up CPU samples had a short-run median of approximately 0.26% and one 1.20% sample. This is not a long CPU acceptance run; CPU is not the current optimization priority.

## Interpretation

Track B is approximately 56 MiB below the official control at the reported central values, but it remains approximately 233 MiB above the 250 MiB private-resident target. The renderer remains the dominant memory owner. This baseline is now suitable for attribution and A/B experiments because the route class and origin were separately confirmed on both clients.

No visible media, voice, video, notifications, or other normal Discord functionality was disabled. No working-set trimming, forced collection, or protocol/security change was used.

The next experiment must decompose the Track B renderer at this exact route into V8, DOM/layout, image/media, compositor, and other native allocations before changing behavior.
