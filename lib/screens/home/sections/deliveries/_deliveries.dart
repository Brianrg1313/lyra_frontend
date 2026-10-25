import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/assistant/assistant_app_tools.dart';
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/business_branches_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/business/business_delivery_service.dart';
import 'package:app/services/business/business_location_service.dart';
import 'package:app/services/business/delivery_area_model.dart';
import 'package:app/services/business/delivery_areas_service.dart';
import 'package:app/services/maps/map_tiles_service.dart';
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/services/shipments/shipments_service.dart';
import 'package:app/toolkit/backend/deployment.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/business/branches/branch_markers.dart';
import 'package:app/screens/home/sections/business/branches/branches_focus.dart';
import 'package:app/screens/home/sections/deliveries/area/state/area_editor.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_layers.dart';
import 'package:app/screens/modals/deliveries/new_shipment/_new_shipment.dart';
import 'package:app/screens/modals/deliveries/shipment/_shipment.dart';

import './deliveries_header.dart';
import './deliveries_map.dart';
import './deliveries_panel.dart';
import './methods/method_list.dart';
import './methods/state/method_flow.dart';
import './shipments/shipment_markers.dart';
import './widgets/map_panel.dart';

/// **The deliveries desk**: the content of the `deliveries` section.
///
/// The map is the sheet, edge to edge, like the business's branches tab: the
/// panel floats over its left side and the actions over its top right corner.
/// Where the company delivers is drawn and edited here, on the one map: the
/// panel lists the map of the branch picked in it ("All branches" the shared
/// one, a branch its own, and picking there puts that one in force) and "New
/// delivery method" ends where a method's areas are shaped on the map. The
/// other areas in force are drawn grey under the open map's, and on the areas
/// a pin picks its branch.
///
/// The branch's deliveries open first: the panel lists them and the map pins
/// where each goes (cloud only, [ShipmentsService]); a tile or a pin opens the
/// shipment's panel.
///
/// The services live here and not app-wide, as on the business page: what
/// they read answers for the active company (and the shipments for the branch
/// worked in), and a business or branch switch remounts the section. The [MapController] and the [AreaEditor] live here because
/// the panel, the map and its pins all move or read them.
class DeliveriesSection extends StatefulWidget {
  const DeliveriesSection({super.key});

  @override
  State<DeliveriesSection> createState() => _DeliveriesSectionState();
}

class _DeliveriesSectionState extends State<DeliveriesSection> {
  final BusinessLocationService _location = BusinessLocationService();
  final MapTilesService _tiles = MapTilesService();
  final BusinessBranchesService _branches = BusinessBranchesService();
  final DeliveryAreasService _areas = DeliveryAreasService();
  final ShipmentsService _shipments = ShipmentsService();
  final BusinessDeliveryService _delivery = BusinessDeliveryService();
  final MethodFlow _flow = MethodFlow();
  final BranchesFocus _focus = BranchesFocus();
  final MapController _map = MapController();
  late final AreaEditor _editor = AreaEditor(map: _map);

  /// The branch the panel is filtered by, `null` for all of them: the one
  /// picked on the board before working in it remounted the desk
  /// ([_carried]), else the one worked in, since the board opens first and
  /// "All branches" lists no shipment (the areas' "all" is a pick away).
  late String? _branch = _takeCarried() ?? (_board ? BranchService().activeId : null);

  /// The branch [_work] switched to, read once by the desk it remounts.
  static String? _carried;

  static String? _takeCarried() {
    final branch = _carried;
    _carried = null;
    return branch;
  }

  /// The panel's search and branch fields, kept here so a flow or an area
  /// being shaped, which hide them, leave them as they were.
  final FormController _filters = FormController();
  late final InputController _search = InputController.search(form: _filters);
  late final InputController _branchPicker = InputController.select(
    form: _filters,
    key: "BRANCH",
    initial: _branch ?? DeliveriesPanel.allBranches
  );

  /// What the search holds, as the panel matches it.
  String _query = "";

  /// The board exists only in the cloud (see [DeliveriesPanel.shipments]).
  final bool _board = Deployment.mode == DeploymentMode.cloud;

  late DeliveriesView _view = _board ? DeliveriesView.shipments : DeliveriesView.areas;

  /// The shipment whose panel was opened last, named on its pin.
  String? _litShipment;

  /// What the map shows, left for the panel's assistant (`app_view`) a moment
  /// after it settles; it outlives the section: «el punto que marqué» is said
  /// from the home's chat, with this section gone.
  Timer? _glancing;
  StreamSubscription<MapEvent>? _moves;

  /// The branch picked, while the company still has it.
  String? get _picked => _branches.branches.any((branch) => branch.id == _branch) ? _branch : null;


  @override
  void initState() {
    super.initState();

    // Deferred: the reads notify, and notifying while mounting rebuilds mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _location.load();
      _tiles.load();
      _branches.load();
      _areas.load();
      if (_board) _shipments.load();
      // The catalog right after: the method cards name its carriers.
      _delivery.load().then((_) => mounted ? _delivery.loadCatalog() : null);
    });

    _editor.addListener(_glance);
    _flow.addListener(_glance);
    _areas.addListener(_glance);
    _branches.addListener(_glance);
    _moves = _map.mapEventStream.listen((_) => _glance());
    _search.textController.addListener(_typed);
  }

  void _typed() {
    final query = _search.text.trim().toLowerCase();

    if (query != _query) setState(() => _query = query);
  }

  @override
  void dispose() {
    _glancing?.cancel();
    _moves?.cancel();
    _editor.dispose();
    _location.dispose();
    _tiles.dispose();
    _branches.dispose();
    _areas.dispose();
    _shipments.dispose();
    _delivery.dispose();
    _flow.dispose();
    _filters.dispose();
    _focus.dispose();
    _map.dispose();

    super.dispose();
  }

  /// A branch picked in the panel (`null`: all of them), or a pin tapped in
  /// the areas view. Not while an area is shaped: it belongs to the map open.
  ///
  /// The board reads the branch worked in and no other, so picking another
  /// one on it works in that one (`BranchService.select`), which remounts the
  /// desk on it; a branch the person may not work in stays picked, and the
  /// panel says why there is no list.
  void _pick(String? branch) {
    if (_editor.isOpen) {
      _showPicked();
      return;
    }

    setState(() => _branch = branch);
    _showPicked();
    _editor.clearProbe();

    if (_view == DeliveriesView.areas) _scopeTo(branch);

    if (branch == null) return;

    if (_view == DeliveriesView.shipments) _work(branch);

    _focus.select(branch);

    final point = _point(branch);

    if (point != null && _tiles.status == MapTilesStatus.ready) {
      final perBranch = _areas.areas?.scope == DeliveryScope.branch;

      _map.move(point, perBranch ? _map.camera.zoom : DeliveriesMap.businessZoom);
    }
  }

  /// A pin tapped: on the board it only moves the map (a tap is no reason to
  /// change the branch worked in); on the areas it picks its branch.
  void _open(String branch) {
    if (_view == DeliveriesView.areas || _editor.isOpen) {
      _pick(branch);
      return;
    }

    final point = _point(branch);

    _focus.select(branch);
    if (point != null && _tiles.status == MapTilesStatus.ready) _map.move(point, _map.camera.zoom);
  }

  /// On the areas the branch field is the scope: the map picked is put in
  /// force ("All branches" the shared one).
  void _scopeTo(String? branch) {
    final scope = DeliveriesPanel.scopeOf(branch);

    if (_areas.areas == null || _areas.areas!.scope == scope || _areas.isWriting) return;

    _areas.setScope(context, scope);
  }

  /// Works in [branch] when the board is not its (see [_pick]).
  void _work(String branch) {
    final working = BranchService();

    if (!_board || branch == working.activeId || working.byId(branch) == null) return;

    _carried = branch;
    working.select(branch);
  }

  /// Writes [_branch] into the panel's field.
  void _showPicked() {
    final value = _branch ?? DeliveriesPanel.allBranches;

    if (_branchPicker.selectedValue == value) return;

    _branchPicker.selectedValue = value;
    _branchPicker.textController.text = value == DeliveriesPanel.allBranches
      ? S.of(context).deliveries_branch_all
      : _branches.branches.where((branch) => branch.id == value).firstOrNull?.name ?? "";
  }

  /// "New delivery method": the panel turns into its steps, unless the
  /// company already has as many as it may.
  void _newMethod() {
    final count = _delivery.delivery?.options.length ?? 0;

    if (count >= MethodList.limit) {
      FloatFlag.of(context).alert(message: S.of(context).deliveries_method_limit(MethodList.limit));
      return;
    }

    _flow.start();
  }

  /// Whether a tap on the map is the areas': while they are listed (their view,
  /// or the last step of a new method) or one is shaped.
  bool get _tappable => _editor.isOpen || (_flow.isOpen
    ? _flow.step == MethodStep.areas
    : _view == DeliveriesView.areas);

  /// Shows [view]; the areas drop the probe a shipment view has no use for,
  /// and the search, which matched the other view's rows, is emptied. The
  /// board on a branch other than the one worked in works in it (see [_pick]).
  void _show(DeliveriesView view) {
    if (view == _view) return;

    _editor.clearProbe();
    _search.textController.clear();
    setState(() => _view = view);
    _glance();

    if (view != DeliveriesView.shipments) return;

    // Back on the board from "All branches": the branch worked in, whose list it is.
    final working = BranchService().activeId;
    if (_branch == null && working != null) {
      setState(() => _branch = working);
      _showPicked();
      return;
    }

    final branch = _branch;
    if (branch != null) _work(branch);
  }

  void _glance() {
    _glancing?.cancel();
    _glancing = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final MapCamera camera;

      try {
        camera = _map.camera;
      } catch (_) {
        return; // Not drawn yet: nothing to tell
      }

      final owner = _picked;
      final editing = _editor.editing;
      final probe = _editor.probe;
      Map<String, double> point(LatLng at) => {"latitude": _round(at.latitude), "longitude": _round(at.longitude)};

      AssistantAppTools.instance.glance("deliveries", {
        "view": _view.name,
        "adding_method": ?_flow.step?.name,
        "center": point(camera.center),
        "zoom": double.parse(camera.zoom.toStringAsFixed(1)),
        "tapped": ?(probe == null ? null : point(probe)),
        "scope": _areas.areas?.scope.name,
        "branch": owner == null ? null : {
          "id": owner,
          "name": ?_branches.branches.where((branch) => branch.id == owner).firstOrNull?.name
        },
        if (_editor.isOpen) "editing": {
          "method": _editor.method.name,
          "area": ?(editing == null ? null : {"id": editing.id, "name": editing.name}),
          "center": ?(_editor.center == null ? null : point(_editor.center!))
        }
      });
    });
  }

  /// A coordinate at the 6 decimals the backend keeps.
  static double _round(double value) => double.parse(value.toStringAsFixed(6));

  /// Opens [shipment]'s panel, moving the map to where it goes.
  Future<void> _openShipment(Shipment shipment) async {
    setState(() => _litShipment = shipment.id);

    final destination = shipment.destination;

    if (destination case ShipmentDestination(:final double latitude, :final double longitude)
        when _tiles.status == MapTilesStatus.ready) {
      _map.move(LatLng(latitude, longitude), _map.camera.zoom);
    }

    await showShipment(context, service: _shipments, id: shipment.id);
  }

  /// "New delivery": a sale sent as a delivery lands on the board, which comes
  /// to the front, and its panel opens for who carries it and when — unless
  /// showing the board moves the desk to another branch (it remounts).
  Future<void> _addShipment() async {
    final shipment = await showNewShipment(context, service: _shipments);
    if (shipment == null || !mounted) return;

    final branch = _branch;
    final stays = branch == null || branch == BranchService().activeId;

    _show(DeliveriesView.shipments);
    if (stays && mounted) await _openShipment(shipment);
  }

  /// Starts a new area, unless the list is not there to add it to, or full.
  void _start(AreaMethod method) {
    final areas = _areas.areas;
    if (_areas.status != DeliveryAreasStatus.ready || areas == null) {
      FloatFlag.of(context).alert(message: S.of(context).deliveries_area_not_ready);
      return;
    }

    if (areas.of(_picked).length >= DeliveryAreasService.limit) {
      FloatFlag.of(context).alert(
        message: S.of(context).deliveries_area_limit(DeliveryAreasService.limit)
      );
      return;
    }

    _editor.start(method, _origin());
  }

  /// A branch's point, or `null` when it has none.
  LatLng? _point(String? id) {
    for (final branch in _branches.branches) {
      if (branch case BusinessBranchModel(:final double latitude, :final double longitude) when branch.id == id) {
        return LatLng(latitude, longitude);
      }
    }

    return null;
  }

  /// Where an area starts: the open branch's point, else the company's, else
  /// the middle of the map on screen, else the middle of the map the server
  /// holds.
  LatLng _origin() {
    final branch = _point(_picked);

    if (branch != null) return branch;

    final location = _location.location;

    if (location != null && location.hasPoint) {
      return LatLng(location.latitude!, location.longitude!);
    }

    try {
      return _map.camera.center;
    } catch (_) {
      final tileset = _tiles.tilesetFor(null, null);

      return tileset == null
        ? const LatLng(0, 0)
        : LatLng(tileset.centerLatitude, tileset.centerLongitude);
    }
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<BusinessLocationService>.value(value: _location),
      ChangeNotifierProvider<MapTilesService>.value(value: _tiles),
      ChangeNotifierProvider<BusinessBranchesService>.value(value: _branches),
      ChangeNotifierProvider<DeliveryAreasService>.value(value: _areas),
      ChangeNotifierProvider<ShipmentsService>.value(value: _shipments),
      ChangeNotifierProvider<BusinessDeliveryService>.value(value: _delivery),
      ChangeNotifierProvider<BranchesFocus>.value(value: _focus)
    ],
    child: Surface(
      padding: EdgeInsets.zero,
      child: ListenableBuilder(
        listenable: Listenable.merge([_areas, _branches, _editor, _flow, _delivery]),
        builder: (context, _) => LayoutBuilder(builder: (context, constraints) => Stack(
          children: [
            Positioned.fill(child: DeliveriesMap(
              controller: _map,
              // Every branch is pinned, the main one with its star at the company's point.
              businessMark: false,
              layers: [
                ..._layers(context),
                BranchMarkers(onSelect: (branch) => _open(branch.id)),
                if (_view == DeliveriesView.shipments && !_editor.isOpen && !_flow.isOpen)
                  ShipmentMarkers(onOpen: _openShipment, lit: _litShipment)
              ],
              overlays: areaOverlays(context, _editor),
              onTap: _tappable ? _editor.tap : null
            )),
            Positioned(
              top: AppSize.spaceS,
              bottom: AppSize.spaceS,
              left: AppSize.spaceS,
              width: MapPanel.width(context, constraints.maxWidth),
              child: MapPanel(child: DeliveriesPanel(
                editor: _editor,
                branch: _picked,
                origin: _origin,
                onBranch: _pick,
                onAdd: _start,
                onNewMethod: _newMethod,
                search: _search,
                branchPicker: _branchPicker,
                query: _query,
                view: _view,
                onView: _show,
                shipments: _board,
                onShipment: _openShipment,
                litShipment: _litShipment,
                flow: _flow,
                company: context.read<BusinessService>().activeId == null ? "" : context.read<BusinessService>().active.name
              ))
            ),
            if (_board) Positioned(
              top: AppSize.spaceS,
              right: AppSize.spaceS,
              child: ListenableBuilder(
                listenable: _shipments,
                builder: (context, _) => _shipments.canAdd
                  ? DeliveriesHeader(onAdd: _addShipment)
                  : const SizedBox.shrink()
              )
            )
          ]
        ))
      )
    )
  );

  /// The panel's areas in their colours (and the one being shaped), the
  /// other branches' in force grey under them.
  List<Widget> _layers(BuildContext context) {
    final areas = _areas.areas;

    // The reach being shaped is the editor's draft; a saved one under it
    // would show the old outline beside the new.
    final outlines = _view == DeliveriesView.areas && !(_editor.isOpen && _editor.reach)
      ? [
          for (final option in DeliveriesPanel.reaches(_delivery.delivery, _picked))
            reachOutline(option.reach!, _branches.branches)
        ]
      : const <List<LatLng>>[];
    final reach = reachLayers(outlines, ThemeColor.of(context).accent);

    if (areas == null) return [...reach, ...areaLayers(context, const [], _editor)];

    final shown = areas.of(_picked);
    final inForce = areas.inForce([for (final branch in _branches.branches) branch.id]);

    return [
      ...reach,
      ...areaLayers(
        context,
        shown,
        _editor,
        others: [for (final area in inForce) if (!shown.contains(area)) area]
      )
    ];
  }
}
