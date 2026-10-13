# Task: cloud-only areas fail on a computer that became a master

Reported 2026-10-13. Open.

## Symptom

On this computer, after "Create Master Server" while signed in online, the app's cloud-only areas
stop working; the cloud's data itself is intact (seen signed in online elsewhere).
- Channels: "We couldn't load your channels" (`ChannelsStatus.error`), not the section's locked message.
- Knowledge (frequent questions): acts as if it had nothing to work with.
- The real-time socket shows disconnected.

## What was ruled out

- The backend: `192.168.1.100` answered REST, the default socket.io namespace and `/presence`
  (`40/presence,` acknowledged); no entries in the backend's `logs/error` that day.
- A lock: Channels drew its error state, so `CapabilityService.of("channels")` was `available`: either
  `cloud`, or `hybrid` with `internet` and `linked` true. In `local`, or `hybrid` unlinked, it would
  have drawn `Unavailable` (`needsInternet` / `needsLink`).

## Leading hypothesis (not confirmed)

In `hybrid` every cloud call and the socket's handshake carry `BusinessModel.cloudKey` in
`business_id` (`BusinessService._use` → `useBusiness`). If the master's company is linked to a
company other than the one with the channels (e.g. a new empty one made by
`HybridService.createOnline`, or the wrong `linkCandidates` entry), or `cloudKey` falls back to the
master's own id, the REST calls fail or come back empty and the backend refuses the socket's
handshake (`select_business`), which socket.io does not retry.

Other candidates: the cloud token missing from `api` in the `hybrid` session (a session opened by
the cloud's grant), or `CapabilityService.linked` left true by `BusinessService._use` while the
active company was the cloud's and `Deployment.mode` changed after it.

## Evidence kept

- The master's store and this app's data at the time: `%LOCALAPPDATA%\Lyra\backup-2026-10-13`
  (`node` = the engine's folder; the others are the Hive boxes and secure storage `tool/clean.ps1`
  removes). The engine's store opens only with that master's keys, which are in that secure storage.
- Still to collect when reproduced: the debug console's `loadChannels failed:` line, the `business_id`
  the failing request carried, the server section's connection and sync line, and whether the active
  company had a `cloudId`.

## Done when

On a computer made a master from an online session, signed in online (`hybrid`): Channels,
Knowledge and the socket reach the same cloud company the account had before, and a test covers the
path that broke.
