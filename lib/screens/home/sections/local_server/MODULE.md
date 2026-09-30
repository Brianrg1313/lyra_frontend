# Module: local_server section

**Path** `lib/screens/home/sections/local_server`
**Role** The master's devices, inside the home (`HomeSection.server`, `/home/server`, area `local_server`): only on a
master's devices (`docs/plan-offline-lan.md` §4 admin screens, §5.3).
**Service** `LanService` (`lib/services/lan`).

## Files

- `_local_server.dart` — `LocalServerSection`: this device's code and CA fingerprint; the devices list (refreshed every
  5 s, online / server / removed), remove (confirmed), "Add device" on the master (the code to type and `PairingQr`);
  `LanBrowsers` on native devices; sign out (`ClientService.signOut`); stop the server (confirmed, counts connected
  devices).
- `widgets/lan_browsers.dart` — `LanBrowsers`: the browsers' root (`devices.browserCa`): SHA-256 and SHA-1 fingerprints,
  the web address, install on this computer (Windows, macOS) or save as `.crt`.
- `widgets/pairing_qr.dart` — `PairingQr`: the pairing QR painted from `package:qr`, always black on white.
