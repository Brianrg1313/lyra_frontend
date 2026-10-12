# Module: deliveries section

**Path** `lib/screens/home/sections/deliveries`
**Role** Content of the `deliveries` home section (`/home/deliveries`, top side-bar group, below messages): the map fills the sheet with every branch pinned and the open map's areas drawn (per branch, the other branches' in force grey under them); over its left side the panel (title + settings; where the company delivers: shared map or one per branch, switched there; "Add area" and the open map's areas, or the editor of the one being shaped; then pending deliveries), "New delivery" over its top right. How the company delivers is a side panel over the map (`modals/deliveries/delivery_settings/`), opened from beside the title. No sub-pages.
**Services** `BusinessLocationService` (`lib/services/business`), `MapTilesService` (`lib/services/maps`), `BusinessBranchesService`, `DeliveryAreasService` — created and provided by `_deliveries.dart`, with `BranchesFocus`.
**Backend** `GET /business/location/` (map center), `GET /business/branches/` (pins, per-branch maps), `/business/delivery/{,options,providers}/` (the settings panel's; `DELIVERY_SCOPE`), `/business/delivery/areas/` (areas, `BRANCH`); in `hybrid` the settings and areas are the master's (`delivery.*`, `DeliveryLanSource`), `POST /scorpius/v1/isochrone` (travel-time outline), `/scorpius/v1` (tilesets, server-drawn raster tiles). No deliveries endpoint yet: the pending list is a placeholder.
**Reuses** `BranchMarkers`, `BranchGlyph`, `BranchesFocus` from `business/branches/`.
**Packages** `flutter_map` + `latlong2` (raster `TileLayer`, light/dark by the app's brightness).

## Files

- `_deliveries.dart` — `DeliveriesSection`: one `Surface` sheet: `DeliveriesMap` edge to edge (`areaLayers` of the open map, `areaOverlays`, map tap → `AreaEditor.tap`; `BranchMarkers`, no business mark), `DeliveriesPanel` in a `MapPanel` on its left, `DeliveriesHeader` on its top right; owns the services, the `MapController`, the `AreaEditor` and the open map (`_owner`: null shared; per branch the one picked, else the first); a pin / a branch picked opens its map per branch (not while shaping), else moves the map; limit per map; where a new area starts (open branch's point → business point → map center → tileset center).
- `deliveries_header.dart` — `DeliveriesHeader`: the floating action: New delivery (coming soon).
- `deliveries_panel.dart` — `DeliveriesPanel({editor, owner, origin, onOwner, onAdd})`: title + settings button (`showDeliverySettings`), subtitle; loading (per branch, until the branches are read) / error + retry; looking: `AreaList` with `AreaMapPicker` as header and `AddAreaButton` above the areas, the probe over the areas in force with `deliveringBranch`, remove asks first; line, `PendingDeliveries`. Shaping: `AreaEditorPanel` only.
- `pending_list.dart` — `PendingDeliveries`: one coming-soon line until the endpoint exists.
- `widgets/scope_switch.dart` — `DeliveryScopeSwitch({scope, onChanged})`: shared / per branch halves and what the one on means for an order; `onChanged` null = read only.
- `widgets/map_panel.dart` — `MapPanel`: frame of a panel floating over a map's left side (side bar fill, line, translucent rim); `MapPanel.width(context, sheet)` (25/30/36% desktop/tablet/phone, with a minimum).
- `deliveries_map.dart` — `DeliveriesMap({controller, layers, overlays, onTap, center, zoomButtons, businessMark})`: server-drawn map of the tileset holding the business point (or `center`, read on mount), centered on it and marking the business point (tileset center without one), OSM attribution; loading / error + retry / no maps on the server → coming soon. `layers` go under the business mark, `overlays` over it. `zoomButtons`: +/- buttons (`widgets/map_zoom_buttons.dart` — `MapZoomButtons`), mouse-wheel zoom off. `businessMark: false` leaves the business point unmarked (the branch form).
- `delivery_format.dart` — `deliveryOptionName` `deliveryAmount` `deliveryFeeLabel` `deliveryEtaLabel`
  `deliveryRadiusLabel` `deliveryZonesLabel` `deliveryNumber`. **Every delivery figure (settings panel, areas) goes through it.**
- `area/widgets/area_map_picker.dart` — `AreaMapPicker`: `DeliveryScopeSwitch` and, per branch, the open branch (glyph, count; none = warning colour) unfolding the branches (`showSelectMenu`).
- `area/state/area_editor.dart` — `AreaEditor` (`ChangeNotifier`) + `AreaMethod {radius, draw, travel}`: looking (map tap = probe) or shaping (tap moves the center / adds a point); points, drag, insert, remove, undo; fits the map.
- `area/widgets/add_area_button.dart` — `AddAreaButton`: full-width row above the areas, `showSelectMenu` of the three methods.
- `area/widgets/area_list.dart` — `AreaList({header, add, areas, currency, probe})`: header, probe result or hint (`area_probe.dart` — `AreaProbe`: holding areas in force, cheapest first, and the branch it leaves from), `add`, empty state, one `AreaTile` per area of the open map
  (`area_tile.dart`: colour, shape + km², fee/minimum/paused tags, edit/pause/remove).
- `area/widgets/area_editor_panel.dart` — `AreaEditorPanel` (keyed by `AreaEditor.session`; `branch`: the map a new area goes into): title + method, live shape readout (draft colour, km², radius / points), map hint, method tools (km + presets / point tools / travel mode + minutes → outline), name, fee, minimum; Cancel / Save pinned under the scroll; builds the request and saves. `area/widgets/area_tool_chip.dart` — `AreaToolChip` (a small tool action).
- `area/widgets/area_layers.dart` — `areaColor`, `areaLayers` (the open map's areas, `others` grey under them, the draft), `savedAreaLayers` (saved areas in a given colour, paused dashed), `areaOverlays` (handles, probe pin). `area/widgets/area_handle.dart` — `AreaHandle` (drag over the map), `AreaHandleDot`.

## Conventions

- **`delivers`/`pickup` are three-state**: `null` is "has not said" and never "no", so the settings offer three
  answers and not a switch. A company with options that never said reads `true` (the backend measures it).
- **`meeting` (flexible areas) is two-state and off by default**, unlike `delivers`/`pickup`: the backend refuses
  it empty. It is company-wide, not per option, and only works with drawn areas (the backend picks the spot inside them).
- **An area is saved as geometry, never as a route**: a travel-time area is the isochrone's outline the company
  confirmed, stored as a polygon (the backend decides with `Geometry`, and routing results are not stored).
- `AreaEditor`'s ceilings are the backend's own figures (`DeliveryAreas` in lyra): radius 0.01–1000 km, 3–250 points,
  20 areas per company. Narrowing one here refuses a shape the server would have taken.
- An area's colour is its index in `chart.series` within its map (`of(owner)`): the list, the probe and the map must call `areaColor` with the same index.
- **Both maps are kept**: the shared areas (`branch` null) and each branch's live side by side; `scope` decides which are in force (`inForce`), and nothing here deletes the other set. The ceiling (20) is per map, as the backend's.
- `deliveringBranch` repeats the backend's `Coverage.dispatcher` for the probe; change both or neither.
- An `AreaHandle` claims the pointer with `EagerGestureRecognizer`; without it the map's drag wins and pans under the point.
- A delivery carrier is checked against the company's country **on write**, so an edit resends
  `MODE`/`PROVIDER` only when they changed (a company that moved could not edit its old option otherwise).
