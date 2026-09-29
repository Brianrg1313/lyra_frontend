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
  `key icon routeKey path(businessId) area ownsSurface`, `initial = statistics`, `opening`. Add a tab here.
- `detail_header.dart` — `BusinessDetailHeader`: thin wrapper over `SectionTabs`.
- `business_avatar.dart` — `BusinessAvatar`: logo or gradient initial.
- `statistics/_statistics.dart` — `BusinessStatisticsTab` (default).
- `branches/_branches.dart` — `BusinessBranchesTab`: heading + add button, card grid of `BusinessBranchesService.branches`; add and a card tap open `showBranchForm` (create / edit).
- `clients/_clients.dart` — `BusinessClientsTab`.

### employees/ — one `Surface`: the people (left, 3/5) and the selected one's detail (right, 2/5, inset `Surface.line` over `surfaceOver`)

- `_employees.dart` — `BusinessEmployeesTab`: loads `BusinessEmployeesService`; list + detail keyed by the selected person.
- `employee_list.dart` — `EmployeeList`, `EmployeeTile`, `EmployeeGroup`, `EmployeeRollGroup`: heading with the invite button (`showInviteEmployee`) and a bar of today's split, current people grouped by where they are today (working, away, starting later, waiting to accept; viewer first in its group, marked "You"), then former; the selected row filled with the detail's color; contract/since columns only when wide, a tag only on a leave.
- `employee_detail.dart` — `EmployeeDetailPanel`: hero header (presence wash, quick copy actions) from the list row at once, blocks after `GET /business/employees/detail/:ID`, with a search box above them; the viewer's unfiled card has no detail.
- `employee_blocks.dart` — `employeeBlocks(context, detail)`: personal data first (full profile only), tenure tiles (time in job, in company, contract), away today, ending, work contact, job + pay, emergency, upcoming absences, record, notes; `EmployeeEditor`: what is editable and the per-key save.
- `employee_edit.dart` — `EmployeeTextFact` (typed in the tile; the check (shown only once changed) or Enter saves, never blur; Escape or a press outside the tile (`TapRegion`, ignored while its own dropdown is open) cancels; with `onPlace` an address searched with `PlaceSearch`), `EmployeeSelectFact` (`showSelectMenu` under the tile; clearable, creatable, lazy `loadOptions`), shared `EmployeeEditButton` (closed tile), `EmployeeEditFrame` (open tile + `EmployeeConfirm` check), `EmployeeSaving`.
- `employee_edit_phone.dart` — `EmployeePhoneFact`: country code select + digits, sent as `+<code><number>`; widens its tile while open.
- `employee_edit_date.dart` — `EmployeeDateFact`: day and year typed, month chosen, sent as `yyyy-MM-dd`; widens its tile while open.
- `employee_card.dart` — detail shapes: `EmployeeSection`, `EmployeeFacts` (2-column tile grid of `EmployeeTile`s; a tile widens to the whole row with `EmployeeWiden`), `EmployeeSearch` (the panel's search: filters tiles by label/value, sections by title), `EmployeeFactFrame`/`EmployeeFactValue` (a tile's inside), `EmployeeFact` (read-only, copyable tile), `EmployeeEvent` (calendar leaf), `EmployeeNote`, `EmployeeQuickAction`, `employeeCopy`.
- `employee_avatar.dart` — `EmployeeAvatar`: profile picture or initials, optional status dot.
- `employee_format.dart` — labels for every backend word (state, work status, contract, workday, period, leave, ending, document, sex), `employeePresence` (tag + color), day/range/span labels.

### settings/ — the profile (read-only sheet; **every edit opens a modal** in `lib/screens/modals/business`)

- `_settings.dart` — `BusinessSettingsTab`: assembles the sheet.
- `profile_header.dart` — `BusinessProfileHeader`: logo, name, legal status, ownership.
- `profile_logo.dart` — `BusinessProfileLogo`: pick + crop + upload (`/business/logo/`).
- `profile_details.dart` — `BusinessProfileDetails`: all loaded data, grouped.
- `profile_identity.dart` — `BusinessProfileIdentity`: legal name, handle, activity, fiscal id, incorporation.
- `profile_incorporation.dart` — `BusinessProfileIncorporation`: year typed, month selected, day typed.
- `profile_phone.dart` — `BusinessProfilePhone`: country code + number.
- `profile_emails.dart` — `ProfileEmailField`, `ProfileEmailAdd`.
- `profile_website.dart` — `BusinessProfileWebsite`: the only external link (`url_launcher`).
- `profile_id.dart` — `BusinessProfileId`: hidden id, reveal + copy.
- `profile_danger.dart` — `BusinessProfileDanger`: delete the business.
- `profile_block.dart` — `ProfileBlock`, `ProfileFieldList`: a group over a surface.
- `profile_field.dart` — `ProfileFieldFrame`, `ProfileField`, `ProfileTextAction`, `ProfileAction`: row primitives.
- `profile_select.dart` — `ProfileSelectField`: `SelectInput` row edited in place (sector, language). No currency here: it lives in the finance section (payment methods tab).
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
  `employee_profile_owned` otherwise) and they write the person's own profile, not a copy. The person's `email` is the account's sign-in and is never written from here.
- `BusinessBranchesService` and `BusinessEmployeesService` are provided by `_business_detail.dart`, not app-wide:
  switching tabs keeps what was read, switching business remounts the page and drops it.
