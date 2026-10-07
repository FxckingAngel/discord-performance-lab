# Track B renderer heap-to-resident boundary

This is a boundary calculation from the Verified authenticated diagnostic. The route and workload were not manually verified.

| Measurement | MiB |
| --- | ---: |
| Renderer private working set | 316.39 |
| Heap snapshot summed self-size | 171.37 |
| Difference | 145.02 |

The heap snapshot self-size is about 54.2% of the renderer private working set, leaving approximately 145.02 MiB, or 45.8%, outside that snapshot self-size. That remainder includes memory the snapshot does not represent, such as renderer/runtime allocations, mapped or shared pages counted in the process boundary, and other native resources. It must not be labeled as one specific Blink, media, or Chromium category without direct evidence.

This boundary confirms that reducing JavaScript object retention alone is unlikely to close the entire Track B gap. Future candidates must measure both the heap summary and the Windows private resident counters, with functional checks and rollback.
