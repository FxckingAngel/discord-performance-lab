# Decision 0001: client boundary

## Status

Accepted for the current project scope.

## Decision

Discord Performance Lab will not patch, unpack, replace, inject into, or redistribute the installed Discord client. It will not remove Discord-selected processes or alter Discord's network, authentication, update, signature, or security behavior.

The current implementation boundary is:

- read-only measurement of the installed client;
- experiments using settings exposed through Discord's normal user interface;
- external, reversible test tooling that does not modify the client or impersonate a user;
- functional and performance validation against the stock installation.

If written permission, source code, or a separately licensed client becomes available, a new decision can define a source-controlled build boundary.

## Reason

The installed PTB build is proprietary. Discord's [Terms of Service](https://discord.com/terms) grant a license to run the client to access the service and state that users may not copy, modify, or create derivative works of the software without written consent or a legal exception. The project goal requires preserving normal Discord functionality, so changes that bypass the client boundary would also weaken the evidence for official-quality behavior.

This does not prevent useful work. The project can first establish repeatable baselines, identify which cost belongs to the process tree, and test supported settings without risking the account, installation, or update path.

## Consequences

- A lower resource number alone cannot justify an unsupported client modification.
- The benchmark harness remains useful for stock-versus-supported-setting comparisons.
- Any future candidate must identify its authority, rollback path, and functional scope before implementation.
- The project may conclude that a requested reduction is not available within the supported boundary. That is a measured result, not a failed benchmark.
