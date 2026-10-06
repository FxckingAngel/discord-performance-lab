# Decision 0001: client boundary

## Status

Accepted for the current project scope. Updated after Korone explicitly authorized local client modification and restart testing for this project.

## Decision

Discord Performance Lab may test a private, reversible performance modification of the local Discord client. The modification must be limited to reducing client work or resource use. It must not provide access to features or data the account is not entitled to use.

The project will not distribute a modified Discord client, and it will not alter Discord's network protocol, authentication, authorization, update, signature, or security behavior.

The current implementation boundary is:

- read-only measurement of the installed client;
- experiments using settings exposed through Discord's normal user interface;
- private, reversible performance-only client experiments with a stock launch path preserved;
- external test tooling that does not impersonate a user or send messages automatically;
- functional and performance validation against the stock installation.

If written permission, source code, or a separately licensed client becomes available, a new decision can define a source-controlled build boundary.

## Reason

The installed PTB build is proprietary. Discord's [Terms of Service](https://discord.com/terms) restrict copying, modifying, and creating derivative works without written consent or a legal exception. Korone's project authorization permits the local experiment described here, but it does not change Discord's terms or authorize distribution.

The safety boundary follows the relevant principles in [BetterDiscord's plugin guidelines](https://docs.betterdiscord.app/plugins/publishing/guidelines): no ban-risk behavior, security-feature disabling, private-data access, unconsented data collection, or changes that remain active after disablement. Those guidelines are reference criteria, not a claim that this project is an approved BetterDiscord addon.

This does not prevent useful work. The project can first establish repeatable baselines, identify which cost belongs to the process tree, and test supported settings without risking the account, installation, or update path.

## Consequences

- A lower resource number alone cannot justify a candidate that weakens security, privacy, or account authorization.
- Every candidate needs a stock launch path, backup, disable procedure, and functional test record.
- The benchmark harness remains useful for stock-versus-candidate comparisons.
- Any candidate that changes protocol, authorization, or access to private data is rejected.
- The project may conclude that a requested reduction is not available within the permitted boundary. That is a measured result, not a failed benchmark.
