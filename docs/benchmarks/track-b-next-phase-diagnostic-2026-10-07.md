# Track B next-phase diagnostic capture

This was a five-repetition capture against the already-running Track B shell.
The manual route checkpoint was intentionally skipped, so the result is
diagnostic evidence only. It is not an authenticated same-route acceptance
baseline.

Raw output is local under:

`artifacts/track-b-next-phase-diagnostic-20261007/`

## Process stability

- Root PID: 41248
- Renderer PID: 30612 in all five repetitions
- Process count: 8 in all five repetitions
- Display: 1920x1080 at 60 Hz
- Window: visible and responsive
- Official Discord: not touched

## Five-run summary

The collector sampled each repetition for 30 seconds after a five-second
settle interval.

| Metric | Median | P95 |
| --- | ---: | ---: |
| Complete-tree working set | 318.17 MiB | 359.67 MiB |
| Complete-tree private working set | 239.52 MiB | 262.87 MiB |
| Complete-tree private bytes | 600.55 MiB | 622.04 MiB |
| Complete-tree CPU | 0.045% | 0.901% |
| Renderer working set | 228.02 MiB | 244.12 MiB |
| Renderer private working set | 193.14 MiB | 206.05 MiB |
| Renderer private bytes | 331.16 MiB | 338.48 MiB |
| GPU private working set | 26.96 MiB | 33.48 MiB |

The renderer remained the largest private-resident process. Its median private
working set is materially below the earlier approximately 313 MiB authenticated
observation, which confirms that Track B's current memory state is strongly
state-dependent.

## Interpretation

This run does not prove that Track B reached the 250 MiB goal. The route and
frontend readiness were not manually confirmed, so the lower state may be an
incomplete, different, or recently initialized Discord state. The result does
establish a useful controlled comparison point: the renderer PID and process
inventory were stable while the shell was responsive.

The next attribution step is to pair this state with the authenticated
readiness probe and compare DOM population, route class, V8 heap, and major
allocation families before treating the lower renderer footprint as a valid
optimization candidate.
