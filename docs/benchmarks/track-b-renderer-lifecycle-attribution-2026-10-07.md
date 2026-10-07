# Track B renderer lifecycle attribution

Date: 2026-10-07

This report summarizes an automatic lifecycle capture of the Track B renderer.
The route was not manually confirmed, so these values are diagnostic evidence,
not authenticated acceptance evidence. Raw process maps, CDP output, and
address-level resident-memory captures remain private.

## Lifecycle checkpoints

| Checkpoint | Complete-tree private WS | Renderer private WS | Renderer V8 used | Renderer private WS outside V8 | Renderer process count |
| --- | ---: | ---: | ---: | ---: | ---: |
| Blank | 94.97 MiB | 9.76 MiB | 0.50 MiB | 9.26 MiB | 1 |
| Navigation | 627.89 MiB | 514.03 MiB | 56.56 MiB | 457.47 MiB | 1 |
| Application shell | 430.96 MiB | 326.84 MiB | 149.68 MiB | 177.16 MiB | 1 |
| Canonical route | 402.98 MiB | 298.39 MiB | 98.67 MiB | 199.72 MiB | 1 |
| Settled 1 minute | 402.86 MiB | 297.76 MiB | 103.75 MiB | 194.01 MiB | 1 |
| Settled 5 minutes | 396.94 MiB | 288.88 MiB | 94.78 MiB | 194.10 MiB | 1 |
| Settled 10 minutes | 377.13 MiB | 276.12 MiB | 90.36 MiB | 185.76 MiB | 1 |

The process tree contained eight processes after Discord navigation. CPU was
below the idle target at the settled checkpoints. The renderer remained the
dominant private-resident owner.

## Allocation-family lifecycle

Allocation-family IDs are one-way hashes used only to correlate the same
allocation base within this capture. They do not identify an allocator or
module.

| Family | Navigation | Application shell | Settled 1 minute | Settled 10 minutes | Observation |
| --- | ---: | ---: | ---: | ---: | --- |
| Largest family | 220.88 MiB | 53.10 MiB | 77.26 MiB | 67.45 MiB | Large navigation peak, mostly released before settlement |
| Second family | 52.19 MiB | 27.64 MiB | 37.40 MiB | 33.54 MiB | Persists after load and remains a major settled family |
| Third family | 43.09 MiB | 17.75 MiB | 17.75 MiB | 17.75 MiB | Stable after application-shell creation |
| Top three combined | 316.15 MiB | 98.48 MiB | 132.41 MiB | 118.74 MiB | Does not account for the complete renderer resident set |

## What this establishes

The largest allocation family is strongly lifecycle-dependent. It is not a
fixed blank-WebView2 floor because the blank checkpoint's top family was only
3.09 MiB, while the navigation checkpoint reached 220.88 MiB. Most of that
family was released before the application-shell checkpoint.

The settled state still retains approximately 118.74 MiB in the three largest
families, while the renderer retains 276.12 MiB private working set at ten
minutes. The remaining resident memory is distributed across smaller private
families, mapped or image pages, and allocations not identified by this
address-family scan. The family sizes do not prove Blink, Skia, compositor,
media, or application ownership.

The capture also shows that V8 used heap and renderer private working set move
independently. At the ten-minute checkpoint, V8 used heap was 90.36 MiB while
the renderer retained 185.76 MiB outside that measurement. This supports
continuing native/rendering attribution rather than treating JavaScript heap
growth as the sole cause.

## Next experiment

The next high-value comparison is a manually confirmed static route versus a
manually confirmed media-heavy route, with the same renderer lifecycle and
per-checkpoint family correlation. The comparison must preserve visible media
behavior. No renderer behavior, cache policy, Chromium flag, working set, or
garbage-collection setting was changed from this evidence.

Source artifacts are retained locally under the private Track B lifecycle
capture directory. Only the aggregates above belong in the repository.
