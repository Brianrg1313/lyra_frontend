# Module: toolkit

**Path** `lib/toolkit`
**Role** App wiring. Everything `main.dart` needs to boot and everything the rest of the
app imports to reach core, the backend, the routes and the theme. No UI here.

## Files

- `toolkit.dart` — the canonical app barrel: re-exports `package:core/core.dart` and
  `S` (i18n). **Screens import this, not `package:core/core.dart`.**
- `api.dart` — the two REST clients and the business header.
  - `api` — main backend (`lyra`, port 80).
  - `assets` — media backend (`cetus`, port 81, `ApiMode.assets`).
  - `apiOrigin` — scheme+host+port, to absolutize relative media paths from the backend.
  - `useBusiness(String? id)` — sets the active business on `api`, `assets` and `sockets`;
    it travels as the `business_id` header on every request. Called only by `BusinessService`.
  - Both extend a private `_SessionApi` that restores the token from secure storage
    (`DatabaseService.fromSecure`) in `preRequest`.
- `sockets.dart` — `sockets`, the real-time client (`SocketAPI`). Same host/token as `api`;
  `business_id` travels in both headers and `auth` (web cannot send custom headers, and
  `auth` is re-read on every reconnect). Lifecycle is owned by `ConnectionService`.
- `settings/routes.dart` — the whole route table (`List<ScreenRoute>`). Home sections are
  generated from `HomeSection.values` and business tabs from `BusinessTab.values`; all of
  them share `shell: Home.shell`. Fixed segments (`/home/channels/new`) are declared
  **before** their `:id` sibling. `/pos` is standalone (no shell, no parents).
- `settings/precall.dart` — `preCall()`: opens Hive (`DatabaseService.initialize`),
  preloads the home box (`HomeService.preload`), and configures the Windows window
  (1024x720, hidden title bar) via `window_manager`.
- `settings/initial_builder.dart` — `initialBuilder(app)`: the `MultiProvider` at the app
  root. Also holds the two instances that must exist before the tree does:
  `clientService` and `businessService`. Services whose state must survive navigation go
  here; flow-scoped ones do not.
- `settings/initial_validator.dart` — `initialValidator()`: resolves the session
  (`clientService.resolve()`), then a pending deep link, else `/home`.
- `settings/translations.dart` — `translations`: bridges core's own strings
  (`hide_keyboard`, `connectionError`) to `S`.
- `theme/dark.dart` / `theme/light.dart` — `darkScheme` / `lightScheme`
  (`SchemeColor.dark/.light` with `primary` + `accent`). Accent is `0xfffb8e00`.

## Rules

- Adding a screen = add its `ScreenRoute` in `settings/routes.dart`. A home section
  instead gets a value in `HomeSection` (see the home module) and is generated from there.
- Adding an app-wide service = register it in `settings/initial_builder.dart`. Use
  `.value` when the instance's lifecycle must not be tied to the tree.
- Never talk to `http` directly; go through `api` / `assets`.
