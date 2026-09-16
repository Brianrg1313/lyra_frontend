# Module: toolkit

**Path** `lib/toolkit`
**Role** App wiring: what `main.dart` needs to boot and what the app imports to reach core, the
backend, routes and theme. No UI.

## Files

- `toolkit.dart` — app barrel: re-exports `package:core/core.dart` + `S`. **Screens import this.**
- `api.dart` — REST clients and the business header:
  - `api` — main backend (`lyra`, port 80). `assets` — media backend (`cetus`, port 81, `ApiMode.assets`).
  - `apiOrigin` — scheme+host+port, to absolutize relative media paths.
  - `useBusiness(String? id)` — sets the active business on `api`, `assets`, `sockets` (`business_id`
    header). Called only by `BusinessService`, which then calls `ConnectionService().rebind()`:
    the socket picks it up only in a new handshake.
  - Both extend private `_SessionApi` (token from `DatabaseService.fromSecure` in `preRequest`).
- `sockets.dart` — `sockets` (`SocketAPI`), same host/token as `api`; `business_id` in headers **and**
  `auth` (web cannot send custom headers; `auth` is re-read on reconnect). Lifecycle: `ConnectionService`.
- `settings/routes.dart` — the route table. Home sections, business/finance/sales tabs are generated
  from their enums; all `/home/...` share `shell: Home.shell`. Fixed segments
  (`/home/connections/new`) go **before** their `:id` sibling. `/pos` is standalone.
- `settings/precall.dart` — `preCall()`: Hive (`DatabaseService.initialize`), `HomeService.preload`,
  Windows window (1024x720, hidden title bar, `window_manager`).
- `settings/initial_builder.dart` — `initialBuilder(app)`: root `MultiProvider` + the two
  pre-tree instances `clientService`, `businessService`. App-wide services only.
- `settings/initial_validator.dart` — `initialValidator()`: `clientService.resolve()`, then a pending deep link, else `/home`.
- `settings/translations.dart` — bridges core's strings (`hide_keyboard`, `connectionError`) to `S`.
- `theme/dark.dart` / `theme/light.dart` — `darkScheme` / `lightScheme` (`SchemeColor`), accent `0xfffb8e00`.

## Rules

- New screen → `ScreenRoute` in `settings/routes.dart` (home sections: a `HomeSection` value instead).
- New app-wide service → `settings/initial_builder.dart`; `.value` when its lifecycle must not follow the tree.
- Never call `http` directly; use `api` / `assets`.
