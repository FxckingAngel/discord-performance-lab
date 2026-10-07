# Track B lifecycle memory decay

Date: 2026-10-07  
Build: current Track B shell, root PID 45420  
Scenario: existing authenticated shell left visible and untouched  
Route/workload: not manually confirmed; diagnostic only  
Display: 1920x1080 at 60 Hz

## Result

The five-minute capture observed the same renderer and browser PIDs throughout. No renderer restart or shell change occurred during the capture.

| Metric | First sample | Median | Last sample | Range |
|---|---:|---:|---:|---:|
| Complete-tree private working set | 397.73 MiB | 311.02 MiB | 277.78 MiB | 277.78–397.73 MiB |
| Renderer private working set | 292.10 MiB | 232.67 MiB | 214.80 MiB | 214.80–292.10 MiB |
| Complete-tree CPU | captured | 0.053% | captured | p95 0.211% |
| Process count | 8 | 8 | 8 | 8 |

The renderer lifetime increased from 336.1 seconds to 676.8 seconds. The renderer PID remained 30988 and the browser PID remained 45712. The window stayed visible and responsive.

## Interpretation

Private resident memory declined without a code or behavior change. This establishes that the higher loaded readings can decay naturally during the lifetime of one renderer. It does not identify the allocation owner, prove that a resource is reclaimable by Track B, or establish the canonical authenticated route.

The result explains why the earlier approximately 316 MiB stable-window capture cannot represent a fixed fully loaded baseline. It is lifecycle evidence. The current normal loaded diagnostic reference remains the corrected five-run range of approximately 399–407 MiB complete-tree private working set and 294–299 MiB renderer private working set until a manually confirmed route is repeated.

The capture reports private working set separately from total working set, shareable working set, and private bytes. Shared pages are not treated as unique resident memory.

## Next measurement

The next controlled run should use one manually confirmed static route and record checkpoints at fresh launch, initialization, one minute, five minutes, and ten minutes. It should then perform normal navigation or media activity, return to the same route, and measure whether the released memory returns. Major allocation-base groups must be tracked through those transitions without assigning ownership from address shape alone.

No renderer behavior was changed as a result of this capture.
