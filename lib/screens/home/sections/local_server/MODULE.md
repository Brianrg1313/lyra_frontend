# Module: local_server section

**Path** `lib/screens/home/sections/local_server`
**Role** The master's devices, inside the home (`HomeSection.server`, `/home/server`, area `local_server`): on a
master's devices, and online on any computer, which creates one there (`docs/plan-offline-lan.md` §4 admin screens, §5.3, D16).
**Services** `LanService`, `HybridService`, `SyncService` (`lib/services/lan`).

## Files

- `_local_server.dart` — `LocalServerSection`: the master's session ready (not in `cloud`) → `_ServerReady`, else
  `ServerAway`. `_ServerReady`: `ServerConnection` across the top; two columns from 820 px (one below): the devices list
  (refreshed every 5 s; server, online, offline, removed; "N connected"; this device marked), remove (confirmed), "Add
  device" on the master → `PairingPanel` (closes when a new device appears); a side `Surface.over` split by rules:
  `LanAddress`, `LanBrowsers` on native devices (both from one `devices.browserCa` read), this device's code and CA
  fingerprint, sign out (`ClientService.signOut`), stop the server (confirmed, counts connected devices).
- `widgets/lan_address.dart` — `LanAddress`: the web address (`.local` name, the IP below), copied with a button; unframed.
- `widgets/lan_browsers.dart` — `LanBrowsers`: the browsers' root (`devices.browserCa`): SHA-256 and SHA-1 fingerprints,
  install on this computer (Windows, macOS) or save as `.crt`.
- `widgets/pairing_panel.dart` — `PairingPanel`: an open pairing's code (Bebas), QR and time left counted from
  `expires`; expired → "New code".
- `widgets/status_dot.dart` — `StatusDot`: filled when on, outlined when off; device rows and `ServerConnection`.
- `widgets/pairing_qr.dart` — `PairingQr`: the pairing QR painted from `package:qr`, always black on white. Also draws the authenticator app's QR (`modals/business/two_factor`).
- `widgets/server_connection.dart` — `ServerConnection`: a bordered strip for a session opened online (`HybridService.joined`),
  online or offline by choice (`StatusDot`), "work offline" / "work online" (reopens the cloud socket), and the owner's "join with your company online" while unlinked;
  for a session on the master alone, "the internet is back" with "sign in online" (`showOnlineSignIn`) while `HybridService.canGoOnline`.
  Online and linked, one line on the sync (`SyncService`, read every 30 s): last synced, failing, another server holds the
  branch (owner: "use this server", confirmed), unlinked (owner: "sync again"); nothing while it enrols.
- `widgets/server_away.dart` — `ServerAway`: online without the master's session: a paired device's "server isn't
  answering" + try again (`resume`, or the master password once); a computer with none, "create the server here" (the
  cloud company's owner only) → the master setup body with the account and `HybridService.companyFrom` → `adopt` →
  `resolve` → back to `/home/server`; an engine this computer can't run says so.
