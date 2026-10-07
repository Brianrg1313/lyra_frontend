# Module: business section

**Path** `lib/screens/home/sections/business`
**Role** One business through its tabs. Content of the `business` home section and of
`/home/business/:id[/<tab>]`.
**Service** `BusinessService` (`lib/services/business`).

## Routing

- `BusinessDetailSection.routeKey` → `/home/business/:id` (opens `BusinessTab.initial`).
- One route per tab from `BusinessTab.values`: `/home/business/:id/<key>`,
  `routeKey = "business_<key>"`, `parents: ["business"]`, `shell: Home.shell`.

## Files

- `_business_detail.dart` — `BusinessDetailSection`: resolves `:id`, loads the profile, tab bar + active tab (`NoPermissionSection` when not granted, see home module).
- `business_tab.dart` — `enum BusinessTab { statistics, employees, branches, clients, settings }`:
  `key icon routeKey path(businessId) area granted ownsSurface badge` (settings: the profile's setup), `initial = statistics`, `opening`. Add a tab here.
- `detail_header.dart` — `BusinessDetailHeader`: thin wrapper over `SectionTabs`.
- `statistics/_statistics.dart` — `BusinessStatisticsTab` (default).
- `branches/_branches.dart` — `BusinessBranchesTab`: heading + add button, card grid of `BusinessBranchesService.branches`; add and a card tap open `showBranchForm` (create / edit).
- `clients/_clients.dart` — `BusinessClientsTab`.

### employees/ — one `Surface`: the people (left, 3/5) and the selected one's detail (right, 2/5, inset `Surface.line` over `surfaceOver`)

- `_employees.dart` — `BusinessEmployeesTab`: loads `BusinessEmployeesService`; list + detail keyed by the selected person.
- `employee_format.dart` — labels for every backend word (state, work status, contract, workday, period, leave, ending, document, sex), `employeePresence` (tag + color), day/range/span labels.

#### employees/employee_list/ — the left panel

- `_employee_list.dart` — `EmployeeList`: heading, column names when wide, current people then former (`_GroupTitle`); the selected row filled with the detail's color.
- `employee_list_heading.dart` — `EmployeeListHeading`: title, counts (only with the view), invite button (`showInviteEmployee`).
- `employee_list_columns.dart` — `EmployeeListColumns`: names the wide rows' columns once.
- `employee_row.dart` — `EmployeeRow` (`statusWidth`): picture, name ("You" on the viewer's), job, contract and since only when wide, presence tag.

#### employees/employee_detail/ — the right panel

- `_employee_detail.dart` — `EmployeeDetailPanel`: header from the list row at once, blocks after `GET /business/employees/detail/:ID`, a search box (only the blocks listen to it) and `EmployeeActions` above them; the viewer's unfiled card has no detail.
- `employee_detail_header.dart` — `EmployeeDetailHeader`: presence wash, picture, name, quick copy actions, tags, job, headline.
- `employee_quick_action.dart` — `EmployeeQuickAction`: a header's square copy button.
- `employee_action.dart` — `enum EmployeeAction` (permissions, settings, activity, sales: icon, label, description).
- `employee_actions.dart` — `EmployeeActions`: one sheet under the search, a 2-column grid (1 when narrow), each opens `showEmployeeTool`; permissions: the viewer's own read-only, someone else's only with `business.employees.permissions`; settings: on the viewer's card their own account (`OwnSettings`), on another's the placeholder.
- `blocks/_blocks.dart` — `employeeBlocks(context, detail, {own})`: the blocks in order — person (full profile only; `sealedLocked` → "Type password" → `showUnseal`, then the detail again), tenure, away today, ending, work contact, job + pay, emergency, upcoming absences, record, notes.
- `blocks/employee_editor.dart` — `EmployeeEditor`: what is editable and the per-key save (`save` job keys, `savePerson` personal keys, `place`).
- `blocks/employee_block_values.dart` — the checks (names, work email, amount, birthday) and the blocks' shared values (company country, digit formatters, options in use, countries).
- `blocks/employee_<name>_block.dart` — one per block: `EmployeePersonBlock` `EmployeeTenureBlock` `EmployeeLeaveNowBlock` `EmployeeEndingBlock` `EmployeeWorkContactBlock` `EmployeeJobBlock` `EmployeeEmergencyBlock` `EmployeeUpcomingBlock` `EmployeeRecordBlock` `EmployeeNotesBlock`.

#### employees/employee_facts/ — the detail's shapes (sheets of tiles)

- `_employee_facts.dart` — `EmployeeFacts` (one sheet per group, a 2-column grid; a tile widens to the whole row with `EmployeeWiden`), `EmployeeTile` (the interface every tile implements: `label value wide`).
- `employee_section.dart` — `EmployeeSection`: a titled group, filtered by the search.
- `employee_search.dart` — `EmployeeSearch`: the panel's search (filters tiles by label/value, sections by title; case and accents ignored).
- `employee_fact.dart` — `EmployeeFact`: read-only, copyable tile. `employee_copy.dart` — `employeeCopy`.
- `employee_event.dart` — `EmployeeEvent` (calendar leaf). `employee_note.dart` — `EmployeeNote`.
- `employee_text_fact.dart` — `EmployeeTextFact` (typed in the tile; the check (shown only once changed) or Enter saves, never blur; Escape or a press outside the tile (`TapRegion`, ignored while its own dropdown is open) cancels; with `onPlace` an address searched with `PlaceSearch`).
- `employee_select_fact.dart` — `EmployeeSelectFact` (`showSelectMenu` under the tile; clearable, creatable, lazy `loadOptions`).
- `employee_phone_fact.dart` — `EmployeePhoneFact`: country code select + digits (trunk `0` dropped, length per `PhonePlan`), sent as `+<code><number>`; widens its tile while open.
- `employee_date_fact.dart` — `EmployeeDateFact`: day and year typed, month chosen, optional `validate`, sent as `yyyy-MM-dd`; widens its tile while open.
- `widgets/employee_fact_frame.dart` — `EmployeeFactFrame` (a tile's inside; `accent` tints the open one; the shared paddings, radii and icon sizes). `widgets/employee_fact_value.dart` — `EmployeeFactValue`.
- `widgets/employee_hover.dart` — `EmployeeHover`; `widgets/employee_hint.dart` — `EmployeeHint` (edit/copy/unfold hints shown only under the pointer, always without a mouse).
- `widgets/employee_edit_button.dart` — `EmployeeEditButton` (closed typed tile). `widgets/employee_edit_frame.dart` — `EmployeeEditFrame` (open tile). `widgets/employee_confirm.dart` — `EmployeeConfirm` (the check). `widgets/employee_saving.dart` — `EmployeeSaving`.

#### employees/employee_permissions/ — one person's permissions (side panel of the permissions action)

- `_employee_permissions.dart` — `EmployeePermissions` (`username`, none = one's own): note, template picker, search, one sheet per section, footer (cancel/save, give access, remove access); over `MemberPermissionsService`.
- `permission_section.dart` — `enum PermissionSection` (every section of `PermissionCatalog`: icon, title, description, action titles).
- `permission_template_text.dart` — `permissionTemplateText` (a global template in the app's words).
- `permission_sheet.dart` — `PermissionSheet`: a section's switch and its actions threaded under it (locked keys the viewer lacks). `permission_cell.dart` — `PermissionCell` (one switch). `permission_thread.dart` — `PermissionThread`. `permission_grid.dart` — `PermissionGrid` (sizes shared by the rows).

### employees/own_settings/ — the viewer's own account (app area `account`), in the settings action's side panel; an index whose subsections open stacked side panels

- `_own_settings.dart` — `OwnSettings`: owns `AccountSecurityService` and `AccountHistoryService` (read on opening only where `account.security` / `account.history` show); header, a search over every subsection's rows (`OwnSetting.matches`), and the index (`OwnIndex`) or what the search found (`OwnResults`).
- `own_header.dart` — `OwnHeader`: picture, name, email, and one sentence on the sign in's steps (warning tint and a "turn on" action without a second step; only where `account.security` shows).
- `own_section.dart` — `enum OwnSection` (icon, title, subtitle, body, searchable `settings`, `open`: a stacked `showSideModal` re-providing the index's services). `own_setting.dart` — `OwnSetting` (one searchable row, `fold`).
- `own_preferences.dart` — `OwnPreferences`: language and appearance of this device, and how inventory tables open (`PreferencesService`), every mode.
- `own_security.dart` — `OwnSecurity`: first password (`showCreatePassword`), second factor (on, change, off: `showTwoFactorSetup`, `showTwoFactorProof`), recovery codes left / new set (app only), SMS and recovery e-mails soon.
- `own_sign_in_methods.dart` — `OwnSignInMethods`: the sign-in e-mail, Google/Apple/Microsoft soon.
- `own_sessions.dart` — `OwnSessions`: this device (platform, sign out), other devices soon.
- `own_history.dart` — `OwnHistory`: every company worked for (logo, role, contract, since/range, tenure, state tag).
- `own_notifications.dart` — `OwnNotifications`; `own_privacy.dart` — `OwnPrivacy` (all rows soon, the tag on the page's lead line).
- `widgets/own_index.dart` — `OwnIndex` (working subsections, then the ones with nothing working yet). `widgets/own_results.dart` — `OwnResults`. `widgets/own_group.dart` — `OwnGroup` (rows over one surface).
- `widgets/own_section_row.dart` — `OwnSectionRow`; `widgets/own_setting_row.dart` — `OwnSettingRow`; `widgets/own_row_tap.dart` — `OwnRowTap`; `widgets/own_arrow.dart` — `OwnArrow`.
- `widgets/own_section_page.dart` — `OwnSectionPage` (lead line and the body over one surface).
- `widgets/own_soon.dart` — `OwnSoon` (a muted line with no backend yet); `widgets/own_soon_list.dart` — `OwnSoonList` (them under one "coming soon"); `widgets/own_soon_tag.dart` — `OwnSoonTag`; `widgets/own_offline.dart` — `OwnOffline` (a cloud row without the cloud); `widgets/own_link.dart` — `OwnLink` (a row's text action).

### settings/ — the profile (read-only sheet; **every edit opens a modal** in `lib/screens/modals/business`)

- `_settings.dart` — `BusinessSettingsTab`: assembles the sheet, `BadgeNotes(businessSettings)` on top.
- `profile_header.dart` — `BusinessProfileHeader`: logo (`BadgePlace.logoField` dot), name, legal status, ownership.
- `profile_logo.dart` — `BusinessProfileLogo`: pick + crop + upload (through `BusinessSource.setLogo`); only drawn
  where `business.settings.edit_logo` isn't shown (`CapabilityService`).
- `profile_details.dart` — `BusinessProfileDetails`: all loaded data, grouped; the e-mails block and the danger zone only
  where `business.settings.manage_emails` / `business.delete` exist (`CapabilityService`).
- `profile_identity.dart` — `BusinessProfileIdentity`: legal name, handle, activity, fiscal id, incorporation.
- `profile_incorporation.dart` — `BusinessProfileIncorporation`: year typed, month selected, day typed.
- `profile_phone.dart` — `BusinessProfilePhone`: country code + number.
- `profile_emails.dart` — `ProfileEmailField`, `ProfileEmailAdd`.
- `profile_website.dart` — `BusinessProfileWebsite`: the only external link (`url_launcher`).
- `profile_id.dart` — `BusinessProfileId`: hidden id, reveal + copy.
- `profile_danger.dart` — `BusinessProfileDanger`: delete the business.
- `profile_block.dart` — `ProfileBlock`, `ProfileFieldList`: a group over a surface.
- `profile_field.dart` — `ProfileFieldFrame` (`badge`: a dot after the name), `ProfileField`, `ProfileTextAction`, `ProfileAction`: row primitives.
- `profile_select.dart` — `ProfileSelectField`: `SelectInput` row edited in place (sector, language; the country with `BadgePlace.countryField`). No currency here: it lives in the finance section (payment methods tab).
- `profile_tag.dart` — `ProfileTag`: state chip.
- `country_flag.dart` — `CountryFlag`.

## Conventions

- New profile datum: `BusinessProfileModel` → a `ProfileField` row in the right `ProfileBlock` →
  its key in `BusinessField` (`lib/screens/modals/business/edit_business_field/business_field.dart`).
- Country/language values come from the catalog services, never hardcoded.
- **Where the business is lives in the branches, not in settings**: each branch has its own address, landmark
  and map point, edited in one form (`showBranchForm`); the main branch's is the company's (`GET /business/location/`
  reads it). There is no location tab.
- **The country is the company's**, not a branch's: a select in the settings sheet (`PUT /business/profile/`
  `COUNTRY`), which also moves the clock, the payment rails and the delivery carriers. The branch form reads it to
  fix the phone code and limit the address search.
- **Employee edits are one key per save** (`PUT /business/employees/`, `BusinessEmployeesService.edit`), except a picked address place (address + city, region, postal code, country in one): the job only
  while invited/active and with the app area `business.employees.invite` (= backend `employees.manage`; the app tree never holds backend keys); the person's keys only when `profile_editable` (= job active; the backend answers
  `employee_profile_owned` otherwise) and they write the person's own profile, not a copy. **The viewer's own personal keys** are
  always editable, with no permission, through `PUT /profile/` (`BusinessEmployeesService.editOwn`); their job is not. The person's `email` is the account's sign-in and is never written from here.
- **Everyone sees their own employee profile**: the employees tab is always `granted`; without `business.employees.view`
  (`BusinessEmployeesService.viewsAll`) the backend answers only the viewer's card and job (no `notes`), the former list
  is not read, and the counts and invite button are hidden. `EmployeeActions` show on one's own card always, on others' only with the view.
- `BusinessBranchesService` and `BusinessEmployeesService` are provided by `_business_detail.dart`, not app-wide:
  switching tabs keeps what was read, switching business remounts the page and drops it.
