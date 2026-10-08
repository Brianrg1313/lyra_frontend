# Module: business section

**Path** `lib/screens/home/sections/business`
**Role** One business through its tabs (statistics, branches, clients, settings; the people are the employees section). Content of the `business` home section and of
`/home/business/:id[/<tab>]`.
**Service** `BusinessService` (`lib/services/business`).

## Routing

- `BusinessDetailSection.routeKey` → `/home/business/:id` (opens `BusinessTab.initial`).
- One route per tab from `BusinessTab.values`: `/home/business/:id/<key>`,
  `routeKey = "business_<key>"`, `parents: ["business"]`, `shell: Home.shell`.

## Files

- `_business_detail.dart` — `BusinessDetailSection`: resolves `:id`, loads the profile, tab bar + active tab (`NoPermissionSection` when not granted, see home module).
- `business_tab.dart` — `enum BusinessTab { statistics, branches, clients, settings }`:
  `key icon routeKey path(businessId) area granted badge bleeds` (settings: the profile's setup), `initial = statistics`, `opening`. Add a tab here.
- `detail_header.dart` — `BusinessDetailHeader`: thin wrapper over `SectionTabs`.
- `statistics/_statistics.dart` — `BusinessStatisticsTab` (default).
- `branches/_branches.dart` — `BusinessBranchesTab`: the sheet is a `DeliveriesMap` (own `BusinessLocationService` + `MapTilesService`), edge to edge (`BusinessTab.bleeds`), opening on the company's point (else the tileset center); `BranchesPanel` floats on its left (25/30/36% of the width on desktop/tablet/phone), the add button (`showBranchForm`) on its top right, hidden when the list failed; every branch is marked on the map (`BranchMarkers`); a tapped branch moves the map to its point and opens `showBranchForm` on it.
- `branches/branches_panel.dart` — `BranchesPanel`: the side bar's line and shadow; heading, local search (name, address), list of `BusinessBranchesService.branches`, main first; loading / error + retry / empty / no match.
- `branches/branches_heading.dart` — `BranchesHeading({onAdd})`: title, subtitle, add button (none without `onAdd`).
- `branches/branch_markers.dart` — `BranchMarkers`: map layer with one tappable mark per non-main branch with a point.
- `branches/branch_row.dart` — `BranchRow`: icon (yellow star on the main one), name, address; tappable (`onTap`).
- `clients/_clients.dart` — `BusinessClientsTab`.

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
- `profile_email_field.dart` — `ProfileEmailField`. `profile_email_add.dart` — `ProfileEmailAdd`.
- `profile_website.dart` — `BusinessProfileWebsite`: the only external link (`url_launcher`).
- `profile_id.dart` — `BusinessProfileId`: hidden id, reveal + copy.
- `profile_danger.dart` — `BusinessProfileDanger`: delete the business.
- `profile_block.dart` — `ProfileBlock`: a group over a surface. `profile_field_list.dart` — `ProfileFieldList`: its rows.
- Row primitives: `profile_field_frame.dart` — `ProfileFieldFrame` (`badge`: a dot after the name); `profile_field.dart` — `ProfileField`; `profile_text_action.dart` — `ProfileTextAction`; `profile_action.dart` — `ProfileAction`.
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
- `BusinessBranchesService` is provided by `_business_detail.dart`, not app-wide:
  switching tabs keeps what was read, switching business remounts the page and drops it.
