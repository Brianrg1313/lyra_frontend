# Module: toolkit

**Path** `lib/toolkit`
**Role** App wiring: what `main.dart` needs to boot and what the app imports to reach core, the
backend, routes and theme. No UI.

## Files

- `toolkit.dart` — app barrel: re-exports `package:core/core.dart` + `S`. **Screens import this.**
- `api.dart` — REST clients and the business header:
  - `api` — main backend (`lyra`, port 80). `assets` — media backend (`cetus`, port 81, `ApiMode.assets`).
    `aries` — conversation desk (`aries`, port 80). `scorpius` — maps (`scorpius`, port 80; tile routes public).
  - `mapTilesUrl(tileset, style)` — absolute `{z}/{x}/{y}{r}.png` template of a tileset's server-drawn tiles (`/scorpius/v1/raster`).
  - `apiOrigin` — scheme+host+port, to absolutize relative media paths.
  - `cloudReachable()` — whether the backend answers at all (any status; a failed connection or 5 s is no); the sign in asks it first.
  - `useBusiness(String? id)` — sets the active business on `api`, `assets`, `aries`, `scorpius`, `sockets` (`business_id`
    header). Called only by `BusinessService`, which then calls `ConnectionService().rebind()`:
    the socket picks it up only in a new handshake.
  - Both extend private `_SessionApi` (token from `DatabaseService.fromSecure` in `preRequest`).
  - `useCookieSession` — web-only `HttpOnly` cookie session, off unless `--dart-define=LYRA_COOKIE_SESSION=true`
    (backend contract: `docs/task-cookie-session-backend.md`). `openSession(token)` — stores the token a sign in answered (no-op in cookie mode).
  - `onSessionRejected` — hook fired by `_SessionApi` on a `401` with `action: "login"`; set by `ClientService` (ends the session).
- `deployment.dart` — `DeploymentMode` (`cloud`, `local`, `hybrid`), `DeploymentRole`, `Deployment.mode`/`.role`/`.paired` (the pairing's role, whichever session),
  `lanEnabled` (every native install, or the page a master serves; no build flag), `restore`
  (in `preCall`: a stored `LanDevice` is LAN mode with its role unless a cloud token is stored, anything else cloud; never chosen), `attach` (set up or
  paired), `detach` (left the LAN), `online`/`offline` (the sign in page's network: the cloud's sources, or the paired master's; `offline` is also "work offline"), `hybrid` (signed in online and to the master, `HybridService`), `use` (tests); `Sources` (one getter per domain: the cloud source, or in `local`/`hybrid` its LAN source over
  `lanService` — session, business, inventory and stock so far — and `UnsupportedError` for a domain whose release hasn't come), `UnreadableAnswer` (an answer its model can't read).
- `lan.dart` — `LanClient` (one `/rpc` socket to the master: hello, a browser's `device.prove`, sign in (or `activate`) + `session.bind`,
  silent refresh, failures as `{message, action, code}` maps), `LanUnreachable`, `lanAppVersion` (= pubspec),
  `lanPlatform`, `lanDeviceName` (the default name a device pairs with), `lanSupported` (web: the `<meta name="lyra-master">` a master writes into its page), `lanServingMaster` (web: the page's origin, if a master's), `lanCanScan` (Android, iOS),
  `discoverMasters`, `openPairingSocket`, `newDeviceKey`, `signDeviceProof`, `forgetDeviceKey`, `canInstallBrowserCa`,
  `installBrowserCa`, `saveBrowserCa`, `lanFailure`; `download` / `upload` (`/f`, the session's token, refreshed once),
  `LanFiles` (the seam).
- `lan_io.dart` — native transport: mutual TLS pinned to the CA (`403` → `device_revoked`, and `/f`), mDNS, PEM keys, the
  browsers' root into the user trust store (Windows `certutil`, macOS `security`).
- `lan_web.dart` — browser transport: WebSockets to the page's origin, a non-extractable WebCrypto key in IndexedDB,
  `fetch` for `/f`.
- `lan_file.dart` — `LanFileResponse`, `LanFileUnreachable` (both transports' `fileRequest`).
- `lan_image.dart` — `mediaImage(url)` (what screens draw an image address with), `LanFileImage` (a master's file over
  its channel, cached by id and size; `address`, `parse`).
- `lan_key.dart` — `LanDeviceKey` (a pairing key: signs, PEM or none, `keep`), `PemDeviceKey`.
- `lan_found.dart` — `LanFound` (a master mDNS found), `LanPairingSocket`.
- `save_file.dart` — `saveFile` (bytes to a file the person keeps: a save dialog natively, a download in a browser).
- `sockets.dart` — `sockets` (`SocketAPI`), same host/token as `api`; `business_id` in headers **and**
  `auth` (web cannot send custom headers; `auth` is re-read on reconnect). Lifecycle: `ConnectionService`.
  Also `presenceSocket`: the backend's `/presence` namespace, no token (`tokenName: "Presence"`), reconnects within 2 s.
- `settings/routes.dart` — the route table. Home sections, business/finance/sales tabs are generated
  from their enums; all `/home/...` share `shell: Home.shell`. Fixed segments
  (`/home/connections/new`) go **before** their `:id` sibling. `/pos` is standalone.
  Every route uses `RouteAnimation.fadeThrough` (`_animation`); a new one must too.
- `settings/precall.dart` — `preCall()`: Hive (`DatabaseService.initialize`), `HomeService.preload`, `PreferencesService.preload`, `Deployment.restore`,
  Windows window (1024x720, hidden title bar, `window_manager`).
- `settings/initial_builder.dart` — `initialBuilder(app)`: root `MultiProvider` + the
  pre-tree instances `clientService`, `businessService`, `lanService`, `hybridService`. App-wide services only.
- `settings/initial_validator.dart` — `initialValidator()`: `local` → `/lan`; a browser on a master's page not paired yet → `/deployment/pair`; a paired device with a cloud session → `hybridService.resume()` (`hybrid` when its master keeps the session; else the master's engine started and the cloud alone); otherwise `clientService.resolve()` (session failure or pending task), then a pending deep link, else `PreferencesService().homePath` (last home page, or `/home`).
- `settings/translations.dart` — bridges core's strings (`hide_keyboard`, `connectionError`) to `S`.
- `theme/dark.dart` / `theme/light.dart` — `darkScheme` / `lightScheme` (`SchemeColor`), accent `0xfffb8e00`.

## Rules

- New screen → `ScreenRoute` in `settings/routes.dart` (home sections: a `HomeSection` value instead).
- New app-wide service → `settings/initial_builder.dart`; `.value` when its lifecycle must not follow the tree.
- Never call `http` directly; use `api` / `assets`, and those only from a `*_cloud_source.dart` or a cloud-only service.
