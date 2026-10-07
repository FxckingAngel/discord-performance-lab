# Track B live renderer boundary capture

This is a read-only boundary capture of the existing normal shell. It is paired with the current live follow-up observations but does not independently verify the authenticated route or workload.

## Process state

- Root PID: 39116
- Renderer PID: 28160
- Process count: 8
- Classification: `VirtualQueryEx` plus `QueryWorkingSetEx`
- Cross-process physical-page deduplication: not performed

## Renderer memory boundary

| Classification | MiB |
| --- | ---: |
| Private bytes | 474.88 |
| Resident memory classified by the scan | 361.57 |
| Private-writable resident | 318.79 |
| Committed private-writable | 461.55 |
| Image resident | 37.99 |
| Mapped resident | 4.27 |

The private-writable resident result is consistent with the approximately 315 MiB renderer private-working-set median from the 60-second follow-up. It is not V8 attribution and does not imply that the anonymous regions belong to Discord application state.

## Largest observed allocation-base groups

| Allocation base | Regions represented | Resident | Committed |
| --- | ---: | ---: | ---: |
| `0x39400000000` | 14 | 97.63 MiB | 100.75 MiB |
| `0x5E0C00000000` | 5 | 35.42 MiB | 46.88 MiB |
| `0x4AE800000000` | 4 | 34.96 MiB | 37.13 MiB |
| `0x7FFEC31C0000` | 1 | 16.16 MiB | 17.25 MiB |
| `0xF6700000000` | 2 | 7.01 MiB | 7.50 MiB |

The first three groups account for approximately 168.01 MiB of the represented resident regions. They remain correlation targets only. Ownership still requires lifecycle or stack evidence, and no renderer behavior was changed from this capture.

Raw artifacts remain local under `artifacts/track-b-live-boundary-20261007/`.
