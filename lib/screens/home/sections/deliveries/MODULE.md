# Module: deliveries section

**Path** `lib/screens/home/sections/deliveries`
**Role** Content of the `deliveries` home section (`/home/deliveries`, top side-bar group, below
messages): a header, then pending deliveries (1/3) and a map (2/3). Sub-pages `settings/` (`/home/deliveries/settings`):
how the company delivers, and `area/` (`/home/deliveries/area`, opened from settings): where, drawn on the map (both moved from the business page).
**Services** `BusinessLocationService` (`lib/services/business`), `MapTilesService` (`lib/services/maps`) — created and provided by `_deliveries.dart`. `BusinessDeliveryService` — created and provided by `settings/_settings.dart`. `DeliveryAreasService` + its own location/tiles services — created and provided by `area/_area.dart`.
**Backend** `GET /business/location/` (map center), `/business/delivery/{,options,providers}/` (settings), `/business/delivery/areas/` (areas); in `hybrid` the settings and areas are the master's (`delivery.*`, `DeliveryLanSource`), `POST /scorpius/v1/isochrone` (travel-time outline), `/scorpius/v1` (tilesets, server-drawn raster tiles). No deliveries endpoint yet: the list is a placeholder.
**Packages** `flutter_map` + `latlong2` (raster `TileLayer`, light/dark by the app's brightness).

## Files

- `_deliveries.dart` — `DeliveriesSection`: header over a two-panel row; loads the business location and the maps, owns the `MapController`.
- `deliveries_header.dart` — `DeliveriesHeader`: title + New delivery (coming soon) + Settings (opens `DeliverySettingsSection.path`).
- `pending_list.dart` — `PendingDeliveriesPanel`: coming-soon `SectionMessage` until the endpoint exists.
- `deliveries_map.dart` — `DeliveriesMap({controller, layers, overlays, onTap, center, zoomButtons})`: server-drawn map of the tileset holding the business point (or `center`, read on mount), centered on it and marking the business point (tileset center without one), OSM attribution; loading / error + retry / no maps on the server → coming soon. `layers` go under the business mark, `overlays` over it. `zoomButtons`: +/- buttons (`widgets/map_zoom_buttons.dart` — `MapZoomButtons`), mouse-wheel zoom off.
- `sub_page.dart` — `DeliveriesSubPage({title, backPath, backLabel, child, actions})`: frame of every sub-page (back arrow + title + actions, line, body on one surface).
- `settings/_settings.dart` — `DeliverySettingsSection` (`routeKey = "deliveries_settings"`, `path`, `parents: ["deliveries"]`): `DeliveriesSubPage` over the body; owns `BusinessDeliveryService`.
- `settings/settings_body.dart` — `DeliverySettingsBody`: reads `BusinessDeliveryService`; owns every write the blocks and panels ask for.
- `settings/delivery_settings.dart` — `DeliverySettingsBlock`: the two three-state flags (`SettingsSelect` + `showSelectMenu`), the delivery note, "Select delivery area" beside the delivers flag (`onArea`), and fixed/flexible areas (`meeting`, two-state, `onMeeting`). Its rows: `settings/delivery_flag_field.dart` — `DeliveryFlagField`,
  `settings/delivery_meeting_field.dart` — `DeliveryMeetingField`, `settings/delivery_area_button.dart` — `DeliveryAreaButton`.
- `settings/delivery_options.dart` — `DeliveryOptionsBlock`: the options, adding in the block title, the "turned off" notice. `limit = 20`.
- `settings/delivery_option_field.dart` — `DeliveryOptionField`: one option, its mode/reach line and its figures as `SettingsTag`s.
- `settings/delivery_format.dart` — `deliveryOptionName` `deliveryAmount` `deliveryFeeLabel` `deliveryEtaLabel`
  `deliveryRadiusLabel` `deliveryZonesLabel` `deliveryNumber`. **Every figure of the delivery settings goes through it.**
- `area/_area.dart` — `DeliveryAreaSection` (`routeKey = "deliveries_area"`, `path`, `parents: ["deliveries"]`): `DeliveriesSubPage` back to settings with "Add area"; owns the services, the `MapController` and the `AreaEditor`; where a new area starts (business point → map center → tileset center).
- `area/area_body.dart` — `DeliveryAreaBody`: loading / error + retry; left panel (list or editor, 1/3) + `DeliveriesMap` (2/3) with the area layers; remove asks first.
- `area/state/area_editor.dart` — `AreaEditor` (`ChangeNotifier`) + `AreaMethod {radius, draw, travel}`: looking (map tap = probe) or shaping (tap moves the center / adds a point); points, drag, insert, remove, undo; fits the map.
- `area/widgets/add_area_button.dart` — `AddAreaButton`: header button, `showSelectMenu` of the three methods.
- `area/widgets/area_list.dart` — `AreaList`: probe result (`area_probe.dart` — `AreaProbe`), empty state, one `AreaTile` per area
  (`area_tile.dart`: colour, shape + km², fee/minimum/paused tags, edit/pause/remove).
- `area/widgets/area_editor_panel.dart` — `AreaEditorPanel` (keyed by `AreaEditor.session`): method tools (km + presets / point tools / travel mode + minutes → outline), name, fee, minimum; builds the request and saves. `area/widgets/area_tool_chip.dart` — `AreaToolChip` (a small tool action).
- `area/widgets/area_layers.dart` — `areaColor`, `areaLayers` (saved areas, paused dashed; the draft), `areaOverlays` (handles, probe pin). `area/widgets/area_handle.dart` — `AreaHandle` (drag over the map), `AreaHandleDot`.

## Conventions

- **`delivers`/`pickup` are three-state**: `null` is "has not said" and never "no", so the settings offer three
  answers and not a switch. A company with options that never said reads `true` (the backend measures it).
- **`meeting` (flexible areas) is two-state and off by default**, unlike `delivers`/`pickup`: the backend refuses
  it empty. It is company-wide, not per option, and only works with drawn areas (the backend picks the spot inside them).
- **An area is saved as geometry, never as a route**: a travel-time area is the isochrone's outline the company
  confirmed, stored as a polygon (the backend decides with `Geometry`, and routing results are not stored).
- `AreaEditor`'s ceilings are the backend's own figures (`DeliveryAreas` in lyra): radius 0.01–1000 km, 3–250 points,
  20 areas per company. Narrowing one here refuses a shape the server would have taken.
- An area's colour is its index in `chart.series`: the list and the map must call `areaColor` with the same index.
- An `AreaHandle` claims the pointer with `EagerGestureRecognizer`; without it the map's drag wins and pans under the point.
- A delivery carrier is checked against the company's country **on write**, so an edit resends
  `MODE`/`PROVIDER` only when they changed (a company that moved could not edit its old option otherwise).
