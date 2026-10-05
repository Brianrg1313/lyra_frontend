# Spec: deliveries (settings, options, areas)

**Plan** §2 (deliveries rows). **App today** `business/business_delivery_*`,
`business/delivery_area*`, `screens/home/sections/deliveries`, `docs/app-areas.json`
(`deliveries.*`).

How the company gets orders to customers: whether it delivers or offers pickup, the delivery
options (own riders, a platform, a courier) and the areas it covers with their fees.

**Locked in `local`** (decided 2026-09-30). Today the readers are the AI channels (they quote
delivery to customers) and the future deliveries list, and neither exists in `local`. So the
section is locked there, like any cloud-only area (D17). This spec applies to **`hybrid`**: the
master keeps the company's delivery settings and areas, they can be edited while offline, and
they sync (`task-edge-sync-backend.md` §11: the settings on `company`, `delivery_option`,
`delivery_area`).

**Units on the wire.** Money is in minor units of the company's currency, a radius in metres (to
the 10 m the cloud's two decimals of a kilometre keep), times in minutes, a point in degrees
(stored in millionths). The app's `DeliveryLanSource` converts both ways.

---

## delivery.settings

### Data

`delivers: bool?`, `pickup: bool?` (three states: yes, no, not said), `meeting: bool`, `notes:
string?`, `currency` (the main one), `options: [option]`. The settings live on the company, as in
the cloud.

**Option** `{id, mode: own|platform|courier, provider?, providerName?, icon (null), label?,
coverage: local|national|international, radius?, zones: [{name, fee?}], fee?, freeFrom?, etaMin?,
etaMax?, notes?, position}`.

### Rules

- **D-1** `delivery.set` takes any of `delivers`, `pickup`, `meeting`, `notes`; `null` sets a flag
  back to "not said" and clears the notes; `meeting` has no third state (`invalid_delivery_flag`).
  `delivers` is answered `true` when the company never said and lists an option, without being
  written.
- **D-2** A `provider` is a code of the carriers' catalogue offered in the company's country
  (`lyra_node` `Carriers`, the cloud's as of 2026-09; `invalid_delivery_provider`), and it decides
  the mode (`delivery_provider_mismatch` when `mode` says otherwise). A carrier the catalogue lacks
  is named by `label` alone; a `platform` or `courier` with neither is `delivery_provider_required`.
  `own` never has one (it is dropped). Changing the mode drops a carrier of the other kind.
- **D-3** `coverage` defaults to `national` for `courier` and `local` for the others.
- **D-4** `radius` (10 m to 1000 km) and `zones` (at most 100, 80 characters each, the same name
  twice kept once) only mean something on a `local` option. Off `local` they are dropped. On an
  edit, an empty `zones` clears them.
- **D-5** Money (`fee`, `freeFrom`, zone fees) is ≥ 0 (`invalid_delivery_fee`). `etaMin ≤ etaMax`,
  1 to 43200 minutes (`invalid_delivery_eta`). `position` 0 to 65535 (`invalid_order`).
- **D-6** On an edit a key left out keeps its value and `null` clears it; the result is checked
  whole. The app sends `mode` and `provider` only when they changed.
- **D-7** `label` (64), `notes` (255) and the settings' notes (255) take the cloud's characters
  (`LABEL`, `NOTES` rules); anything else is `invalid_field`. At most 20 options
  (`delivery_options_limit`). Removing is soft.

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `delivery.get` | `delivery` | — | settings | — |
| `delivery.set` | `delivery.edit` | any of `delivers`, `pickup`, `meeting`, `notes` | settings | `invalid_delivery_flag`, `invalid_field` |
| `delivery.options.create` | `delivery.create` | `mode`, `provider`, `label`, `coverage`, `radius`, `zones`, `fee`, `freeFrom`, `etaMin`, `etaMax`, `notes`, `position` | settings | D-2 to D-7 codes |
| `delivery.options.edit` | `delivery.edit` | `id` and the create's keys | settings | `not_found`, D-2 to D-7 codes |
| `delivery.options.remove` | `delivery.delete` | `id` | settings | `not_found` |
| `delivery.providers` | `delivery` | — | `{country, modes, coverages, providers: [{code, name, kind, scope, icon}]}` | — |

---

## delivery.area

### Data

`area {id, name, kind: radius|polygon, latitude?, longitude?, radius?, polygon: [[latitude,
longitude]], fee?, minimum?, active, position}` and the list's `currency`.

### Rules

- **D-10** `radius` areas have a center and a radius (10 m to 1000 km;
  `invalid_delivery_area_center`, `invalid_delivery_radius`). `polygon` areas have 3 to 250
  points, as pairs or `{latitude, longitude}`; a point repeated where it was drawn twice and the
  closing point are dropped (`invalid_delivery_area_polygon`). Coordinates at 6 decimals. Each kind
  keeps only its own shape. The cloud doesn't refuse an outline that crosses itself, so neither
  does the master.
- **D-11** At most 20 areas (`delivery_areas_limit`). `name` is required, up to 64 characters.
- **D-12** `holding(point)`: the active areas containing a point, cheapest first. It is the app's
  probe (`DeliveryAreasModel.holding`); the master doesn't answer it.
- **D-13** `{id, active}` alone pauses or resumes; `null` is active. Removing is soft on both sides
  (nothing refers to an area).
- **D-14** The travel-time outline (isochrone) is the cloud's routing engine: the app asks the
  cloud while it answers, and without it the editor draws by radius or by points.

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `delivery.areas.list` | `delivery` | — | `{currency, areas}` | — |
| `delivery.areas.create` | `delivery.create` | `name`, `kind`, `latitude`, `longitude`, `radius`, `polygon`, `fee`, `minimum`, `active`, `position` | list | D-10, D-11 codes |
| `delivery.areas.edit` | `delivery.edit` | `id` and the create's keys | list | `not_found`, D-10 codes |
| `delivery.areas.remove` | `delivery.delete` | `id` | list | `not_found` |

The permissions are the cloud catalogue's keys, as its routes take them (`session.md` P-4).

---

## Differences from cloud

- No base map tiles, no travel shapes (isochrone), no routes without the internet. The settings
  work whole; the areas list, pause and remove, but drawing one needs the map (Open question 3).
- Carrier icons are the cloud's files: `icon` is always null on a master.

## Open questions

1. ~~Hide in `local`?~~ Decided: locked in `local`, available in `hybrid`.
2. ~~Is a courier's `provider` always from the catalogue?~~ As the cloud: a catalogue code, or
   none and the carrier named by `label`.
3. Without map tiles, how is a polygon drawn? Options: a plain canvas with the site's pin and a
   scale bar; typing coordinates; or waiting for the offline tile pack (plan §14).

## Release status

The deliveries release (2026-10-04) serves every op above (D-1 to D-14) and syncs them: the
settings as four fields of `company` (`delivers`, `pickup`, `meetingPoint`, `deliveryNotes`), and
`delivery_option` and `delivery_area` (an empty `zones` or `polygon` travels as null). In the app
the three `deliveries` areas are served by the master in `hybrid`, with or without the internet.
