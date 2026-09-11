# Lyra — Agent Guide

Flutter app (`package:app`), desktop-first business console (Windows/web/mobile targets).
This file holds **global rules only**. File-by-file inventories live in each module's
`MODULE.md`. Read a module doc only when you touch that module.

---

## 1. Core is the widget source — highest priority rule

`core` is a local path package (`E:/andromeda/frontend/packages/core`) that owns the
design system, navigation, api/socket clients, forms, modals and tables.

**Rule: if `core` has it, use it. Never reach for a Material/Cupertino component that
`core` already wraps.** Check the index below before writing any UI. If it is not there,
open `E:/andromeda/frontend/packages/core/MODULE.md` (full signatures) before assuming
it does not exist.

Material/Cupertino is allowed **only** for layout & rendering primitives core does not
wrap: `Row` `Column` `Stack` `Expanded` `Flexible` `Padding` `SizedBox` `Align` `Center`
`Wrap` `ListView` `SingleChildScrollView` `GestureDetector` `MouseRegion` `Icon`
`ClipRRect` `Container` `AnimatedContainer` transitions, `InheritedWidget`, `Theme.of`,
`MediaQuery`.

Banned in favour of core (never introduce new usages):

| Do not use | Use |
|---|---|
| `ElevatedButton` `TextButton` `OutlinedButton` `IconButton` | `Button` `MainButton` `FeedbackButton` `FocusableWidget` |
| `TextField` `TextFormField` `Form` | `Input` `SearchInput` `SelectInput` `CodeInput` + `InputController`/`FormController` |
| `DropdownButton` `PopupMenuButton` | `SelectInput` / `showSelectMenu` |
| `showDialog` `AlertDialog` `showModalBottomSheet` | `showModal` `showSideModal` `showAlertModal` |
| `Scaffold` `AppBar` `Card` `Divider` | `PageBuilder` `Skeleton` `Header` `Surface` `Separator` |
| `Text` | `TextSmall` `TextMedium` `TextLarge` |
| `SnackBar` `ScaffoldMessenger` | `FloatFlag` |
| `DataTable` `Table` | `DataTableView` + `TableColumn`/`TableController`/`TableStyle` |
| `CircularProgressIndicator` | `Loading` (raw one only for pre-existing sized inline spinners) |
| hardcoded colors | `ThemeColor.of(context).*` |
| hardcoded paddings/sizes | `AppSize.*` |

### Core index — symbol to import

`package:app/toolkit/toolkit.dart` re-exports **all of `core/core.dart` plus `S` (i18n)**.
It is the canonical single import for screens; use it instead of `package:core/core.dart`.

- **toolkit.dart** (= core.dart + S): `PageBuilder` `Skeleton` `Header` `FloatHeader`
  `Surface` (`.over/.line/.glass/.gradient`) `Separator` (`.horizontal/.vertical`)
  `TextSmall` `TextMedium` `TextLarge` `TextFont` `Loading` `AnimatedNumber`
  `FeedbackButton` `FocusableWidget` `ScrollableWidget` `HideKeyboard`
  `IsKeyboardVisible` `ColorPicker` `ColorPickerField` `ColorPickerController`
  `DataTableView` `TableColumn` `TableController` `TableStyle` `Navis` `ScreenRoute`
  `RouteAnimation` `ThemeColor` `SchemeColor` `AppSize` `AppController` `Responsive`
  `DeviceSelector` `CI` (icon font) `Str` `FloatFlag` `showModal` `showSideModal`
  `showAlertModal` `ModalHeader` `ModalSide` `AlertModal`
- **`package:core/button.dart`**: `Button` `MainButton` `FeedbackButton`
- **`package:core/form.dart`**: `Input` `SearchInput` `SelectInput` `SelectOption`
  `CodeInput` `InputRow` `InputController` `FormController` `InputValidator`
  `InputType` `InputStatus` `InputError` `showSelectMenu` `SelectOptionTile`
- **`package:core/images.dart`**: `ImageDynamic` (assets, theme-aware), `CacheImage` (network)
- **`package:core/types.dart`**: `ListenableMap`
- **`package:core/api.dart`**: `RestAPI` `ApiModel` `ApiMode` `Headers`
- **`package:core/socket.dart`**: `SocketAPI` `SocketStatus`
- **`package:core/starter.dart`**: `starter()` — app bootstrap, called only by `main.dart`

---

## 2. Modules

Each row is a module: what it is and where its spec lives. **Do not scan a module's
directory — read its `MODULE.md`.**

| Module | Path | Responsibility | Spec |
|---|---|---|---|
| core (external) | `E:/andromeda/frontend/packages/core` | Design system, navigation, api/socket, forms, modals, tables. Source of all widgets. | `E:/andromeda/frontend/packages/core/MODULE.md` |
| toolkit | `lib/toolkit` | App wiring: api/socket instances, routes, themes, bootstrap hooks, barrel export. | `lib/toolkit/MODULE.md` |
| services | `lib/services` | State and backend access. `ChangeNotifier` services plus their models/requests. No widgets. | `lib/services/MODULE.md` |
| home | `lib/screens/home` | Main shell: side bar, header, section router. Every `/home/...` route renders this one page. | `lib/screens/home/MODULE.md` |
| business section | `lib/screens/home/sections/business` | Business page and its tabs (settings/profile, employees, branches, clients, statistics). | `.../business/MODULE.md` |
| inventory section | `lib/screens/home/sections/inventory` | Product tables: list + stock summary, and the spreadsheet view of one table. | `.../inventory/MODULE.md` |
| channels section | `lib/screens/home/sections/channels` | AI channels: list, conversations, create/edit form. | `.../channels/MODULE.md` |
| connections section | `lib/screens/home/sections/connections` | Third-party accounts: list and create/edit form. | `.../connections/MODULE.md` |
| sales section | `lib/screens/home/sections/sales` | Every sale in flight and every one finished, live over sockets: two lists split by whether the money arrived and the goods left. | `.../sales/MODULE.md` |
| finance section | `lib/screens/home/sections/finance` | The company money: overview, payment history, receivables, payment methods. | `.../finance/MODULE.md` |
| modals | `lib/screens/modals` | Every dialog and side panel in the app, grouped by the section that opens it. | `lib/screens/modals/MODULE.md` |
| auth | `lib/screens/login`, `lib/screens/sign_up` | Sign in (+ email code step) and sign up (+ verification step). | `lib/screens/login/MODULE.md` |
| pos | `lib/screens/pos` | Standalone point-of-sale mode (`/pos`), three panels, no home shell. | `lib/screens/pos/MODULE.md` |
| i18n | `lib/l10n`, `lib/generated` | `intl_en.arb` and generated `S`. All user-facing strings. | `lib/l10n/MODULE.md` |
| tests | `test` | Widget and unit tests, flat, one file per behaviour. | `test/MODULE.md` |
| baileys_server | `baileys_server` | Standalone Node.js sidecar: Baileys (unofficial WhatsApp Web) in front, a local control API for the desktop app, an outbound WebSocket relay to the backend. Not a Flutter module — own toolchain. | `baileys_server/MODULE.md` |

Single file, no spec: `lib/main.dart` (calls `starter`), `lib/screens/_splash/_splash.dart`
(centered `Loading` while `initialValidator` resolves the first route).

---

## 3. Conventions

**Language — English, always.** Identifiers, `///` docs, inline comments, `MODULE.md`
files, test names, commit messages, assertion strings and log text. No exceptions, and
never two languages in one file. Parts of the repo (many `test/` files, most `///` docs
in the `core` package) still carry Spanish from before this rule: translate what you
touch, in the same change. The only text that is not English is user-facing copy, which
never lives in code anyway — it lives in `lib/l10n/intl_en.arb` under `S`.

**Naming and layout**
- A folder is a unit. Its entry file is `_<name>.dart` (e.g. `_home.dart`, `_channels.dart`);
  siblings are its parts. Sub-state goes in `state/`, sub-widgets in `widgets/`,
  sub-sections in `blocks/`.
- Screens extend `PageBuilder`. Reusable pieces are `StatelessWidget`/`StatefulWidget`.
- Services are `ChangeNotifier`s; models are plain classes with a `fromJson`-style
  factory; write bodies live in `*_request.dart`.

**Imports** — group with the comment banners already used in the repo:
`// PACKAGES`, `// SERVICES`, `// WIDGETS`. App-internal imports use `package:app/...`;
same-folder ones use `'./x.dart'`.

**State**
- `provider` only. App-wide services registered in `lib/toolkit/settings/initial_builder.dart`;
  flow-scoped ones (`SignInService`, `SignUpService`) provided by their own screen.
- Load states are an `enum XStatus { idle, loading, ready, empty, error }` on the service.

**Navigation** — `Navis`, never `Navigator.pushNamed`.
`Navis.push/pop/navigate/pushAndClearStack/back/forward`; read the active screen with
`Navis.currentKey` and URL args with `Navis.currentArgs`. Routes are declared in
`lib/toolkit/settings/routes.dart`; home sections share `shell: Home.shell`.

**Theming** — `ThemeColor.of(context)` gives `primary accent text subtitle background
modal line lineOver surface surfaceOver surfaceFeedback navBar input keyboard shadow
button icon table snackBar`. Sizes from `AppSize`: `action button picture corner gap
spaceXS spaceS spaceM padding spaceL text flag`, plus `AppSize.cornerInset(gap, [base])`.

**Errors** — `FloatFlag.showFromError(e)` for api failures; `FloatFlag.of(context)
.error/.alert/.notification/.message` otherwise. The api layer already normalizes
exceptions into `{message, action}`.

**Strings** — never hardcode user-facing text. `S.of(context).key` (or `S.current.key`
outside the tree). Add the key to `lib/l10n/intl_en.arb` first; see the i18n spec.

**Comments** — explain *why*, not *what*. The codebase documents intent
(trade-offs, backend contracts) in `///` on the declaration. Keep that density; do not
add restating comments.

---

## 4. Commands

```
flutter analyze                  # lint gate (flutter_lints)
flutter test                     # all tests
flutter test test/<file>.dart    # one
flutter run -d windows           # primary target
flutter pub get                  # after touching pubspec.yaml
```

Never edit `lib/generated/**` by hand — it is Flutter Intl output, regenerated by the
IDE plugin when `lib/l10n/intl_en.arb` is saved (there is no CLI generator in this repo;
see the i18n spec).

**Quality gate: `flutter analyze` must stay at "No issues found!".** Not "no new issues" —
zero. A non-empty baseline is how three test files sat broken and silent through a
folder refactor: nobody could see the new errors among the old noise.

- Generated code is excluded in `analysis_options.yaml` (`lib/generated/**`), because a
  lint there is rewritten back on the next regeneration and cannot be fixed in place.
  Exclude generated output; never sprinkle `// ignore:` into it.
- `test/` is analyzed like `lib/`. A test that no longer compiles is a broken test, not
  a skipped one — `flutter test` reports it as a load failure, which is easy to scroll past.
- If a fix is genuinely not possible, an `// ignore:` on the single line with a reason is
  the last resort. Do not widen the exclude list to silence real code.

---

## 5. Doc maintenance protocol

When you add, remove, rename or repurpose a file, update that module's `MODULE.md` in
the same change. When you add a whole module, create its `MODULE.md` and add a row to
the table in section 2. Keep entries to one line per file: `path` — what it is.
Facts only, English, no prose. These docs are written for agents: optimize for being
read once and answering "where do I edit this" without opening the directory.
