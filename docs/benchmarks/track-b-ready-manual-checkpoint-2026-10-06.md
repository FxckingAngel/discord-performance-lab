# Track B manual checkpoint benchmark

Date: 2026-10-06

This run used the user's `READY` confirmation as the manual checkpoint. Track B was launched from the verified shell build and measured without UI automation. The official Discord client remained open and was not included in the Track B process tree.

Scenario: authenticated settled idle, using the state present after launch and manual preparation.

Capture: 621.2 seconds, 20 samples, 30-second interval, seven processes, one renderer.

| Metric | Median | P95 | Target |
| --- | ---: | ---: | ---: |
| Summed working set | 531.56 MiB | 546.06 MiB | diagnostic |
| Private working set | 178.14 MiB | 192.18 MiB | physical-resident diagnostic |
| Private bytes / commit | 256.32 MiB | 274.05 MiB | approximately 250 MiB |
| Total CPU | 0.008% | 0.008% | 0.2% |
| Process count | 7 | 7 | no fixed target |
| Renderer count | 1 | 1 | attribution required |
| Handles | 3546.5 | 3667.2 | diagnostic |
| Threads | 173 | 200.65 | diagnostic |

Role medians:

| Role | Working set | Private working set | Private bytes / commit |
| --- | ---: | ---: | ---: |
| Browser | 199.99 MiB | 41.43 MiB | 54.17 MiB |
| Renderer | 182.53 MiB | 106.64 MiB | 120.31 MiB |
| GPU | 68.42 MiB | 17.17 MiB | 58.20 MiB |
| Network service | 46.65 MiB | 8.18 MiB | 13.29 MiB |
| Storage service | 20.10 MiB | 3.00 MiB | 7.55 MiB |
| Crashpad | 13.69 MiB | 1.77 MiB | 2.89 MiB |

Interpretation:

- The CPU target passes by a wide margin in this captured settled window.
- Private working set is below 250 MiB, but private bytes / commit is slightly above the 250 MiB goal. This remains a near miss, not a pass for the complete Track B target.
- The single renderer's median private working set is 106.64 MiB and median private bytes are 120.31 MiB in this run. These values are process attribution, not a claim that all renderer memory is JavaScript memory.
- The result is valid as a manual-checkpoint process measurement. The exact route, account, and workload remain user-confirmed rather than machine-verifiable in this artifact.

Raw samples, including per-process PIDs and local role mappings, remain outside the public repository at:

`benchmarks/raw/track-b-ready-manual-checkpoint-20261006-064727.json`

The raw file must remain private because command-line and process metadata can reveal local installation details.
