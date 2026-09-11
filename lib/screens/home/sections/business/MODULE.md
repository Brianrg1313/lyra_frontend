# Module: business section

**Path** `lib/screens/home/sections/business`
**Role** The business page: one business seen through five tabs. Content of the `business`
home section and of its sub-page `/home/business/:id[/:tab]`.
**Service** `BusinessService` (`lib/services/business`).

## Routing

- `BusinessDetailSection.routeKey` → `/home/business/:id` (opens `BusinessTab.initial`).
- One route per tab, generated from `BusinessTab.values`: `/home/business/:id/<key>`,
  `routeKey = "business_<key>"`. All declare `parents: ["business"]` and `shell: Home.shell`.
- Separate routes per tab (not a `:tab` arg) because the shell learns of a screen change
  through `Navis.currentKey`.

## Files

- `_business_detail.dart` — `BusinessDetailSection`: resolves the business from the `:id`
  segment, loads the profile, hosts the tab bar and the active tab body.
- `business_tab.dart` — `enum BusinessTab { statistics, employees, branches, clients,
  settings }` with `key`, `icon`, `routeKey`, `path(businessId)`, `initial = statistics`.
  Adding a tab is adding a case here; the route table reads this list.
- `detail_header.dart` — `BusinessDetailHeader`: the tab bar. It is a thin wrapper over
  `SectionTabs` (`sections/section_tabs.dart`), shared with the money page; what belongs
  to a business is which tabs there are and what each one is called.
- `business_avatar.dart` — `BusinessAvatar`: logo, or a gradient avatar with the initial.

### statistics/
- `_statistics.dart` — `BusinessStatisticsTab`. Default tab: how the business is doing.

### employees/
- `_employees.dart` — `BusinessEmployeesTab`: people, rank and permissions.
  Reads `BusinessService.employees` / `BusinessEmployeesStatus`.

### branches/
- `_branches.dart` — `BusinessBranchesTab`: locations.

### clients/
- `_clients.dart` — `BusinessClientsTab`: who the business sells to.

### settings/ — the business profile

The tab is a read-only sheet; **every edit opens a modal** (`lib/screens/modals/business`:
`edit_business_field`, `edit_business_email`, `verify_business_email`).

- `_settings.dart` — `BusinessSettingsTab`: assembles the sheet below.
- `profile_header.dart` — `BusinessProfileHeader`: logo, name, legal status, ownership.
- `profile_logo.dart` — `BusinessProfileLogo`: pick + crop + upload (`/business/logo/`).
- `profile_details.dart` — `BusinessProfileDetails`: all loaded data, grouped.
- `profile_identity.dart` — `BusinessProfileIdentity`: legal name, handle, activity,
  fiscal id, incorporation.
- `profile_incorporation.dart` — `BusinessProfileIncorporation`: year typed, month
  selected, day typed.
- `profile_phone.dart` — `BusinessProfilePhone`: country code select + number.
- `profile_emails.dart` — `ProfileEmailField`, `ProfileEmailAdd`: the address rows.
- `profile_website.dart` — `BusinessProfileWebsite`: the only row that opens an external
  link (`url_launcher`).
- `profile_id.dart` — `BusinessProfileId`: hidden identifier with reveal + copy.
- `profile_danger.dart` — `BusinessProfileDanger`: delete the business.
- `profile_block.dart` — `ProfileBlock`, `ProfileFieldList`: a group over a surface.
- `profile_field.dart` — `ProfileFieldFrame`, `ProfileField`, `ProfileTextAction`,
  `ProfileAction`: the row primitives every block is built from.
- `profile_select.dart` — `ProfileSelectField`: a row whose value is a `SelectInput`
  (sector, language, currency).
- `profile_tag.dart` — `ProfileTag`: state chip (icon + text over a tinted fill).
- `country_flag.dart` — `CountryFlag`: a row-sized flag.

## Conventions

- New profile datum: add it to `BusinessProfileModel`, render a row via `ProfileField`
  inside the right `ProfileBlock`, and add its key to `BusinessField`
  (`lib/screens/modals/business/edit_business_field/business_field.dart`) so the edit modal can
  write it.
- Country/currency/language values always come from the catalog services, never hardcoded.
