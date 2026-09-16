# Module: business section

**Path** `lib/screens/home/sections/business`
**Role** One business through five tabs. Content of the `business` home section and of
`/home/business/:id[/<tab>]`.
**Service** `BusinessService` (`lib/services/business`).

## Routing

- `BusinessDetailSection.routeKey` → `/home/business/:id` (opens `BusinessTab.initial`).
- One route per tab from `BusinessTab.values`: `/home/business/:id/<key>`,
  `routeKey = "business_<key>"`, `parents: ["business"]`, `shell: Home.shell`.

## Files

- `_business_detail.dart` — `BusinessDetailSection`: resolves `:id`, loads the profile, tab bar + active tab.
- `business_tab.dart` — `enum BusinessTab { statistics, employees, branches, location, delivery, clients, settings }`:
  `key icon routeKey path(businessId)`, `initial = statistics`. Add a tab here.
- `detail_header.dart` — `BusinessDetailHeader`: thin wrapper over `SectionTabs`.
- `business_avatar.dart` — `BusinessAvatar`: logo or gradient initial.
- `statistics/_statistics.dart` — `BusinessStatisticsTab` (default).
- `employees/_employees.dart` — `BusinessEmployeesTab`: reads `BusinessService.employees`.
- `branches/_branches.dart` — `BusinessBranchesTab`.
- `location/_location.dart` — `BusinessLocationTab`: reads `BusinessLocationService`, opens `showLocationForm`, writes it.
- `location/location_details.dart` — `BusinessLocationDetails`: the address block (country included) and the map point block, built from `settings/profile_*` rows.
- `delivery/_delivery.dart` — `BusinessDeliveryTab`: reads `BusinessDeliveryService`; owns every write the blocks and panels ask for.
- `delivery/delivery_settings.dart` — `DeliverySettingsBlock`: the two three-state flags (`SettingsSelect` + `showSelectMenu`) and the delivery note.
- `delivery/delivery_options.dart` — `DeliveryOptionsBlock`: the options, adding in the block title, the "turned off" notice. `limit = 20`.
- `delivery/delivery_option_field.dart` — `DeliveryOptionField`: one option, its mode/reach line and its figures as `SettingsTag`s.
- `delivery/delivery_format.dart` — `deliveryOptionName` `deliveryAmount` `deliveryFeeLabel` `deliveryEtaLabel`
  `deliveryRadiusLabel` `deliveryZonesLabel` `deliveryNumber`. **Every figure of the delivery tab goes through it.**
- `clients/_clients.dart` — `BusinessClientsTab`.

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
- `profile_select.dart` — `ProfileSelectField`: `SelectInput` row edited in place (sector, language, currency).
- `profile_tag.dart` — `ProfileTag`: state chip.
- `country_flag.dart` — `CountryFlag`.

## Conventions

- New profile datum: `BusinessProfileModel` → a `ProfileField` row in the right `ProfileBlock` →
  its key in `BusinessField` (`lib/screens/modals/business/edit_business_field/business_field.dart`).
- Country/currency/language values come from the catalog services, never hardcoded.
- **`delivers`/`pickup` are three-state**: `null` is "has not said" and never "no", so the tab offers three
  answers and not a switch. A company with options that never said reads `true` (the backend measures it).
- **Where the business is lives in the location tab, not in settings**: street, city, region, postal code,
  country and the map point are one form, saved together. The settings sheet is who the business *is*.
- `address` and `country` are `companies` columns `PUT /business/profile/` can also write, but this app writes
  them only from the location panel. After a `COUNTRY` write the tab rereads the profile
  (`BusinessService.refreshProfile`) — the delivery tab checks its carriers against it; nothing outside the
  location reads `address`.
- The country also sets the clock and the payment rails, so the backend hands that one key of
  `PUT /business/location/` to the company's own write (`Business.update`).
- A delivery carrier is checked against the company's country **on write**, so an edit resends
  `MODE`/`PROVIDER` only when they changed (a company that moved could not edit its old option otherwise).
- `BusinessLocationService`/`BusinessDeliveryService` are provided by `_business_detail.dart`, not app-wide:
  switching tabs keeps what was read, switching business remounts the page and drops it.
