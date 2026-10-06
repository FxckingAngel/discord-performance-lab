# Track B page-level working-set diagnostic

Date: 2026-10-06

This is a read-only diagnostic of the current seven-process Track B tree. It uses the Windows `QueryWorkingSet` API to inspect resident-page flags for each process. Microsoft documents the PSAPI `Shared` flag as indicating that a page can be shared, while `ShareCount` reports the number of processes sharing a page. Neither field provides cross-process physical-page identity, so this capture is not a replacement for the benchmark's private-working-set or private-bytes metrics.

Source: [PSAPI_WORKING_SET_EX_BLOCK](https://learn.microsoft.com/en-us/windows/win32/api/psapi/ns-psapi-psapi_working_set_ex_block) and [QueryWorkingSetEx](https://learn.microsoft.com/en-us/windows/win32/api/psapi/nf-psapi-queryworkingsetex).

## Capture

- Root PID: 38760
- Process count: 7
- Available page queries: 7
- Raw artifact: `benchmarks/raw/track-b-working-set-pages-flags-20261006.json`
- No Discord state, shell setting, working set, priority, sandbox, or authentication state was changed.

The probe was repeated three times at 15-second spacing against the same root PID. Resident totals were 528.99, 529.00, and 528.97 MiB. The corresponding PSAPI `Shared`-flag totals were 161.36 MiB in all three samples, `ShareCount > 1` totals were 2.18 MiB in all three, and single-owner totals were 329.80 MiB in all three. The repeated result makes the classification discrepancy reproducible for this settled state.

## Tree totals

| Classification | MiB |
| --- | ---: |
| Resident pages returned by QueryWorkingSet | 527.016 |
| Pages with the PSAPI `Shared` flag | 160.598 |
| Pages without the PSAPI `Shared` flag | 169.734 |
| Pages with `ShareCount > 1` | 2.184 |
| Pages with `ShareCount <= 1` | 328.148 |

The classifications intentionally do not add to one another. The `Shared` flag and `ShareCount` answer different questions, and the latter is not a physical-page identity that can be safely deduplicated across the entire tree.

## Largest roles

| Role | Resident | PSAPI Shared flag | ShareCount > 1 |
| --- | ---: | ---: | ---: |
| renderer | 182.21 MiB | 29.68 MiB | 0.21 MiB |
| browser | 137.99 MiB | 51.46 MiB | 0.07 MiB |
| GPU | 67.63 MiB | 24.73 MiB | 0.64 MiB |
| native shell | 59.87 MiB | 22.45 MiB | 0.68 MiB |
| network utility | 46.07 MiB | 18.18 MiB | 0.27 MiB |

## Interpretation

This diagnostic confirms that ordinary summed working set includes pages with different sharing characteristics, but it does not prove that 160.6 MiB can be removed from the application's physical footprint. The `ShareCount > 1` total is much smaller because most resident pages are either private or only mapped by one process at the instant of capture. The existing performance-counter values remain the acceptance metrics: private working set for unique/private resident RAM and private bytes for committed private memory.

The discrepancy between the page classifications and `Working Set - Private` is useful evidence for future accounting work, not an optimization result. The 250 MiB target remains active and unchanged.
