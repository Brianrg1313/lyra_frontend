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
  - `useBusiness(String? id)` — sets the active business on `api`, `assets`, `aries`, `scorpius`, `sockets` (`business_id`
    header). Called only by `BusinessService`, which then calls `ConnectionService().rebind()`:
    the socket picks it up only in a new handshake.
  - Both extend private `_SessionApi` (token from `DatabaseService.fromSecure` in `preRequest`).
  - `useCookieSession` — web-only `HttpOnly` cookie session, off unless `--dart-define=LYRA_COOKIE_SESSION=true`
    (backend contract: `docs/task-cookie-session-backend.md`). `openSession(token)` — stores the token a sign in answered (no-op in cookie mode).
  - `onSessionRejected` — hook fired by `_SessionApi` on a `401` with `action: "login"`; set by `ClientService` (ends the session).
- `deployment.dart` — `DeploymentMode` (`cloud`, `local`, `hybrid`), `DeploymentRole`, `Deployment.mode`/`.role`,
  `lanEnabled` (native build with `--dart-define=LYRA_LAN=true`), `chosen`, `restore` (from preferences, in `preCall`),
  `choose` (persists), `use` (tests); `Sources` (one getter per domain: the cloud source, `UnsupportedError` in any other
  mode until phase 4), `UnreadableAnswer` (an answer its model can't read).
- `lan.dart` — `LanClient` (one `/rpc` socket to the master: hello, sign in + `session.bind`, silent refresh, failures as
  `{message, action, code}` maps), `LanUnreachable`, `lanAppVersion` (= pubspec), `lanPlatform`, `lanSupported`,
  `discoverMasters`, `openPairingSocket`, `lanFailure`.
- `lan_io.dart` / `lan_web.dart` — the transport behind `lan.dart` (conditional import): native mutual TLS pinned to the
  CA (`403` → `device_revoked`) and mDNS; web is a stub until the browser client exists.
- `lan_found.dart` — `LanFound` (a master mDNS found), `LanPairingSocket`.
- `sockets.dart` — `sockets` (`SocketAPI`), same host/token as `api`; `business_id` in headers **and**
  `auth` (web cannot send custom headers; `auth` is re-read on reconnect). Lifecycle: `ConnectionService`.
- `settings/routes.dart` — the route table. Home sections, business/finance/sales tabs are generated
  from their enums; all `/home/...` share `shell: Home.shell`. Fixed segments
  (`/home/connections/new`) go **before** their `:id` sibling. `/pos` is standalone.
  Every route uses `RouteAnimation.fadeThrough` (`_animation`); a new one must too.
- `settings/precall.dart` — `preCall()`: Hive (`DatabaseService.initialize`), `HomeService.preload`, `PreferencesService.preload`, `Deployment.restore`,
  Windows window (1024x720, hidden title bar, `window_manager`).
- `settings/initial_builder.dart` — `initialBuilder(app)`: root `MultiProvider` + the
  pre-tree instances `clientService`, `businessService`, `lanService`. App-wide services only.
- `settings/initial_validator.dart` — `initialValidator()`: a LAN build with no mode chosen → `/deployment`; `local` → `/lan`; otherwise `clientService.resolve()` (session failure or pending task), then a pending deep link, else `PreferencesService().homePath` (last home page, or `/home`).
- `settings/translations.dart` — bridges core's strings (`hide_keyboard`, `connectionError`) to `S`.
- `theme/dark.dart` / `theme/light.dart` — `darkScheme` / `lightScheme` (`SchemeColor`), accent `0xfffb8e00`.

## Rules

- New screen → `ScreenRoute` in `settings/routes.dart` (home sections: a `HomeSection` value instead).
- New app-wide service → `settings/initial_builder.dart`; `.value` when its lifecycle must not follow the tree.
- Never call `http` directly; use `api` / `assets`, and those only from a `*_cloud_source.dart` or a cloud-only service.
