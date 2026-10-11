import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_branches_service.dart';
import 'package:app/services/business/delivery_area_model.dart';
import 'package:app/services/business/delivery_area_request.dart';
import 'package:app/services/business/delivery_areas_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/business/branches/branch_markers.dart';
import 'package:app/screens/home/sections/deliveries/area/state/area_editor.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_editor_panel.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_layers.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_list.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_map_picker.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_probe.dart';
import 'package:app/screens/home/sections/deliveries/deliveries_map.dart';

/// Body of the delivery area: a panel on the left (one third) and the map on
/// the right (two thirds), like the deliveries desk.
///
/// While looking, the panel says how the areas are shared and which map is
/// open, lists its areas, and a tap on the map says which areas in force reach
/// that point and which branch the order would leave from. While an area is
/// shaped, the panel holds its tools and its name and figures, and the map is
/// where the shape is made.
///
/// Per branch, the other branches' areas are drawn grey under the open map's,
/// and every branch is pinned: a pin opens its map.
class DeliveryAreaBody extends StatefulWidget {
  const DeliveryAreaBody({
    super.key,
    required this.editor,
    required this.map,
    required this.origin,
    required this.owner,
    required this.onOwner
  });

  final AreaEditor editor;
  final MapController map;

  /// Where an area opened with no center of its own starts.
  final LatLng Function() origin;

  /// The open map: a branch's id, or `null` for the shared one.
  final String? owner;

  final void Function(String branch) onOwner;

  @override
  State<DeliveryAreaBody> createState() => _DeliveryAreaBodyState();
}

class _DeliveryAreaBodyState extends State<DeliveryAreaBody> {
  AreaEditor get _editor => widget.editor;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DeliveryAreasService>();
    final branchService = context.watch<BusinessBranchesService>();
    final areas = service.areas;

    // Per branch, the maps are the branches': nothing to open before they are read.
    final waiting = areas?.scope == DeliveryScope.branch &&
      branchService.status != BusinessBranchesStatus.ready &&
      branchService.status != BusinessBranchesStatus.error;

    return switch (service.status) {
      DeliveryAreasStatus.error when areas == null => SectionMessage(
        icon: CI.info,
        title: S.of(context).deliveries_area_error_title,
        subtitle: S.of(context).deliveries_area_error_subtitle,
        action: service.retry,
        actionLabel: S.of(context).deliveries_map_retry
      ),
      _ when areas != null && !waiting => ListenableBuilder(
        listenable: _editor,
        builder: (context, _) => _content(context, service, areas)
      ),
      _ => const Center(child: Loading())
    };
  }

  Widget _content(BuildContext context, DeliveryAreasService service, DeliveryAreasModel areas) {
    final branches = context.read<BusinessBranchesService>().branches;
    final scheme = ThemeColor.of(context);
    final mine = areas.of(widget.owner);
    final inForce = areas.inForce([for (final branch in branches) branch.id]);
    final others = [for (final area in inForce) if (area.branch != widget.owner) area];

    Color colorOf(DeliveryArea area) => area.branch == widget.owner
      ? areaColor(context, mine.indexOf(area), active: area.active)
      : scheme.text.secondary;

    final point = _editor.probe;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _editor.isOpen
          ? AreaEditorPanel(
              key: ValueKey(_editor.session),
              editor: _editor,
              currency: areas.currency,
              count: mine.length,
              branch: widget.owner
            )
          : AreaList(
              header: AreaMapPicker(
                areas: areas,
                branches: branches,
                owner: widget.owner,
                onScope: service.isWriting ? null : (scope) => service.setScope(context, scope),
                onOwner: widget.onOwner
              ),
              areas: mine,
              currency: areas.currency,
              probe: point == null ? null : AreaProbe(
                holding: DeliveryAreasModel(areas: inForce).holding(point),
                currency: areas.currency,
                colorOf: colorOf,
                from: deliveringBranch(point, scope: areas.scope, inForce: inForce, branches: branches)?.name,
                onClear: _editor.clearProbe
              ),
              onFocus: (area) => _editor.fit(area.bounds),
              onEdit: (area) => _editor.edit(area, widget.origin()),
              onToggle: (area) => _toggle(service, area),
              onRemove: (area) => _remove(service, area)
            )),
        SizedBox(width: AppSize.gap),
        Expanded(flex: 2, child: DeliveriesMap(
          controller: widget.map,
          // Every branch is pinned, the main one with its star at the company's point.
          businessMark: false,
          layers: [
            ...areaLayers(context, mine, _editor, others: others),
            BranchMarkers(onSelect: (branch) => widget.onOwner(branch.id))
          ],
          overlays: areaOverlays(context, _editor),
          onTap: _editor.tap
        ))
      ]
    );
  }

  Future<void> _toggle(DeliveryAreasService service, DeliveryArea area) =>
    service.update(context, deliveryAreaActiveRequest(area, !area.active));

  Future<void> _remove(DeliveryAreasService service, DeliveryArea area) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).deliveries_area_remove_title,
      message: S.of(context).deliveries_area_remove_message(area.name),
      confirmText: S.of(context).deliveries_area_remove,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !mounted) return;

    await service.remove(context, area.id);
  }
}
