# Spec: deliveries (settings, options, areas)

**Plan** §2 (deliveries rows). **App today** `business/business_delivery_*`,
`business/delivery_area*`, `screens/home/sections/deliveries`, `docs/app-areas.json`
(`deliveries.*`).

How the company gets orders to customers: whether it delivers or offers pickup, the delivery
options (own riders, a platform, a courier) and the areas it covers with their fees.

**Hidden in `local`** (decided 2026-09-30). Today the readers are the AI channels (they quote
delivery to customers) and the future deliveries list, and neither exists in `local`. So the
deliveries section is hidden there, like any cloud-only area. This spec applies to **`hybrid`**:
the master keeps the company's delivery settings and areas, they can be edited while offline,
and they sync.

---

## delivery.settings

### Data

`delivers: bool?`, `pickup: bool?` (three states: yes, no, not said), `meeting: bool`, `notes:
string?`, `currency` (the main one), `options: [option]`.

**Option** `{id, mode: own|platform|courier, provider?, label?, coverage:
local|national|international, radius?, zones: [{name, fee?}], fee?, freeFrom?, etaMin?, etaMax?,
notes?, position}`.

### Rules

- **D-1** Flags travel one at a time (`{DELIVERS: true}`); `null` sets "not said".
- **D-2** `mode` other than `own` must name a `provider` from the providers catalogue for the
  company's country, or free text for `courier` (Open question 2); `own` never has one
  (`provider_not_allowed`).
- **D-3** `coverage` defaults to `national` for `courier` and `local` for the others.
- **D-4** `radius` (km, > 0) and `zones` only mean something on a `local` option. Off `local` they
  are dropped. On an edit of a `local` option, an empty `zones` clears them.
- **D-5** Money (`fee`, `freeFrom`, zone fees) is ≥ 0 in the main currency. `etaMin ≤ etaMax`
  (`invalid_eta`), in minutes.
- **D-6** Changing `mode` or `provider` on an edit is sent only when it changed (the request
  builder already does so); the rest of the option follows the missing-key / `null` rule.

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `delivery.get` | `deliveries.settings.view` | — | `BusinessDeliveryModel` | — |
| `delivery.set` | `deliveries.settings.edit` | one of `DELIVERS`, `PICKUP`, `MEETING_POINT`, `NOTES` | settings | `invalid_field` |
| `delivery.options.create` | `deliveries.settings.edit` | `createDeliveryOptionRequest` | settings | D-2…D-5 codes |
| `delivery.options.edit` | `deliveries.settings.edit` | `updateDeliveryOptionRequest` | settings | `not_found`, D-2…D-5 codes |
| `delivery.options.remove` | `deliveries.settings.edit` | `id` | settings | `not_found` |
| `delivery.providers` | `deliveries.settings.view` | — | `DeliveryCatalog` (from the snapshot) | — |

---

## delivery.area

### Data

`area {id, name, kind: radius|polygon, center?, radius? (m), points: [latlng], fee?, minimum?,
active, position}` and the list's `currency`.

### Rules

- **D-10** `radius` areas have a center and a radius > 0. `polygon` areas have 3 to 250 points
  (`maxRingPoints`), no self-intersection (`invalid_polygon`). Coordinates at 6 decimals.
- **D-11** At most 20 areas (`DeliveryAreasService.limit`, `too_many_areas`).
- **D-12** `holding(point)`: the active areas containing a point, cheapest first; ties by
  `position`. A point on the edge counts as inside. The engine uses the same ray casting as
  `ringContains`, so client and master agree.
- **D-13** `ACTIVE` is toggled alone. Removing is a hard delete (nothing references an area).
- **D-14** `delivery.areas.travelShape` (isochrone) needs the map service: cloud only
  (`needs_internet`).

### Ops

| Op | Permission | Args | Answer | Errors |
|---|---|---|---|---|
| `delivery.areas.list` | `deliveries.areas.view` | — | `DeliveryAreasModel` | — |
| `delivery.areas.create` | `deliveries.areas.create` | `createDeliveryAreaRequest` | list | `invalid_polygon`, `too_many_areas`, `invalid_field` |
| `delivery.areas.edit` | `deliveries.areas.edit` | `updateDeliveryAreaRequest` or `{ID, ACTIVE}` | list | `not_found`, `invalid_polygon` |
| `delivery.areas.remove` | `deliveries.areas.delete` | `id` | list | `not_found` |

---

## Differences from cloud

- No base map tiles, no travel shapes (isochrone), no routes. Areas are drawn and edited by
  coordinates over whatever the map can show offline (Open question 3).

## Open questions

1. ~~Hide in `local`?~~ Decided: hidden in `local`, available in `hybrid`.
2. Is a courier's `provider` always from the catalogue, or can it be free text?
3. Without map tiles, how is a polygon drawn? Options: a plain canvas with the site's pin and a
   scale bar; typing coordinates; or waiting for the offline tile pack (plan §14).
