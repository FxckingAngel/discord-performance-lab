# Decision 0028: capability implementation stays separate from activation

Date: 2026-10-07

Track B will implement desktop capability groups in isolated harnesses, but will expose `DiscordNative` to Discord only as one coherent, fully tested boot contract. A passing isolated group is not permission to add that group to the normal shell.

The current atomic candidate remains rejected. It exposes the observed metadata, storage, Erlang packing, process utilities, and IPC recorder, but Discord leaves `#app-mount` empty. Startup also requests `discord_voice` and `discord_utils`, while generic IPC behavior and the complete native-module boundary remain unresolved. The normal shell therefore continues to expose no `DiscordNative` root object.

The next isolated implementation target is the seven-method clipboard group:

`copy`, `copyImage`, `copyFile`, `cut`, `paste`, `read`, and `hasMixedContent`.

The implementation must use a real Windows owner and match the observed method and error shapes. Synthetic tests may use generated text, an in-memory image, and a temporary file. They must not read, publish, or overwrite the user's existing clipboard. The group remains diagnostic-only until its behavior, security boundary, and resource cost are tested.

The next atomic Discord activation is not selected from group names alone. It requires a sanitized startup behavior trace or equivalent evidence showing the complete coherent set Discord consumes before the application initializes. The candidate must then be enabled together and pass the existing readiness gate: valid route, populated `#app-mount`, normal document structure, synchronized renderer inventory, and no white-page regression.

The clean official Discord control remains read-only. Track B may be restarted for build and diagnostic work.
