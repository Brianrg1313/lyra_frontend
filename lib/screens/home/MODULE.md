# Module: home

**Path** `lib/screens/home`
**Role** The authenticated shell. Every `/home/...` route renders this **one** page
(`shell: Home.shell`): switching sections updates the tree instead of stacking a page.

## Invariants

- `Home` takes nothing by constructor (the `Navigator` caches the shell page): read
  `Navis.currentKey` / `Navis.currentArgs`.
- Content is keyed by the active business (`KeyedSubtree(key: ValueKey(businessId))`): a switch
  **remounts** the section, so sections just load in `initState`.
- Sub-pages bound to an id of the previous business (`/home/inventory/:id`) use the
  `BusinessListener` mixin to navigate away.
- **Const-section trap**: `_screen` returns sections as `const`; a canonicalized const is skipped by
  `Element.updateChild`, so a tabbed section must listen to `Navis.currentKey` itself
  (`ValueListenableBuilder`, see `sections/finance/_finance.dart`).
- `HomeSection.needsBusiness` is enforced twice: side bar disables it, shell refuses to mount it
  (deep links). No business → `NoBusinessSection`.

## Files

- `_home.dart` — `Home extends PageBuilder`, `static const shell = "home"`. `initialized` opens the
  socket (`ConnectionService().open()`, idempotent) when authenticated. Listens to
  `Navis.currentKey` + `BusinessService.activeId`.
- `desktop/_body.dart` — `DesktopBody`: side bar + header + content.
- `desktop/side_bar/side_bar.dart` — `SideBar({section})`: groups from `HomeSection`, collapsible via `HomeService`.
- `desktop/side_bar/options.dart` — option list; disables unmet `needsBusiness`; builds the POS option by hand.
- `desktop/side_bar/option.dart` — `Option({icon, title, action, isExpanded, isActive})`.
- `desktop/side_bar/profile.dart` — `ProfileCard`. `desktop/side_bar/sign_out.dart` — `SignOut`.
- `header/_header.dart` — `HomeHeader`: search (`HomeService.searchQuery`, cleared on screen change), business selector, inbox.
- `header/business_selector.dart` — `BusinessSelector`: switches the active business, offers creation.
- `sections/_sections.dart` — **section registry**: `enum HomeSection` (`key path icon`; `dashboard
  business inventory services channels connections sales finance marketing report externalServices`),
  groups `.home` `.transactions` (sales, finance; POS closes it but is in no list) `.products`
  `.reports` `.connectionGroups`; `byKey`, `containing`, `isCurrent`, `title(context)`,
  `needsBusiness`, `build()`; `homeContent(currentKey, section, businessId)` (incl. sub-pages).
- `sections/section_tabs.dart` — `SectionTabs<T>({tabs, active, icon, title, onTab})`: tab bar used
  by business, finance and sales. **Reuse it for any new tabbed section.**
- `sections/business_listener.dart` — `mixin BusinessListener<T>`.
- `sections/no_business.dart` — `NoBusinessSection`.
- `sections/placeholder.dart` — `SectionPlaceholder`: `dashboard services marketing report externalServices`.
- `sections/section_message.dart` — `SectionMessage({icon, message, action?})`: full-section empty/error/loading. Use instead of ad-hoc centered columns.

## Sections with their own module

`sections/{business,inventory,channels,connections,sales,finance}/MODULE.md`.

## Adding a section

1. Value in `HomeSection` (key, path, icon) + a group list.
2. Title in `title(context)`, widget in `build()`.
3. `S` key in `lib/l10n/intl_en.arb`.
4. Its route is generated from `HomeSection.values`; only sub-pages go in `routes.dart`
   (`parents: ["<key>"]`, `shell: Home.shell`).
