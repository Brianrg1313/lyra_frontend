# Lyra — Agent Guide

Flutter app (`package:app`), desktop-first business console (Windows primary; web/mobile targets).
This file holds **global rules only**. Per-file inventories live in each module's `MODULE.md`;
read one only when you touch that module.

---

## 1. Core is the widget source — highest priority rule

`core` is a local path package (`E:/andromeda/frontend/packages/core`, its own git repo) that
owns the design system, navigation, api/socket clients, forms, modals, tables and charts.

**If `core` has it, use it.** Check the index below before writing any UI; if a symbol is not
there, read `E:/andromeda/frontend/packages/core/MODULE.md` (full signatures) before assuming
it does not exist.

Material/Cupertino is allowed **only** for layout/rendering primitives core does not wrap:
`Row` `Column` `Stack` `Expanded` `Flexible` `Padding` `SizedBox` `Align` `Center` `Wrap`
`ListView` `SingleChildScrollView` `GestureDetector` `MouseRegion` `Icon` `ClipRRect`
`Container` `AnimatedContainer`, transitions, `InheritedWidget`, `Theme.of`, `MediaQuery`.

Banned (never introduce new usages):

| Do not use | Use |
|---|---|
| `ElevatedButton` `TextButton` `OutlinedButton` `IconButton` | `Button` `MainButton` `FeedbackButton` `FocusableWidget` |
| `TextField` `TextFormField` `Form` | `Input` `SearchInput` `SelectInput` `CodeInput` + `InputController`/`FormController` |
| `DropdownButton` `PopupMenuButton` | `SelectInput` / `showSelectMenu` |
| `showDialog` `AlertDialog` `showModalBottomSheet` | `showModal` `showSideModal` `showAlertModal` |
| `Scaffold` `AppBar` `Card` `Divider` | `PageBuilder` `Skeleton` `Header` `Surface` `Separator` |
| `Text` | `TextSmall` `TextMedium` `TextLarge` |
| `SnackBar` `ScaffoldMessenger` | `FloatFlag` |
| `showMenu` `MenuAnchor` `ContextMenuController`, menus on `onSecondaryTap`/`onLongPress` | `ContextMenuRegion` (+ `ContextItem`/`ContextSeparator`/`ContextHeader`), `showContextMenu` |
| `DataTable` `Table` | `DataTableView` + `TableColumn`/`TableController`/`TableStyle` |
| `CircularProgressIndicator` | `Loading` (raw one only for pre-existing sized inline spinners) |
| `Image.network(url)` | `Image(image: mediaImage(url))` (`toolkit/lan_image.dart`: a master's files come over its channel) |
| initials circles, `DecorationImage` avatars, `NetworkImage` | `ProfilePicture(kind: ProfileKind.user/employee/business/customer)` |
| hardcoded colors | `ThemeColor.of(context).*` |
| hardcoded paddings/sizes | `AppSize.*` |

### Core index — symbol to import

`package:app/toolkit/toolkit.dart` re-exports **all of `core/core.dart` plus `S` (i18n)**. It is
the single import for screens; never import `package:core/core.dart` directly.

- **toolkit.dart** (= core.dart + S): `PageBuilder` `Skeleton` `Header` `FloatHeader`
  `Surface` (`.over/.line/.glass/.gradient`) `Separator` (`.horizontal/.vertical`)
  `TextSmall` `TextMedium` `TextLarge` `TextInter` `TextFont` `Loading` `AnimatedNumber`
  `FeedbackButton` `FocusableWidget` `ScrollableWidget` `HideKeyboard` `IsKeyboardVisible`
  `ColorPicker` `ColorPickerField` `ColorPickerController` `ProfilePicture` `ProfileKind` `DataTableView` `TableColumn`
  `TableController` `TableStyle` `ChartView` `ChartSeries` `ChartFormat` `StatTile`
  `Sparkline` `Navis` `ScreenRoute` `RouteAnimation` `ThemeColor` `SchemeColor` `AppSize`
  `AppController` `Responsive` `DeviceSelector` `CI` (icon font) `Str` `FloatFlag`
  `showModal` `showSideModal` `showAlertModal` `ModalHeader` `ModalSide` `AlertModal`
  `ContextMenuRegion` `ContextItem` `ContextSeparator` `ContextHeader` `showContextMenu`
- **`package:core/button.dart`**: `Button` `MainButton` `FeedbackButton`
- **`package:core/form.dart`**: `Input` `SearchInput` `SelectInput` `SelectOption` `CodeInput`
  `InputRow` `InputController` `FormController` `InputValidator` `InputType` `InputStatus`
  `InputError` `showSelectMenu` `showCheckMenu` `SelectOptionTile`
- **`package:core/images.dart`**: `ImageDynamic` (assets, theme-aware), `CacheImage` (network)
- **`package:core/types.dart`**: `ListenableMap`
- **`package:core/api.dart`**: `RestAPI` `ApiModel` `ApiMode` `Headers`
- **`package:core/socket.dart`**: `SocketAPI` `SocketStatus`
- **`package:core/starter.dart`**: `starter()` — called only by `main.dart`

### App-level shared widgets — check before building a new one

- `SectionTabs<T>` (`lib/screens/home/sections/_section/section_tabs.dart`) — tab bar of any tabbed section.
- `PageSwitcher` (`lib/screens/home/sections/_section/page_switcher.dart`) — animated swap of a section's sub-pages/tab bodies.
- `SectionMessage` (`lib/screens/home/sections/_section/section_message.dart`) — full-section empty/error/loading.
- `SectionFilterChip` `SectionMenuChip` (`lib/screens/home/sections/_section/filter_chip.dart`, `filter_menu_chip.dart`) — the controls of a filter bar.
- `SectionMoreButton` (`lib/screens/home/sections/_section/more_button.dart`) — "load more" under a paged table.
- `SettingsBlock` `SettingsRow` `SettingsTag`… (`lib/screens/modals/shared/settings/settings_block.dart`) — read-only panel rows.
- `BusinessListener` (`lib/screens/home/sections/_section/business_listener.dart`) — sub-page reacting to a business switch.
- `BadgeMark` `BadgeCorner` (`lib/screens/home/badges/badge_mark.dart`) — what a place has pending; `BadgeNotes` (`badge_notes.dart`) says it in words; places in `BadgePlace` (`lib/services/badges/badge_place.dart`).

---

## 2. Modules

**Do not scan a module's directory — read its `MODULE.md`.**

| Module | Path | Responsibility | Spec |
|---|---|---|---|
| core (external) | `E:/andromeda/frontend/packages/core` | Design system, navigation, api/socket, forms, modals, tables, charts. | `E:/andromeda/frontend/packages/core/MODULE.md` |
| toolkit | `lib/toolkit` | App wiring: api/socket instances, routes, themes, bootstrap hooks, barrel export. | `lib/toolkit/MODULE.md` |
| services | `lib/services` | State and backend access: `ChangeNotifier` services, models, request bodies. No widgets. | `lib/services/MODULE.md` |
| home | `lib/screens/home` | Main shell: side bar, header, section router. Every `/home/...` route renders this one page. | `lib/screens/home/MODULE.md` |
| business section | `lib/screens/home/sections/business` | Business page and its tabs (statistics, branches, clients, settings/profile). | `.../business/MODULE.md` |
| employees section | `lib/screens/home/sections/employees` | The company's people: the list always on the left; on the right one person's page (an index of their card's parts), each part on its own page (permissions included), and on one's own card the account's subsections. | `.../employees/MODULE.md` |
| inventory section | `lib/screens/home/sections/inventory` | Catalog tables (what is bought and counted), one at a time (selector in the bar): stock summary or spreadsheet (cells switch); templates when there is none. | `.../inventory/MODULE.md` |
| menu section | `lib/screens/home/sections/menu` | Made products' tables (dishes, combos), one at a time: a grid of cards, each a form with what it consumes. Cloud only. | `.../menu/MODULE.md` |
| supply chain section | `lib/screens/home/sections/supply_chain` | Products made of others: recipes (to order or by batch, the 86, batches, lost dishes, presentations), modifier groups, and the kitchen's reports (consumption, variance, cost per dish). Cloud only. | `.../supply_chain/MODULE.md` |
| channels section | `lib/screens/home/sections/channels` | AI channels: grid, edit page, form blocks shared with the create/detail panels. | `.../channels/MODULE.md` |
| knowledge section | `lib/screens/home/sections/knowledge` | Frequent questions Lyra looks up: the company's context per question (branch, products, dates), and the questions Lyra left waiting for one. Cloud only. | `.../knowledge/MODULE.md` |
| connections section | `lib/screens/home/sections/connections` | Third-party accounts: list and create/edit form. | `.../connections/MODULE.md` |
| messages section | `lib/screens/home/sections/messages` | Conversation desk (`/aries/v1`): inbox (1/3) and open chat (2/3), live via sockets. | `.../messages/MODULE.md` |
| deliveries section | `lib/screens/home/sections/deliveries` | Deliveries desk, below messages in the side bar: a map drawn by the self-hosted tile server (`/scorpius`) with the branches, the branch's deliveries board (cloud only: assign, schedule in a franja, move; the branch's schedule — franjas, week, closed days — in a side panel), where the company delivers drawn and edited on it (one shared map or one per branch); settings in a side panel. | `.../deliveries/MODULE.md` |
| sales section | `lib/screens/home/sections/sales` | Live sales board (sockets), two tabs: in process / done. | `.../sales/MODULE.md` |
| finance section | `lib/screens/home/sections/finance` | Company money: overview, payments, receivables, payment methods. | `.../finance/MODULE.md` |
| local_server section | `lib/screens/home/sections/local_server` | The master's devices (pair, remove, browsers' root, stop the server), only on a master's devices. | `.../local_server/MODULE.md` |
| modals | `lib/screens/modals` | Every dialog and side panel, grouped by the section that opens it. | `lib/screens/modals/MODULE.md` |
| auth | `lib/screens/authentication` | One email-only entry (`/login`) that branches to sign in (password, code) or sign up (code). | `lib/screens/authentication/MODULE.md` |
| pre_start | `lib/screens/pre_start` | Pages before the home, one per pending `/init` task (`welcome`: no company or a pending invitation). | `lib/screens/pre_start/MODULE.md` |
| pos | `lib/screens/pos` | Standalone point-of-sale mode (`/pos`), three panels, no home shell. | `lib/screens/pos/MODULE.md` |
| i18n | `lib/l10n`, `lib/generated` | `intl_en.arb` and generated `S`. All user-facing strings. | `lib/l10n/MODULE.md` |
| tests | `test` | Widget and unit tests, flat, one file per behaviour. | `test/MODULE.md` |
| baileys_server | `baileys_server` | Node.js sidecar: Baileys (unofficial WhatsApp Web), local control API, outbound relay to the backend. Own toolchain. | `baileys_server/MODULE.md` |
| lyra_protocol (external) | `E:/andromeda/frontend/packages/lyra_protocol` | LAN protocol shared with the engine: op catalogue, frames, error codes, handshake. Pure Dart, own repo. | `E:/andromeda/frontend/packages/lyra_protocol/MODULE.md` |
| lyra_node (external) | `E:/andromeda/frontend/packages/lyra_node` | The master's engine (offline/LAN mode): encrypted store, keys, oplog, audit, accounts, process, LAN server (TLS, pairing, RPC). Pure Dart, own repo; the app only runs its executable. | `E:/andromeda/frontend/packages/lyra_node/MODULE.md` |

No spec: `lib/main.dart` (calls `starter`), `lib/screens/_splash/_splash.dart` (centered
`Loading` while `initialValidator` resolves the first route).

---

## 3. Conventions

**Language — English, always**: identifiers, `///` docs, comments, `MODULE.md`, test names,
commit messages, assertions, logs. Never two languages in one file. Many `test/` files and most
`///` docs in `core` still carry Spanish: translate what you touch, in the same change.
User-facing copy is the only non-English text, and it lives in `lib/l10n/intl_en.arb` under `S`.

**Naming and layout**
- A folder is a unit; its entry file is `_<name>.dart` (`_home.dart`, `_channels.dart`),
  siblings are its parts. Sub-state in `state/`, sub-widgets in `widgets/`, sub-sections in `blocks/`.
- Screens extend `PageBuilder`. Reusable pieces are `StatelessWidget`/`StatefulWidget`.
- Services are `ChangeNotifier`s; models are plain classes with a `fromJson`-style factory;
  write bodies live in `*_request.dart`.

**Imports** — banners `// PACKAGES`, `// SERVICES`, `// WIDGETS`. App-internal imports use
`package:app/...`; same-folder ones use `'./x.dart'`.

**State** — `provider` only. App-wide services are registered in
`lib/toolkit/settings/initial_builder.dart`; flow- or section-scoped ones are created and
provided by their screen. Load states: `enum XStatus { idle, loading, ready, empty, error }`.

**Backend access** — a service reads and writes through its domain's source
(`lib/services/<domain>/sources/`: `XSource` returns models, `XCloudSource` holds the REST
calls), resolved by `Sources` in `lib/toolkit/deployment.dart`. **Never `api.*` from a service.**
Only cloud-only services (chats, channels, connections, maps, Baileys, places, money AI, sign up,
badges, the person's own account, shipments, opening hours, kitchen) call `api` directly. Screens never know the deployment mode (`docs/plan-offline-lan.md`).

**Deployment modes** — every area of `docs/app-areas.json` declares `modes`, and
`CapabilityService.modes` carries the same entry (`test/capabilities_test.dart` enforces it). A new
feature says in the same change whether it is `cloud` only or `local` too.

**Local ops** — a new op of the LAN protocol goes into `docs/offline/protocol-v1.md`, `lyra_protocol`
(`Ops`), an engine handler with its authorization rule, and a contract test, in the same change
(`test/protocol_catalogue_test.dart` keeps the doc and `Ops` equal). Sensitive fields (a person's money,
identity documents, bank data) are **sealed by default** in the engine (plan §6.3). Nothing is ever
served or accepted without TLS and a verified peer, debug builds and tests included: no plaintext
listener, no "accept any certificate" outside the `/pair` step that SPAKE2 then authenticates
(`protocol-v1.md` §3).

**Sync** — a `local` feature whose data also lives in the cloud syncs by declaring one entity in the
same change: its row in `docs/task-edge-sync-backend.md` §11, an `EdgeEntity` in `lyra_node`, and one
in the backend's `lib/models/edge/entities/` (plan §9.8). Ids, stamps, conflicts and the feed are the
sync's; never sync a section by hand.

**Navigation** — `Navis`, never `Navigator.pushNamed`:
`Navis.push/pop/navigate/pushAndClearStack/back/forward`; active screen `Navis.currentKey`,
URL args `Navis.currentArgs`. Routes live in `lib/toolkit/settings/routes.dart`; home
sections share `shell: Home.shell`.

**Theming** — `ThemeColor.of(context)`: `primary accent text subtitle background modal line
lineOver surface surfaceOver surfaceFeedback navBar input keyboard shadow button icon table
snackBar chart`. Sizes from `AppSize`: `action button picture corner gap spaceXS spaceS spaceM
padding spaceL text flag`, plus `AppSize.cornerInset(gap, [base])`.

**Errors** — `FloatFlag.showFromError(e)` for api failures (the api layer normalizes to
`{message, action}`); `FloatFlag.of(context).error/.alert/.notification/.message` otherwise.

**Strings** — never hardcode user-facing text. `S.of(context).key` (`S.current.key` outside
the tree). Add the key to `lib/l10n/intl_en.arb` first; see the i18n spec.

**Comments** — explain *why*, not *what*. Intent (trade-offs, backend contracts) goes in `///`
on the declaration. Keep that density; no restating comments.

---

## 4. Commands

```
flutter analyze                  # lint gate (flutter_lints)
flutter test                     # all tests
flutter test test/<file>.dart    # one
flutter run -d windows           # primary target
flutter pub get                  # after touching pubspec.yaml
```

Never edit `lib/generated/**` by hand. It is regenerated from `lib/l10n/intl_en.arb` by the
Flutter Intl IDE plugin on save, or `dart pub global run intl_utils:generate` (see the i18n spec).

**Quality gate: `flutter analyze` must report "No issues found!"** — zero, not "no new issues":
a noisy baseline once hid three broken test files through a refactor.
- `lib/generated/**` is excluded in `analysis_options.yaml` (regeneration undoes any fix there).
  Never `// ignore:` generated code.
- `test/` is analyzed like `lib/`. A test that no longer compiles only shows up in
  `flutter test` as a load failure — easy to miss.
- Last resort: a single-line `// ignore:` with a reason. Never widen the exclude list.

`flutter test` has a few known pre-existing failures, listed in `test/MODULE.md`. Any other
failure is yours.

---

## 5. Doc maintenance protocol

- Add, remove, rename or repurpose a file → update its module's `MODULE.md` in the same change.
  New module → create its `MODULE.md` and add a row to section 2.
- A `MODULE.md` answers **"where do I edit this"**: one line per file, `path` — what it is.
  Facts only, English, no prose.
- The **why** lives in `///` on the declaration, not in `MODULE.md`. A module doc carries an
  invariant only when breaking it is a bug no single file reveals (cross-file traps, backend
  contracts shared by several files) — one bullet each.
- State each fact in one doc; other docs point to it instead of repeating it.
