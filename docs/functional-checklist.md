# Functional acceptance checklist

Run this checklist for stock Discord and every candidate build or supported-setting profile. Record pass, fail, not tested, and evidence. A missing or degraded required feature blocks acceptance even when resource numbers improve.

## Identity and lifecycle

- [ ] Sign in and restore the expected account state.
- [ ] Open Discord from the normal shortcut or launch path.
- [ ] Close Discord normally and confirm all child processes exit.
- [ ] Relaunch after a normal close without stale-lock or recovery errors.
- [ ] Check that the normal update path still reports and applies updates.

## Navigation and messaging

- [ ] Open a server and a text channel.
- [ ] Switch channels and servers repeatedly.
- [ ] Receive a controlled notification.
- [ ] Send and receive a normal text message using a human-controlled account.
- [ ] Load older message history and verify scrolling remains responsive.
- [ ] Open links, attachments, emoji, and message context actions.

## Voice, video, and media

- [ ] Join and leave a voice call.
- [ ] Confirm microphone input and output devices.
- [ ] Confirm mute, deafen, and device switching.
- [ ] Start and stop a camera session when available.
- [ ] Start and stop screen sharing when available.
- [ ] Play and stop a fixed media item.
- [ ] Check reconnect behavior after a controlled network interruption.

## User-facing behavior

- [ ] Open settings and change a reversible preference.
- [ ] Confirm the preference persists after relaunch.
- [ ] Verify keyboard navigation for the tested workflow.
- [ ] Verify text scaling and reduced-motion preferences where configured.
- [ ] Confirm overlays or integrations that are in scope still work.
- [ ] Confirm notifications remain enabled and arrive once.

## Evidence requirements

For each checklist run, record the build or profile identifier, date, Windows version, scenario, operator, result, and evidence path. Do not include message contents, account identifiers, tokens, screenshots containing private conversations, or raw crash dumps in the repository.

## Acceptance rule

The candidate must pass every required item for its declared scope, and every failed or untested item must be reported. A performance improvement with a functional regression is rejected.
