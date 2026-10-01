# Spec: business (company, site, settings, catalogues)

**Plan** §1 principle 3, §2, §7.5. **App today** `business/business_service.dart`,
`business_profile_model.dart`, `business_location_*`, `business_branches_service.dart`,
`catalog/*`, `files/*`.

A master holds **one company at one site** (plan D6). The company is created at setup; it is
never created, switched or deleted from the business screens.

---

## business.company

### Data

The fields of `BusinessProfileModel`, minus what needs the internet:

| Field | Type | Written by |
|---|---|---|
| `id` | uuid | setup |
| `name`, `legalName`, `nickname`, `caption` | string | `business.settings.edit` |
| `logo` | fileId? | `business.settings.edit_logo` |
| `activity` | code of `BusinessActivity` | `business.settings.edit` |
| `taxId` | string | `business.settings.edit` |
| `country` | ISO 3166-1 alpha-2 | setup; `business.settings.edit` (see B-4) |
| `language` | code | `business.settings.edit` |
| `currency` | ISO 4217 | setup only (B-5) |
| `phone`, `website` | string | `business.settings.edit` |
| `incorporationDate` | `YYYY-MM-DD`? | `business.settings.edit` |
| `timezone` | IANA name? | setup (proposed: the master OS zone); `business.settings.edit` (B-9) |
| `verification` | always `untrusted` | nobody (B-6) |
| `emails` | always `[]` | nobody (cloud only) |
| `created` | instant | setup |

### Rules

- **B-1** Setup creates the company with `name`, `country`, `currency`, `language` and
  `timezone`, and the owner account (`session.md`, S-6). It runs once. Afterwards there is no op
  that creates a company (the "create business" entry points are hidden in `local`, plan §7.3).
- **B-2** An edit writes one key at a time, as `BusinessService.editProfile` does today
  (`{KEY: value}`). An empty string clears an optional field. `name` can't be cleared
  (`required`).
- **B-3** `nickname` (the handle) is free text offline: there is no global namespace to be
  unique in. It is only unique within the master, which trivially holds one.
- **B-4** Changing `country` changes which rails, banks and document types the catalogues offer
  (`money.md`), and the default phone plan. It never rewrites stored data.
- **B-5** `currency` (the main currency) is fixed after setup, as in the cloud ("the main currency
  is never written from the app"). Changing it would relabel every price without converting it.
- **B-6** Verification is a cloud process: `local` always answers `untrusted`, and the app shows
  nothing about it (capability gate).
- **B-7** Deleting the company (`business.delete`) doesn't exist offline. Its local equivalent
  is **resetting the master** (admin screen, recovery key required, backup offered first), which
  is outside this spec.
- **B-8** Logo: an image upload (see `protocol-v1.md`, files), at most 5 MB, `png`/`jpeg`/`webp`.
  The engine keeps the original and a 256 px square version. Replacing it keeps the old file
  until the next backup rotation, then drops it. *Built so far:* `business.setLogo` takes the
  account's own `logo` upload and makes it readable with `business.view`; the one it replaces
  goes back to the orphan sweep (1 hour), since backups don't exist before phase 5. No 256 px
  version yet, and the app hides the logo change on a master until images are fetched over the
  master's pinned channel (the inventory release, which needs it for product images).
- **B-9** `timezone` is nullable, as in the cloud. `null` means the country's default zone (the
  `countries` catalogue carries one per country). An edit is checked against the IANA list
  (`invalid_timezone`); an empty value clears it. *Built so far:* setup leaves it `null` (Dart
  can't read the OS zone's IANA name on every platform), and the engine checks the name against
  the IANA database it carries since the POS release (`Zones`, which also computes "today").

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `business.profile` | `business.view` | — | the profile | — |
| `business.edit` | `business.settings.edit` | `{KEY: value}` (one key of `BusinessFields.editable`) | the profile | `required`, `invalid_field`, `invalid_timezone`, `bad_request` (not one key) |
| `business.setLogo` | `business.settings.edit_logo` | `{fileId: id \| null}` | the profile | `invalid_file` |

The profile answer: the fields above, `created`, `verification: "untrusted"`, `emails: []`, and
`owner` (whether the reader holds `*`, the app's owner badge). `logo` is a file id. The app's LAN
source maps the screens' keys (`LEGAL_NAME`, `DESCRIPTION`…) onto these.

### Events

| Event | When | Payload |
|---|---|---|
| `business/changed` | any profile field, the logo or the site changed | `{keys: [...]}`, the changed profile keys, or `["site"]`. Clients re-read what they show. Sent to sessions holding `business.view`. |

---

## business.site

The one site this master runs. The app has two screens that write a location: the business
location (`BusinessLocationService`) and the branches list (`BusinessBranchesService`). In
`local` the branches list is hidden (plan §2), and **both sources read and write this one
record**, so the delivery screens, which read the business location, keep working.

### Data

The union of `BusinessLocationModel` and `BusinessBranchModel`:

`name, legalName, taxId, phone, address, landmark, city, region, postalCode, country, latitude,
longitude, storefront, online`. `main` is always `true`. `maps` (a map link) is derived from the
point and never stored.

### Rules

- **B-10** Edits carry **only what changed** (the app's request builders already do). A key with
  `null` (location) or `""` (branch form) clears the field.
- **B-11** A point is both coordinates or neither. Half a point is refused (`invalid_point`).
  Coordinates are stored at 6 decimals. Latitude is in [-90, 90], longitude in [-180, 180].
- **B-12** `country` sent in a location write is the **company's** country (as today: "the backend
  hands that one key to the company's own write"), so it goes through B-4.
- **B-13** There is no place search offline (`BusinessPlacesService` answers `unavailable`, which
  the form already treats as "type the address yourself").
- **B-14** The answer carries `main: true` and the company's `country`; a point comes back in
  degrees at 6 decimals (stored in millionths). *Not reachable from a screen yet:* no page of the
  app writes the location today (in the cloud the main branch is edited in the branches tab,
  hidden on a master); a site form on the business settings is a follow-up.

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `business.site.get` | `business.view` | — | the site | — |
| `business.site.edit` | `business.settings.edit` | changed keys | the site | `invalid_point`, `invalid_field` |

`BusinessLocationService` maps `GET`/`PUT /business/location/` onto these. `BusinessBranchesService`
is not reachable in `local`; in `hybrid` it lists the cloud's branches with the master's own site
marked, and only the site can be edited while offline.

---

## Catalogues and vocabularies

Read-only data the app already takes from the server. Offline it comes from the snapshot
bundled with the release: `Catalogs` in `lyra_protocol` (plan §7.5), which the engine serves and the
app reads before any master exists (the setup form). The master serves **its own copy**, so every
client of one master sees the same version even if clients run different builds. Built so far:
`countries` and `currencies` (each with the columns the cloud's `/init` rows carry, `flag` null,
countries with their `timezone`), plus the vocabularies the engine checks (`languages`,
`activities`). The others arrive with the domain that reads them.

| Catalogue | App reader today | Used by |
|---|---|---|
| `countries` | `CountryCatalogService` | bootstrap, forms |
| `currencies` | `CurrencyCatalogService` | bootstrap, money formatting, minor units |
| `phone_plans` | `PhonePlan` | phone inputs |
| `money.concepts` (in / out, with `ticket`, `settles`) | `MoneyCatalogService` | `money.md` |
| `money.settlements` (with `reference`, `change`, `default`, and a new `credit` flag) | `MoneyCatalogService`, `PosMethodsService` | `pos.md`, `money.md` |
| `money.rails` per country, with requirement sheets (`fields`) | `MoneyMethodsService.rails` | `money.md` |
| `money.options` (`banks`, `documents`, `networks`) per country | `MoneyMethodsService.options` | `money.md` |
| `sales.stages`, `sales.handover` | `SalesCatalogService` | `sales.md` |
| `sales.channels` | `SalesCatalogService` (from `/pos/methods`) | `sales.md` (offline: `pos` only) |
| `stock.reasons` | `StockReason` (hard-coded in the app today) | `stock.md` |
| `delivery.providers` per country | `BusinessDeliveryService` | `deliveries.md` |
| `common_passwords` | none | `session.md` S-2 |

### Rules

- **B-20** A catalogue answer has the same shape the app reads today, so the cloud and LAN
  sources share the model parsing.
- **B-21** Each catalogue carries `version` (the release that built it). The diagnostics screen
  shows it. In `hybrid`, the master refreshes catalogues from the cloud when online and keeps
  the newer one.
- **B-22** Texts in catalogues (`name` of a concept, a stage, a rail) are in the company
  `language`. The snapshot holds every language the app ships.

### Ops

`catalog.get` · session · `name` (one of the table above) · `{version, items}` · `not_found` for a
catalogue this release doesn't carry.

---

## Differences from cloud

- No company creation, switching or deletion; no verification; no company e-mails.
- One site instead of a branches list.
- No place search and no map link lookup; a map link is still derived from the stored point.
- Catalogues are as fresh as the master's app release (`local`), or the last cloud refresh
  (`hybrid`).

## Open questions

1. ~~Time zone in the cloud.~~ Answered: the cloud stores `timezone` on the company (profile
   `GET`/`PUT`, `TIMEZONE` on create and edit), nullable, falling back to the country's default
   zone (B-9). It syncs like any other profile key.
2. The `credit` flag on settlement kinds. *Deferred with credit itself* (`money.md`,
   money.receivable). Proposal kept: the vocabulary gets `credit: true` on `account`, and the
   engine reads the flag (README, vocabularies).
