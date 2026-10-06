# Track B decision 0021: prioritize frontend parsing and state-retention investigation

Date: 2026-10-06

## Evidence

Three short authenticated-no-bridges diagnostic captures produced V8 allocation-sampling results with 1,263 to 1,290 samples each and 66.83 to 67.07 MiB reported V8 used heap. The same allocation leads recurred in all three windows:

| Sampled allocation lead | Approximate sampled self bytes across runs |
| --- | ---: |
| `_._parseBody` | 5.06–6.29 MiB |
| Discord web bundle | 2.73–4.18 MiB |
| `unpack` | 2.38–2.47 MiB |
| `get`, `set`, `T`, `l`, `f` | recurring smaller entries |

## Decision

The next renderer investigation should examine message/state parsing, unpacking, and the objects retained by those paths. Use local heap snapshots or sanitized retaining-path summaries to determine whether these are live retained objects, transient allocations, or merely hot allocation sites.

Do not change Discord's frontend, patch the bundle, or remove message history based on this table. Allocation-sampling self bytes are not retained size and cannot be subtracted from renderer private working set. No optimization is accepted until the ownership, lifetime, functionality impact, and complete-tree memory effect are measured.

Raw CDP artifacts remain private under `artifacts/`.
