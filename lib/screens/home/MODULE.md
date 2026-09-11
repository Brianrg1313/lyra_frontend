# Module: home

**Path** `lib/screens/home`
**Role** The authenticated shell. Every `/home/...` route renders this **one** page
(`shell: Home.shell`): switching sections updates the tree instead of stacking a page,
so the side bar keeps its state.

## Key invariants

- `Home` receives nothing by constructor. The `Navigator` caches the shell page, so the
  active screen is read from `Navis.currentKey` and URL args from `Navis.currentArgs`.
- The content is keyed by the active business id (`KeyedSubtree(key: ValueKey(businessId))`).
  Changing business **remounts** the section, which is what makes every section reload in
  its `initState` without subscribing to the business itself.
- Sub-pages bound to an id of the previous business (`/home/inventory/:id`) cannot be
  remounted; they use the `BusinessListener` mixin to navigate away instead.
- A section whose content depends on `Navis.currentKey` (a tabbed one) must listen to it
  itself: `_screen` returns those sections as `const`, and a canonicalized `const` widget
  is skipped by `Element.updateChild` on identity, so the shell's rebuild does not reach
  it. See `sections/finance/_finance.dart`.
- `HomeSection.needsBusiness` is enforced twice: the side bar disables the option, and
  the shell refuses to mount it (a section is a URL and is reachable by deep link).
  Without a business, `NoBusinessSection` offers sign-up.

## Files

- `_home.dart` — `Home extends PageBuilder`. `static const shell = "home"`. `initialized`
  opens the socket (`ConnectionService().open()`, idempotent) if the client is
  authenticated. Listens to `Navis.currentKey` + `BusinessService.activeId`.
- `desktop/_body.dart` — `DesktopBody`: side bar + header + content layout.
- `desktop/side_bar/side_bar.dart` — `SideBar({section})`: the groups from `HomeSection`
  (`home`, `transactions`, `products`, `reports`, `connectionGroups`), collapsible via
  `HomeService`.
- `desktop/side_bar/options.dart` — builds the option list; disables sections whose
  `needsBusiness` is unmet.
- `desktop/side_bar/option.dart` — `Option({icon, title, action, isExpanded, isActive})`.
- `desktop/side_bar/profile.dart` — `ProfileCard`: the client at the bottom of the bar.
- `desktop/side_bar/sign_out.dart` — `SignOut`.
- `header/_header.dart` — `HomeHeader`: app search, business selector, notifications/inbox.
- `header/business_selector.dart` — `BusinessSelector`: switches the active business
  (it lives in the header because the choice rules everything below it) and offers
  business creation.
- `sections/_sections.dart` — **the section registry**:
  - `enum HomeSection` with `key`, `path`, `icon`; values: `dashboard business inventory
    services channels connections sales finance marketing report externalServices`.
  - Groups: `HomeSection.home` (dashboard, business), `.transactions` (sales, finance),
    `.products`, `.reports`, `.connectionGroups`. The POS closes the transactions group in
    the bar but is **not** in any list: it is a page of its own, so `options.dart` builds
    that option by hand.
  - `byKey(key)`, `containing(currentKey)`, `isCurrent(currentKey)`, `title(context)`,
    `needsBusiness`, `build()`.
  - `homeContent(currentKey, section, businessId)` — what the shell shows, including
    routing to sub-pages.
- `sections/section_tabs.dart` — `SectionTabs<T>({tabs, active, icon, title, onTab})`: the
  tab bar of a section split into tabs. Generic over the tab enum, drawn by the business
  page and the money page. **Use it for a new tabbed section instead of a second bar.**
- `sections/business_listener.dart` — `mixin BusinessListener<T>`: tells a sub-page that
  another business was activated.
- `sections/no_business.dart` — `NoBusinessSection`: shown when the client has no business.
- `sections/placeholder.dart` — `SectionPlaceholder`: default content of sections without
  a screen yet (`dashboard`, `services`, `marketing`, `report`, `externalServices`).
- `sections/section_message.dart` — `SectionMessage({icon, message, action?})`: the
  full-section empty/error/loading state. Use this instead of ad-hoc centered columns.

## Sections with their own module

| Section | Path | Spec |
|---|---|---|
| business | `sections/business` | `sections/business/MODULE.md` |
| inventory | `sections/inventory` | `sections/inventory/MODULE.md` |
| channels | `sections/channels` | `sections/channels/MODULE.md` |
| connections | `sections/connections` | `sections/connections/MODULE.md` |
| sales | `sections/sales` | `sections/sales/MODULE.md` |
| finance | `sections/finance` | `sections/finance/MODULE.md` |

## Adding a section

1. Add a value to `HomeSection` (key, path, icon) and to one of the group lists.
2. Add its title case in `title(context)` and its widget in `build()`.
3. Add the `S` key in `lib/l10n/intl_en.arb`.
4. The `ScreenRoute` is generated from `HomeSection.values` — nothing to add in
   `routes.dart` unless the section has sub-pages, which are declared there with
   `parents: ["<section key>"]` and `shell: Home.shell`.
