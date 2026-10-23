import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_branches_service.dart';
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_service.dart';
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

import './methods/method_flow_panel.dart';
import './methods/method_list.dart';
import './methods/state/method_flow.dart';
import './methods/widgets/delivery_meeting_field.dart';
import './shipments/shipment_list.dart';
import './widgets/panel_halves.dart';

/// What the panel shows: the branch's deliveries, where the company delivers,
/// or how (its delivery methods).
enum DeliveriesView { shipments, areas, methods }

/// The panel over the desk's map.
///
/// While looking: the section's title with "New delivery method" beside it,
/// then one of the views. The branch's deliveries (`ShipmentList`), the daily
/// work, open first; the areas show where it delivers (shared or per branch,
/// and per branch whose map is open), "Add area", the open map's areas and
/// what happens outside them (fixed or flexible). A tap on the map says which
/// areas in force reach that point and which branch the order would leave
/// from. The methods (`MethodList`) are the company's ways of delivering,
/// pickup and its delivery note.
///
/// "New delivery method" turns the whole panel into its steps
/// (`MethodFlowPanel`): who carries it, its price and time, and where it
/// delivers — the areas list again, with the map beside it.
///
/// While an area is shaped, everything under the title gives way to its tools,
/// name and figures: the map is where the shape is made. A flow under way
/// comes back after it.
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
    required this.flow,
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

  /// Adding or editing a delivery method, when under way.
  final MethodFlow flow;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    // The flow and the editor bring their own heading: the views' controls
    // would only be ways out of them.
    final busy = editor.isOpen || flow.isOpen;
    final views = [
      if (shipments) DeliveriesView.shipments,
      DeliveriesView.areas,
      DeliveriesView.methods
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(child: TextLarge(S.of(context).deliveries, ellipsis: true)),
          if (!busy) ...[
            SizedBox(width: AppSize.gap),
            _newMethod(context)
          ]
        ]),
        if (!busy) ...[
          SizedBox(height: AppSize.gap * 0.5),
          TextSmall(
            S.of(context).deliveries_subtitle,
            lines: 2,
            ellipsis: true,
            color: scheme.text.secondary
          )
        ],
        SizedBox(height: AppSize.spaceS),
        if (!busy) ...[
          PanelHalves<DeliveriesView>(
            values: views,
            selected: view,
            label: (view) => switch (view) {
              DeliveriesView.shipments => S.of(context).deliveries_view_shipments,
              DeliveriesView.areas => S.of(context).deliveries_view_areas,
              DeliveriesView.methods => S.of(context).deliveries_view_methods
            },
            icon: (view) => switch (view) {
              DeliveriesView.shipments => CI.delivery,
              DeliveriesView.areas => CI.globe_shopping,
              DeliveriesView.methods => CI.store
            },
            onChanged: onView
          ),
          SizedBox(height: AppSize.spaceS)
        ],
        Expanded(child: _body(context))
      ]
    );
  }

  Widget _body(BuildContext context) {
    if (editor.isOpen) return _areas(context);

    if (flow.isOpen) {
      return MethodFlowPanel(
        flow: flow,
        areas: _areas,
        onDone: () {
          flow.close();
          onView(DeliveriesView.methods);
        }
      );
    }

    return switch (view) {
      DeliveriesView.shipments when shipments => ShipmentList(onOpen: onShipment, lit: litShipment),
      DeliveriesView.methods => MethodList(onEdit: (option) => _edit(context, option)),
      _ => _areas(context)
    };
  }

  /// "New delivery method": the panel turns into its steps, unless the
  /// company already has as many as it may.
  Widget _newMethod(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: () {
        final count = context.read<BusinessDeliveryService>().delivery?.options.length ?? 0;

        if (count >= MethodList.limit) {
          FloatFlag.of(context).alert(message: S.of(context).deliveries_method_limit(MethodList.limit));
          return;
        }

        flow.start();
      },
      height: AppSize.action,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
      radius: AppSize.corner,
      color: scheme.surfaceOver,
      feedbackColor: scheme.line,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CI.plus, size: AppSize.text, color: scheme.icon),
          SizedBox(width: AppSize.gap),
          TextSmall(S.of(context).deliveries_method_new, bold: true)
        ]
      )
    );
  }

  /// Opens a method's form in the panel once the catalog is read (see
  /// `MethodFlowPanel._pick`).
  Future<void> _edit(BuildContext context, DeliveryOption option) async {
    await context.read<BusinessDeliveryService>().loadCatalog();
    flow.edit(option);
  }

  /// What the assistant does when a customer is outside every area: it bends
  /// the areas, so it is set under them. Company-wide, saved on tap.
  Widget _outside(BuildContext context) {
    final service = context.watch<BusinessDeliveryService>();
    final delivery = service.delivery;

    if (delivery == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextMedium(S.of(context).deliveries_area_outside, bold: true, ellipsis: true),
        SizedBox(height: AppSize.gap * 0.5),
        TextSmall(
          S.of(context).business_delivery_meeting_note,
          lines: 3,
          color: ThemeColor.of(context).text.secondary
        ),
        SizedBox(height: AppSize.gap),
        DeliveryMeetingField(
          value: delivery.meeting,
          onChanged: (value) {
            if (value != delivery.meeting && !service.isWriting) service.setMeeting(context, value);
          }
        )
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
      footer: mine.isEmpty ? null : _outside(context),
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
