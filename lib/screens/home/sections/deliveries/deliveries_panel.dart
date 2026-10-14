import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_branches_service.dart';
import 'package:app/services/business/delivery_area_model.dart';
import 'package:app/services/business/delivery_area_request.dart';
import 'package:app/services/business/delivery_areas_service.dart';
import 'package:app/services/shipments/shipment_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/deliveries/area/state/area_editor.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/add_area_button.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_editor_panel.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_layers.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_list.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_map_picker.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_probe.dart';
import 'package:app/screens/modals/deliveries/delivery_settings/_delivery_settings.dart';

import './shipments/shipment_list.dart';
import './widgets/panel_halves.dart';

/// What the panel shows: the branch's deliveries, or where the company
/// delivers.
enum DeliveriesView { shipments, areas }

/// The panel over the desk's map.
///
/// While looking: the section's title with its settings beside it (how the
/// company delivers, a side panel over the map), then one of two views. The
/// branch's deliveries (`ShipmentList`), the daily work, open first; the
/// areas show where it delivers (shared or per branch, and per branch whose
/// map is open), "Add area" and the open map's areas. A tap on the map says
/// which areas in force reach that point and which branch the order would
/// leave from.
///
/// While an area is shaped, everything under the title gives way to its tools,
/// name and figures: the map is where the shape is made.
class DeliveriesPanel extends StatelessWidget {
  const DeliveriesPanel({
    super.key,
    required this.editor,
    required this.owner,
    required this.origin,
    required this.onOwner,
    required this.onAdd,
    required this.view,
    required this.onView,
    required this.onShipment,
    this.shipments = true,
    this.litShipment
  });

  final AreaEditor editor;

  /// The open map: a branch's id, or `null` for the shared one.
  final String? owner;

  /// Where an area opened with no center of its own starts.
  final LatLng Function() origin;

  final void Function(String branch) onOwner;

  /// Starts an area made by the method picked.
  final void Function(AreaMethod method) onAdd;

  final DeliveriesView view;
  final void Function(DeliveriesView view) onView;

  /// Whether the deliveries board exists here: a branch's, in the cloud only
  /// (a master runs none, and the board needs the `branch_id` the cloud picks).
  final bool shipments;

  /// Opens a shipment's panel.
  final void Function(Shipment shipment) onShipment;

  /// The shipment picked on the map.
  final String? litShipment;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(child: TextLarge(S.of(context).deliveries, ellipsis: true)),
          SizedBox(width: AppSize.gap),
          FeedbackButton(
            action: () => showDeliverySettings(context),
            height: AppSize.action,
            padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
            radius: AppSize.corner,
            color: scheme.surfaceOver,
            feedbackColor: scheme.line,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CI.setting, size: AppSize.text, color: scheme.icon),
                SizedBox(width: AppSize.gap),
                TextSmall(S.of(context).deliveries_settings, bold: true)
              ]
            )
          )
        ]),
        SizedBox(height: AppSize.gap * 0.5),
        TextSmall(
          S.of(context).deliveries_subtitle,
          lines: 2,
          ellipsis: true,
          color: scheme.text.secondary
        ),
        SizedBox(height: AppSize.spaceS),
        if (!editor.isOpen && shipments) ...[
          PanelHalves<DeliveriesView>(
            values: DeliveriesView.values,
            selected: view,
            label: (view) => view == DeliveriesView.shipments
              ? S.of(context).deliveries_view_shipments
              : S.of(context).deliveries_view_areas,
            icon: (view) => view == DeliveriesView.shipments ? CI.delivery : CI.globe_shopping,
            onChanged: onView
          ),
          SizedBox(height: AppSize.spaceS)
        ],
        Expanded(child: !editor.isOpen && shipments && view == DeliveriesView.shipments
          ? ShipmentList(onOpen: onShipment, lit: litShipment)
          : _areas(context))
      ]
    );
  }

  Widget _areas(BuildContext context) {
    final service = context.watch<DeliveryAreasService>();
    final branchService = context.watch<BusinessBranchesService>();
    final areas = service.areas;

    // Per branch, the maps are the branches': nothing to open before they are read.
    final waiting = areas?.scope == DeliveryScope.branch &&
      branchService.status != BusinessBranchesStatus.ready &&
      branchService.status != BusinessBranchesStatus.error;

    if (service.status == DeliveryAreasStatus.error && areas == null) {
      return Align(
        alignment: Alignment.topCenter,
        child: _Failed(message: S.of(context).deliveries_area_error_title, onRetry: service.retry)
      );
    }

    if (areas == null || waiting) return const Center(child: Loading());

    final branches = branchService.branches;
    final mine = areas.of(owner);

    if (editor.isOpen) {
      return AreaEditorPanel(
        key: ValueKey(editor.session),
        editor: editor,
        currency: areas.currency,
        count: mine.length,
        branch: owner
      );
    }

    final scheme = ThemeColor.of(context);
    final inForce = areas.inForce([for (final branch in branches) branch.id]);
    final point = editor.probe;

    Color colorOf(DeliveryArea area) => area.branch == owner
      ? areaColor(context, mine.indexOf(area), active: area.active)
      : scheme.text.secondary;

    return AreaList(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextMedium(S.of(context).deliveries_scope_title, bold: true, ellipsis: true),
          SizedBox(height: AppSize.gap),
          AreaMapPicker(
            areas: areas,
            branches: branches,
            owner: owner,
            onScope: service.isWriting ? null : (scope) => service.setScope(context, scope),
            onOwner: onOwner
          )
        ]
      ),
      add: AddAreaButton(onPick: onAdd),
      areas: mine,
      currency: areas.currency,
      probe: point == null ? null : AreaProbe(
        holding: DeliveryAreasModel(areas: inForce).holding(point),
        currency: areas.currency,
        colorOf: colorOf,
        from: deliveringBranch(point, scope: areas.scope, inForce: inForce, branches: branches)?.name,
        onClear: editor.clearProbe
      ),
      onFocus: (area) => editor.fit(area.bounds),
      onEdit: (area) => editor.edit(area, origin()),
      onToggle: (area) => service.update(context, deliveryAreaActiveRequest(area, !area.active)),
      onRemove: (area) => _remove(context, service, area)
    );
  }

  Future<void> _remove(BuildContext context, DeliveryAreasService service, DeliveryArea area) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).deliveries_area_remove_title,
      message: S.of(context).deliveries_area_remove_message(area.name),
      confirmText: S.of(context).deliveries_area_remove,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !context.mounted) return;

    await service.remove(context, area.id);
  }
}

/// A read that failed, and the way to read it again.
class _Failed extends StatelessWidget {
  const _Failed({required this.message, required this.onRetry});

  final String message;
  final void Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(children: [
      Expanded(child: TextSmall(message, lines: 2, color: scheme.text.secondary)),
      SizedBox(width: AppSize.gap),
      FeedbackButton(
        action: onRetry,
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap),
        radius: AppSize.corner,
        feedbackColor: scheme.surfaceFeedback,
        child: TextSmall(S.of(context).deliveries_map_retry, bold: true, color: scheme.primary)
      )
    ]);
  }
}
