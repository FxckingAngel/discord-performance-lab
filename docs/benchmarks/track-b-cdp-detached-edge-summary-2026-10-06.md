# Track B detached-node edge summary

This is a sanitized graph pass over the private heap snapshot from `track-b-cdp-current-20261006-163748`. It emits aggregate node and edge types only. It does not publish object names, strings, URLs, message data, cookies, tokens, heap objects, or raw edges.

| Measurement | Result |
| --- | ---: |
| Detached nodes | 4,862 |
| Detached nodes with incoming edges | 4,862 |
| Detached nodes with no incoming edges | 0 |
| Detached-node type | Native |
| Detached native self size | 0.79 MiB |

| Incoming edge type | Count |
| --- | ---: |
| Element | 47,568 |
| Property | 6,620 |
| Weak | 2,698 |
| Internal | 1,683 |
| Shortcut | 1,542 |
| Context | 405 |

| Source node type | Incoming edge count |
| --- | ---: |
| Native | 50,336 |
| Object | 7,112 |
| Array | 1,679 |
| Closure | 1,542 |

The result says the detached nodes are still referenced in the snapshot graph, but it does not establish that they are Discord-owned leaks or that releasing them would be safe. Retaining-path work must continue locally before any frontend change.
