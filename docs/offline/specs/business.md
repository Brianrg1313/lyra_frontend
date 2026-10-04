# Spec: business (company, site, settings, catalogues)

**Plan** §1 principle 3, §2, §7.5. **App today** `business/business_service.dart`,
`business_profile_model.dart`, `business_location_*`, `business_branches_service.dart`,
`catalog/*`, `files/*`.

A master holds **one company at one site** (plan D6). The company is created once, at setup or
right after it from the welcome; it is never switched or deleted from the business screens.

---

## business.company

### Data

The fields of `BusinessProfileModel`, minus what needs the internet:

| Field | Type | Written by |
|---|---|---|
| `id` | uuid | setup |
| `name`, `legalName`, `nickname`, `caption` | string | `business.edit` |
| `logo` | fileId? | `business.edit` |
| `activity` | code of `BusinessActivity` | `business.edit` |
| `taxId` | string | `business.edit` |
| `country` | ISO 3166-1 alpha-2 | setup; `business.edit` (see B-4) |
| `language` | code | `business.edit` |
| `currency` | ISO 4217 | setup only (B-5) |
| `phone`, `website` | string | `business.edit` |
| `incorporationDate` | `YYYY-MM-DD`? | `business.edit` |
| `timezone` | IANA name? | setup (proposed: the master OS zone); `business.edit` (B-9) |
| `verification` | always `untrusted` | nobody (B-6) |
| `emails` | always `[]` | nobody (cloud only) |
| `created` | instant | setup |
| `cloudId` | the cloud company's id? | setup or `business.create` from the cloud; `business.link` (B-30) |

### Rules

- **B-1** The company is created with `name`, `country`, `currency`, `language`, `timezone` and
  optionally `activity`, once. Setup makes the owner account (`session.md`, S-6) and either the
  company with it or none: the sign in's "Create Master Server" leaves it to the welcome, which
  creates it with `business.create`, as the cloud's welcome does. That op is the owner's alone and
  answers `company_exists` once there is one. The business screens' "create business" entry points
  stay hidden in `local` (plan §7.3).
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
  account's own `logo` upload and makes it readable by every member; the one it replaces
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
| `business.create` | owner (`*`) | `{name, country, currency, language, timezone?, activity?, cloudId?}` | the company as `session.bootstrap` lists it | `required`, `invalid_field`, `forbidden`, `company_exists` |
| `business.profile` | `business` | — | the profile | — |
| `business.edit` | `business.edit` | `{KEY: value}` (one key of `BusinessFields.editable`) | the profile | `required`, `invalid_field`, `invalid_timezone`, `bad_request` (not one key) |
| `business.setLogo` | `business.edit` | `{fileId: id \| null}` | the profile | `invalid_file` |
| `business.link` | owner (`*`) | `{cloudId}` | the company as `session.bootstrap` lists it | `invalid_field`, `forbidden`, `not_found` (no company), `already_linked` |

The profile answer: the fields above, `created`, `verification: "untrusted"`, `emails: []`, and
`owner` (whether the reader holds `*`, the app's owner badge). `logo` is a file id. The app's LAN
source maps the screens' keys (`LEGAL_NAME`, `DESCRIPTION`…) onto these.

### Events

| Event | When | Payload |
|---|---|---|
| `business/changed` | any profile field, the logo or the site changed | `{keys: [...]}`, the changed profile keys, or `["site"]`. Clients re-read what they show. Sent to every member's sessions, as every member sees the name and logo. |

---

## business.link

The company of a master and the cloud's are one company in two homes (plan §9.6, D15): the master
keeps the cloud company's id, so a device signed in online reaches the cloud-only areas (messages,
channels) of the same company, and the edge sync (phase 6) knows what to keep equal.

### Rules

- **B-30** `cloudId` is set when the master is created from the cloud (setup or `business.create`
  carry it), or later by the owner with `business.link`, which the app asks once at an online sign
  in on a device with an unlinked master (plan D18); when the account manages no cloud company, the app makes
  one from the master's profile (`business/create`) and links it without asking. The bootstrap's company carries it (`cloudId`,
  null while unlinked).
- **B-31** It is written once. The same id again answers as the first time; another one is
  refused (`already_linked`): the master's data would otherwise be joined to a second company.
  Unlinking is resetting the master (B-7). The write is audited (`company.linked`), logged in the
  oplog and announced by `business/changed {keys: ["cloudId"]}`.
- **B-32** The engine can't check, without the internet, that the account owns that cloud company;
  the app links only a company its cloud session lists as the owner's. The cloud grant (§9.6,
  phase 4b E3) will carry the company id signed by the backend, checked against the link.

---

## business.sync

A linked master syncs with its cloud company once it is enrolled with the backend
(`docs/task-edge-sync-backend.md` §1, plan §9.2). Nobody fills a form for it: the app does it by
itself, on a device signed in online as the owner, the first time the company is linked and the
internet answers.

### Rules

- **B-33** `sync.prepare` answers `{publicKey, instance, engine, name}`: the master's edge key (made
  once, kept sealed until enrolled), its installation id, the engine's version and the computer's
  name (the company's when it has none). The app sends them to `POST /edge/v1/devices` with the
  owner's session. Only the owner prepares or enrols, as only the owner may online.
- **B-34** `sync.enroll` takes the backend's answer as it came (`device`, `company`, `site`,
  `edgeKey`, `allowance`, `endpoint`), checked: the endpoint https, the key 32 bytes, the company the
  one the master is linked to (`not_linked`, `company_mismatch`). The master syncs from its next
  cycle. Audited (`sync.enrolled`); answers `sync.status`.
- **B-35** `sync.status` (`server`): `{enrolled: false}`, or `{enrolled, device, phase, allowance,
  revoked, lastSync, lastError, pending, conflicts, rejected}`.
- **B-36** The app never enrols again by itself a master the cloud revoked: unlinking it was
  someone's decision. The server section says so and lets the owner enrol it again, which, like a
  branch whose server is another (`site_has_master`), asks once whether this server replaces that one.

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
| `business.site.get` | `business` | — | the site | — |
| `business.site.edit` | `business.edit` | changed keys | the site | `invalid_point`, `invalid_field` |

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
