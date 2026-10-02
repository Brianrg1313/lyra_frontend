# Module: local_server section

**Path** `lib/screens/home/sections/local_server`
**Role** The master's devices, inside the home (`HomeSection.server`, `/home/server`, area `local_server`): on a
master's devices, and online on any computer, which creates one there (`docs/plan-offline-lan.md` §4 admin screens, §5.3, D16).
**Services** `LanService`, `HybridService` (`lib/services/lan`).

## Files

- `_local_server.dart` — `LocalServerSection`: the master's session ready (not in `cloud`) → `_ServerReady`, else
  `ServerAway`. `_ServerReady`: `ServerConnection` first; the address browsers open (`LanAddress`); this device's code and CA fingerprint; the devices list (refreshed every
  5 s, online / server / removed), remove (confirmed), "Add device" on the master (the code to type and `PairingQr`);
  `LanBrowsers` on native devices (both from one `devices.browserCa` read); sign out (`ClientService.signOut`); stop the server (confirmed, counts connected
  devices).
- `widgets/lan_address.dart` — `LanAddress`: the web address (`.local` name, the IP below), copied with a button.
- `widgets/lan_browsers.dart` — `LanBrowsers`: the browsers' root (`devices.browserCa`): SHA-256 and SHA-1 fingerprints,
  install on this computer (Windows, macOS) or save as `.crt`.
- `widgets/pairing_qr.dart` — `PairingQr`: the pairing QR painted from `package:qr`, always black on white.
- `widgets/server_connection.dart` — `ServerConnection`: for a session opened online (`HybridService.joined`), online or
  offline by choice, "work offline" / "work online", and the owner's "join with your company online" while unlinked.
- `widgets/server_away.dart` — `ServerAway`: online without the master's session: a paired device's "server isn't
  answering" + try again (`resume`, or the master password once); a computer with none, "create the server here" (the
  cloud company's owner only) → the master setup body with the account and `HybridService.companyFrom` → `adopt` →
  `resolve` → back to `/home/server`; an engine this computer can't run says so.
