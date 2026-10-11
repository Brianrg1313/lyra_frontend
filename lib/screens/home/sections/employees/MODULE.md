# Module: employees section

**Path** `lib/screens/home/sections/employees`
**Role** Who works in the active company, in two panels: the list on the left, always in sight, and the detail on the right, which navigates: one person (`/home/employees/:id`, the viewer's card always `me`; bare `/home/employees` shows the viewer's): their header and an index of their card's parts, each part on its own page (`/home/employees/:id/<part>`), and on one's own card the account's subsections (`/home/employees/me/<subsection>`). Content of the `employees` home section, right after business in the side bar.
**Services** `BusinessEmployeesService` (`lib/services/business`), `AccountSecurityService` + `AccountHistoryService` (`lib/services/account`) — created and provided by `_employees.dart`.

## Files

- `_employees.dart` — `EmployeesSection`: owns and provides the services (dropped on a business switch, the home content remounts); loads the list, the account on the first own page; lays the list (2/5) and the detail (3/5) on two `Surface`s, the detail's topped by the person's bar (`EmployeeDetailHeader`), which stays; resolves the detail's page from `Navis.currentKey`/`currentArgs` (no or unknown person → the viewer's card, part without a job → their page) and swaps only it with a `PageSwitcher`.
- `employee_page.dart` — `EmployeePage`: body of the detail panel's pages, under the person's bar (optional back arrow to a path + title; body at a reading width from the left; `scroll` off for the permissions). No surface: the panel's stays put.
- `employee_panel_bar.dart` — `EmployeePanelBar`: both panels' top (one height, a line across), so the list's heading and the person's bar line up.
- `employee_format.dart` — labels for every backend word (state, work status, contract, workday, period, leave, ending, document, sex), `employeePresence` (tag + color), day/range/span labels.

### employee_list/ — the left panel

- `_employee_list.dart` — `EmployeeList` (`onOpen`, `selected`): heading, column names when wide, current people then former (`_GroupTitle`).
- `employee_list_heading.dart` — `EmployeeListHeading`: the list's bar — title, counts (only with the view), invite button (`showInviteEmployee`).
- `employee_list_columns.dart` — `EmployeeListColumns`: names the wide rows' columns once.
- `employee_row.dart` — `EmployeeRow` (`statusWidth`): picture, name ("You" on the viewer's), job, contract and since only when wide, presence tag; `selected` filled.

### employee_detail/ — one person's page and the pages of their card

- `_employee_detail.dart` — `EmployeeDetailPage` (`routeKey`, `path(id)`, `idOf`): no arrow; the headline, and after `GET /business/employees/detail/:ID` the "Work" index of the parts with something to say (permissions: one's own always, someone else's only with `business.employees.permissions`); on one's own card the sign-in posture (`account.security` only) and the "Your account" index of `OwnSection` (the soon ones apart); the viewer's unfiled card has no detail, only the account.
- `employee_part.dart` — `enum EmployeePart` (personal, job, absences, record, notes, permissions: icon, title, subtitle, `routeKey`, `path(id)`, `byRouteKey`).
- `employee_part_page.dart` — `EmployeePartPage`: one part's blocks (reads the detail too, for a direct link) or `EmployeePermissions`.
- `employee_detail_header.dart` — `EmployeeDetailHeader`: the detail panel's bar, drawn from the list row at once: picture, name, tags, username · job, quick copy actions.
- `employee_quick_action.dart` — `EmployeeQuickAction`: a header's square copy button.
- `widgets/employee_index_group.dart` — `EmployeeIndexGroup` (rows over one surface, optional title). `widgets/employee_index_row.dart` — `EmployeeIndexRow` (icon, title, subtitle, arrow or soon tag).
- `widgets/employee_detail_failed.dart` — `EmployeeDetailFailed` (retry). `widgets/employee_detail_loading.dart` — `EmployeeDetailLoading`.
- `blocks/_blocks.dart` — `employeePartBlocks(context, part, detail, {own})`: a part's blocks in order, those with nothing to say left out — personal: person (full profile only; `sealedLocked` → "Type password" → `showUnseal`, then the detail again), emergency; job: tenure, job + pay, work contact; absences: away today, upcoming; record: ending, record; notes.
- `blocks/employee_editor.dart` — `EmployeeEditor`: what is editable and the per-key save (`save` job keys, `savePerson` personal keys, `place`).
- `blocks/employee_block_values.dart` — the checks (names, work email, amount, birthday) and the blocks' shared values (company country, digit formatters, options in use, countries).
- `blocks/employee_<name>_block.dart` — one per block: `EmployeePersonBlock` `EmployeeTenureBlock` `EmployeeLeaveNowBlock` `EmployeeEndingBlock` `EmployeeWorkContactBlock` `EmployeeJobBlock` `EmployeeEmergencyBlock` `EmployeeUpcomingBlock` `EmployeeRecordBlock` `EmployeeNotesBlock`.

### employee_facts/ — the detail's shapes (sheets of tiles)

- `_employee_facts.dart` — `EmployeeFacts` (one sheet per group, a 2-column grid; a tile widens to the whole row with `EmployeeWiden`), `EmployeeTile` (the interface every tile implements: `label value wide`).
- `employee_section.dart` — `EmployeeSection`: a titled group, filtered by the search.
- `employee_search.dart` — `EmployeeSearch`: a search over tiles (by label/value) and sections (by title), case and accents ignored; used by the permissions' search, none above the parts (all shows).
- `employee_fact.dart` — `EmployeeFact`: read-only, copyable tile. `employee_copy.dart` — `employeeCopy`.
- `employee_event.dart` — `EmployeeEvent` (calendar leaf). `employee_note.dart` — `EmployeeNote`.
- `employee_text_fact.dart` — `EmployeeTextFact` (typed in the tile; the check (shown only once changed) or Enter saves, never blur; Escape or a press outside the tile (`TapRegion`, ignored while its own dropdown is open) cancels; with `onPlace` an address searched with `PlaceSearch`).
- `employee_select_fact.dart` — `EmployeeSelectFact` (`showSelectMenu` under the tile; clearable, creatable, lazy `loadOptions`).
- `employee_phone_fact.dart` — `EmployeePhoneFact`: country code select + digits (trunk `0` dropped, length per `PhonePlan`), sent as `+<code><number>`; widens its tile while open.
- `employee_date_fact.dart` — `EmployeeDateFact`: day and year typed, month chosen, optional `validate`, sent as `yyyy-MM-dd`; widens its tile while open.
- `widgets/employee_fact_frame.dart` — `EmployeeFactFrame` (a tile's inside; `accent` tints the open one; the shared paddings, radii and icon sizes). `widgets/employee_fact_value.dart` — `EmployeeFactValue`.
- `widgets/employee_hover.dart` — `EmployeeHover`; `widgets/employee_hint.dart` — `EmployeeHint` (edit/copy/unfold hints shown only under the pointer, always without a mouse).
- `widgets/employee_edit_button.dart` — `EmployeeEditButton` (closed typed tile). `widgets/employee_edit_frame.dart` — `EmployeeEditFrame` (open tile). `widgets/employee_confirm.dart` — `EmployeeConfirm` (the check). `widgets/employee_saving.dart` — `EmployeeSaving`.

### employee_permissions/ — one person's permissions (the permissions part's page)

- `_employee_permissions.dart` — `EmployeePermissions` (`username`, none = one's own): note, `PermissionBranches` (several branches), template picker, search, one sheet per section, footer (cancel/save, give access, remove access); over `MemberPermissionsService`.
- `permission_section.dart` — `enum PermissionSection` (every section of `PermissionCatalog`: icon, title, description, action titles).
- `permission_template_text.dart` — `permissionTemplateText` (a global template in the app's words).
- `permission_branches.dart` — `PermissionBranches`: where they work (a chip per branch, "every branch") and which structure the sheets are (`Permissions in`: every branch's, or one branch's own; "use every branch's" resets it, asked first).
- `permission_sheet.dart` — `PermissionSheet`: a section's switch and its actions threaded under it (locked keys the viewer lacks). `permission_cell.dart` — `PermissionCell` (one switch). `permission_thread.dart` — `PermissionThread`. `permission_grid.dart` — `PermissionGrid` (sizes shared by the rows).

### own_settings/ — the viewer's own account (app area `account`): subsections listed on their own card's page, each a page of its own

- `own_section.dart` — `enum OwnSection` (icon, title, subtitle, body, `soon`, `routeKey`, `path`, `byRouteKey`).
- `own_preferences.dart` — `OwnPreferences`: language and appearance of this device, and how inventory tables open (`PreferencesService`), every mode.
- `own_security.dart` — `OwnSecurity`: first password (`showCreatePassword`), second factor (on, change, off: `showTwoFactorSetup`, `showTwoFactorProof`), recovery codes left / new set (app only), SMS and recovery e-mails soon.
- `own_sign_in_methods.dart` — `OwnSignInMethods`: the sign-in e-mail, Google/Apple/Microsoft soon.
- `own_sessions.dart` — `OwnSessions`: this device (platform, sign out), other devices soon.
- `own_history.dart` — `OwnHistory`: every company worked for; `widgets/own_history_job.dart` — `OwnHistoryJob` (logo, role, contract, since/range, tenure, state tag).
- `own_notifications.dart` — `OwnNotifications`; `own_privacy.dart` — `OwnPrivacy` (all rows soon, the tag on the page's lead line).
- `widgets/own_section_page.dart` — `OwnSectionPage` (lead line and the body over one surface).
- `widgets/own_sign_in_posture.dart` — `OwnSignInPosture`: one sentence on the sign in's steps, warning tint and a "turn on" action without a second step.
- `widgets/own_soon.dart` — `OwnSoon` (a muted line with no backend yet); `widgets/own_soon_list.dart` — `OwnSoonList` (them under one "coming soon"); `widgets/own_soon_tag.dart` — `OwnSoonTag`; `widgets/own_offline.dart` — `OwnOffline` (a cloud row without the cloud); `widgets/own_link.dart` — `OwnLink` (a row's text action).

## Conventions

- **The permission area is still `business.employees`** (`HomeSection.area`): the section was a business tab, and its grants
  (`business.employees.view/invite/permissions`) are the backend's `employees.*`; the capability and side bar locks read the same area.
- **Employee edits are one key per save** (`PUT /business/employees/`, `BusinessEmployeesService.edit`), except a picked address place (address + city, region, postal code, country in one): the job only
  while invited/active and with the app area `business.employees.invite` (= backend `employees.manage`; the app tree never holds backend keys); the person's keys only when `profile_editable` (= job active; the backend answers
  `employee_profile_owned` otherwise) and they write the person's own profile, not a copy. **The viewer's own personal keys** are
  always editable, with no permission, through `PUT /profile/` (`BusinessEmployeesService.editOwn`); their job is not. The person's `email` is the account's sign-in and is never written from here.
- **Everyone sees their own employee profile**: the section is always granted (`HomeSection.granted`); without `business.employees.view`
  (`BusinessEmployeesService.viewsAll`) the backend answers only the viewer's card and job (no `notes`), the former list
  is not read, and the counts and invite button are hidden. The permissions part shows on one's own card always, on others' only with `business.employees.permissions`.
