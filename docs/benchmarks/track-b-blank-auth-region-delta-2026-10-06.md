# Track B blank-to-authenticated private-region delta

Date: 2026-10-06

Comparison artifact: `artifacts/track-b-feature-summary-refresh-20261006.json`

This comparison uses the repeated blank Release capture `track-b-release-blank-floor-rep-retry-20261006` as the baseline and the authenticated-no-bridges capture `track-b-release-auth-delta-refresh-9230-20261006` as the candidate. The captures are not a same-route acceptance benchmark; the authenticated route/workload was not manually verified.

## Resident delta

| Category | Authenticated minus blank |
| --- | ---: |
| Resident classification | +498.784 MiB |
| Private-writable resident | +373.700 MiB |
| Committed private-writable | +446.930 MiB |
| Mapped resident | +35.960 MiB |
| Image resident | +88.629 MiB |

## Private-writable region shape

| Region size | Delta in resident bytes |
| --- | ---: |
| Under 64 KiB | +62.947 MiB |
| 64 KiB–1 MiB | +152.180 MiB |
| 1–4 MiB | +91.261 MiB |
| 4–16 MiB | +66.742 MiB |
| 16 MiB or larger | +0.570 MiB |

The loaded Discord state adds many small and medium private-writable regions rather than one dominant giant allocation. This makes a single arena-size or working-set switch an unlikely solution. The next useful engineering work is to correlate these deltas with frontend state categories such as retained application data, decoded resources, Blink state, and compositor resources. No optimization is accepted from this comparison alone.
