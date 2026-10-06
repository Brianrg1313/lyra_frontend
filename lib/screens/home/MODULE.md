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
- **Permissions gate twice too**, sections and tabs alike (`PermissionsService`): the side bar / `SectionTabs`
  mark the lock but still open, and the body refuses to mount without `<area>.view` → `NoPermissionSection`.
  A tab's area is `<section>.<key>` (its enum's `area`); a bare section opens its enum's `opening` (first granted tab).
  Tabbed pages listen to `PermissionsService` themselves (const-section trap).
- **The deployment mode gates before both** (`CapabilityService`): a section the network can't serve now
  (`needsInternet`) is locked in the side bar with that reason and still opens, and `homeContent` mounts
  `UnavailableSection` for it; only a `hidden` one is left out (a group with none left loses its title). Tabs the same.

## Files

- `_home.dart` — `Home extends PageBuilder`, `static const shell = "home"`. `initialized` opens the
  socket (`ConnectionService().open()`, idempotent) when authenticated; `_OfferOnline` (on `HybridService` and `CapabilityService`) joins a master's
  company with its company online whenever `HybridService.shouldAskLink` turns true (`askLinkCompany`), and opens the online sign in once a session on the master alone can go online (`HybridService.shouldOfferOnline`). Listens to `Navis.currentKey` + `BusinessService.activeId`, and
  rebuilds on `PermissionsService` and `CapabilityService` (the internet or "work offline" lock a section in place).
- `desktop/_body.dart` — `DesktopBody`: side bar + header + content.
- `desktop/side_bar/side_bar.dart` — `SideBar({section})`: groups from `HomeSection`, collapsible via `HomeService`.
- `desktop/side_bar/options.dart` — option list (each with `BadgePlace.section`; opening one `discover`s its news); locks unmet `needsBusiness` and, with a business, sections without `<key>.view` (`PermissionsService`) — those still open, onto `NoPermissionSection`. No POS option (the POS opens from the header).
- `desktop/side_bar/option.dart` — `Option({icon, title, action, isExpanded, isActive, lockedMessage, badge})` (`lockedMessage` non-null = locked, shown as tooltip; `opensLocked` = still clickable; `badge` = its `BadgePlace`, a mark after the title or a dot on the icon when collapsed, none when locked).
- `desktop/side_bar/profile.dart` — `ProfileCard` (`ConnectionDot` on the picture's bottom-right). `desktop/side_bar/connection_dot.dart` — `ConnectionDot`: the socket's state (green connected, yellow connecting, red down, nothing while idle). `desktop/side_bar/sign_out.dart` — `SignOut`: calls `ClientService.signOut`.
- `header/_header.dart` — `HomeHeader`: search (`HomeService.searchQuery`, cleared on screen change), business selector, POS (`BadgePlace.pos`),
  the bell (`BadgePlace.bell`; opens `showPendingPanel`, then goes to `badgeRoute`), inbox (coming soon).
- `badges/badge_mark.dart` — `BadgeMark({place, dot})` (a number when the place counts things, a dot for alerts/news, nothing
  when clear; listens to the `BadgesService` singleton, no provider needed), `BadgeCorner({place, child, dot, outside})`, `badgeColor(level)` (info blue, warning yellow, critical red).
- `badges/badge_notes.dart` — `BadgeNotes({place, padding})`: what a place has pending in words, one tinted line per badge, on top of the page the dot leads to.
- `badges/badge_title.dart` — `badgeTitle(context, badge)`: the badge's `title` l10n key → `S`; an unknown one → `badge_unknown`.
- `badges/badge_route.dart` — `badgeRoute(badge, business:)`: the app page that clears a badge, by its most specific anchor; `null` = none yet.
- `header/business_selector.dart` — `BusinessSelector`: switches the active business, offers creation; with
  `CapabilityService.singleCompany` only shows the one company.
- `sections/_sections.dart` — **section registry**: `enum HomeSection` (`key path icon`; `dashboard
  business inventory services channels connections messages deliveries sales finance marketing report externalServices
  server`), groups `.home` (dashboard, business, messages, deliveries, sales; untitled) `.products`
  `.reports` (finance first) `.connectionGroups` (with `server`, key `local_server`, only on a master's devices); `byKey`, `containing`, `isCurrent`, `title(context)`,
  `needsBusiness`, `build()`; `homeContent(currentKey, section, businessId)` (incl. sub-pages).
- `sections/section_tabs.dart` — `SectionTabs<T>({tabs, active, icon, title, onTab, isLocked?, badge?})` (locked = lock icon, still opens; `badge` = a tab's `BadgePlace`, a dot after its title): tab bar used
  by business, finance and sales. **Reuse it for any new tabbed section.**
- `sections/page_switcher.dart` — `PageSwitcher({id, child})`: ~300 ms fade-through between the pages of one section.
  Wraps `homeContent` (keyed by section, so switching sections does not animate) and the tab bodies of
  business, finance and sales. **Wrap the body of any new tabbed section in it.**
- `sections/business_listener.dart` — `mixin BusinessListener<T>`.
- `sections/no_business.dart` — `NoBusinessSection`.
- `sections/unavailable.dart` — `UnavailableSection({capability, surface})`: a section or tab (`surface: false`) the deployment mode lacks, or locked until the internet answers; a session on the master alone offers "sign in online" (`showOnlineSignIn`) once the backend answers (`HybridService.canGoOnline`), otherwise nothing to ask for.
- `sections/no_permission.dart` — `NoPermissionSection({permission, title, surface = true})`: shown by `homeContent` in place of a section without `<key>.view`, and by business/finance/sales in place of a tab (`surface: false`); owns a `PermissionRequestsService`, offers "Request access" unless one is pending.
- `sections/placeholder.dart` — `SectionPlaceholder`: `dashboard services marketing report externalServices`.
- `sections/section_message.dart` — `SectionMessage({icon, message, action?})`: full-section empty/error/loading. Use instead of ad-hoc centered columns.

## Sections with their own module

`sections/{business,inventory,channels,connections,messages,deliveries,sales,finance,local_server}/MODULE.md`.

## Adding a section

1. Value in `HomeSection` (key, path, icon) + a group list.
2. Title in `title(context)`, widget in `build()`.
3. `S` key in `lib/l10n/intl_en.arb`.
4. Its route is generated from `HomeSection.values`; only sub-pages go in `routes.dart`
   (`parents: ["<key>"]`, `shell: Home.shell`).
