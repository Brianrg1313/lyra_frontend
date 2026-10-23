import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/business_branches_service.dart';
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_service.dart';
import 'package:app/services/business/delivery_area_model.dart';
import 'package:app/services/business/delivery_area_request.dart';
import 'package:app/services/business/delivery_areas_service.dart';
import 'package:app/services/shipments/shipment_model.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/deliveries/area/state/area_editor.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/add_area_button.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_editor_panel.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_layers.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_list.dart';
import 'package:app/screens/home/sections/deliveries/area/widgets/area_probe.dart';
import 'package:app/screens/home/sections/deliveries/delivery_format.dart';

import './methods/method_flow_panel.dart';
import './methods/state/method_flow.dart';
import './methods/widgets/delivery_meeting_field.dart';
import './methods/widgets/reach_tile.dart';
import './shipments/shipment_list.dart';
import './widgets/panel_halves.dart';

/// What the panel shows: the branch's deliveries, or where the company
/// delivers.
enum DeliveriesView { shipments, areas }

/// The panel over the desk's map.
///
/// While looking: the title and what the desk is for, a search over the view
/// on screen, the branch the desk is
/// filtered by ("All branches" or one), the switch between the two views, and
/// the view. The deliveries (`ShipmentList`) are the daily work, open first;
/// the areas show "New delivery method", the map of the branch picked and what
/// happens outside them (fixed or flexible). A tap on the map says which areas
/// in force reach that point and which branch the order would leave from.
///
/// On the areas the branch field is the scope too: "All branches" is the
/// shared map, a branch its own map (the desk writes the scope it means).
///
/// The board reads the branch worked in only (`branch_id`): "All branches", or
/// a branch the person does not work in, says so instead of a list.
///
/// "New delivery method" (over the areas) turns the whole panel into its
/// steps (`MethodFlowPanel`); while an area is shaped, the panel gives way to
/// its tools, name and figures. A flow under way comes back after it.
class DeliveriesPanel extends StatelessWidget {
  const DeliveriesPanel({
    super.key,
    required this.editor,
    required this.branch,
    required this.origin,
    required this.onBranch,
    required this.onAdd,
    required this.onNewMethod,
    required this.view,
    required this.onView,
    required this.onShipment,
    required this.flow,
    required this.search,
    required this.branchPicker,
    this.query = "",
    this.shipments = true,
    this.litShipment,
    this.company = ""
  });

  final AreaEditor editor;

  /// The branch picked, or `null` for all of them.
  final String? branch;

  /// Where an area opened with no center of its own starts.
  final LatLng Function() origin;

  final void Function(String? branch) onBranch;

  /// Starts an area made by the method picked.
  final void Function(AreaMethod method) onAdd;

  /// Starts a new delivery method, unless the company is at the limit.
  final void Function() onNewMethod;

  final DeliveriesView view;
  final void Function(DeliveriesView view) onView;

  /// Whether the deliveries board exists here: a branch's, in the cloud only
  /// (a master runs none, and the board needs the `branch_id` the cloud picks).
  final bool shipments;

  /// Opens a shipment's panel.
  final void Function(Shipment shipment) onShipment;

  /// The shipment picked on the map.
  final String? litShipment;

  /// The company's name: a new own delivery's with "All branches" picked.
  final String company;

  /// Adding or editing a delivery method, when under way.
  final MethodFlow flow;

  /// The search field and the branch field: the desk's, so what was typed or
  /// picked outlives the flow and the editor that hide them.
  final InputController search;
  final InputController branchPicker;

  /// What the search holds, trimmed and lower case.
  final String query;

  /// [branchPicker]'s value for "All branches".
  static const String allBranches = "all";

  /// The scope the branch field means on the areas: "All branches" shares
  /// one map, a branch has its own.
  static DeliveryScope scopeOf(String? branch) => branch == null ? DeliveryScope.global : DeliveryScope.branch;

  /// The own deliveries with a reach shown on the map of [branch]: every one
  /// on "All branches", else those measured from it or from none.
  static List<DeliveryOption> reaches(BusinessDeliveryModel? delivery, String? branch) => [
    for (final option in delivery?.options ?? const <DeliveryOption>[])
      if (option.mode == DeliveryMode.own &&
          option.reach != null &&
          (branch == null || option.reach!.branch == null || option.reach!.branch == branch))
        option
  ];

  @override
  Widget build(BuildContext context) {
    // The flow and the editor bring their own heading: the views' controls
    // would only be ways out of them.
    // A reach session is the method form's own: the form stays on.
    if (editor.isOpen && !editor.reach) return _areas(context);

    if (flow.isOpen) {
      final branches = context.watch<BusinessBranchesService>().branches;
      final picked = branches.where((entry) => entry.id == branch).firstOrNull;
      // The hours beside an own delivery's prices: the branch picked's, else
      // the main one's — a method is the company's, any week is an example.
      final shown = picked ?? branches.where((entry) => entry.main).firstOrNull ?? branches.firstOrNull;

      return MethodFlowPanel(
        flow: flow,
        areas: _areas,
        ownName: picked?.name ?? (company.isEmpty ? null : company),
        hoursOf: shown?.id,
        branchName: shown?.name,
        editor: editor,
        // An own delivery's reach is measured from that branch's point.
        reachFrom: switch (shown) {
          BusinessBranchModel(:final double latitude, :final double longitude) => LatLng(latitude, longitude),
          _ => origin()
        },
        reachBranch: shown?.id,
        onDone: () {
          flow.close();
          onView(DeliveriesView.areas);
        }
      );
    }

    final views = [
      if (shipments) DeliveriesView.shipments,
      DeliveriesView.areas
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextInter(S.of(context).deliveries, multiplier: 1.4, bold: true),
        SizedBox(height: AppSize.gap * 0.5),
        TextSmall(
          S.of(context).deliveries_subtitle,
          lines: 2,
          ellipsis: true,
          color: ThemeColor.of(context).text.secondary
        ),
        SizedBox(height: AppSize.spaceS),
        SearchInput(
          controller: search,
          placeholder: view == DeliveriesView.shipments
            ? S.of(context).deliveries_search_shipments
            : S.of(context).deliveries_search_areas,
          // Filtered as it is typed (the desk listens to the field): there is
          // nothing to ask the backend.
          onSearch: (_) {}
        ),
        SizedBox(height: AppSize.gap),
        _branchField(context),
        SizedBox(height: AppSize.spaceS),
        if (views.length > 1) ...[
          PanelHalves<DeliveriesView>(
            values: views,
            selected: view,
            label: (view) => switch (view) {
              DeliveriesView.shipments => S.of(context).deliveries_view_shipments,
              DeliveriesView.areas => S.of(context).deliveries_view_areas
            },
            icon: (view) => switch (view) {
              DeliveriesView.shipments => CI.delivery,
              DeliveriesView.areas => CI.globe_shopping
            },
            onChanged: onView
          ),
          SizedBox(height: AppSize.spaceS)
        ],
        Expanded(child: view == DeliveriesView.shipments && shipments
          ? _shipments(context)
          : _areas(context))
      ]
    );
  }

  /// "All branches" and each branch; in the areas view each says how many
  /// areas its map has.
  Widget _branchField(BuildContext context) {
    final areas = context.watch<DeliveryAreasService>().areas;
    final branches = context.watch<BusinessBranchesService>().branches;
    final counted = view == DeliveriesView.areas && areas != null;

    return SelectInput(
      controller: branchPicker,
      placeholder: S.of(context).deliveries_branch,
      leftIcon: const Icon(CI.store),
      searchable: false,
      emptyText: S.of(context).deliveries_scope_branches_empty,
      options: [
        SelectOption(value: allBranches, placeholder: S.of(context).deliveries_branch_all),
        for (final branch in branches) SelectOption(
          value: branch.id,
          placeholder: branch.name,
          subtitle: counted ? S.of(context).deliveries_scope_branch_count(areas.of(branch.id).length) : null
        )
      ],
      onSelected: (option) => onBranch(option.value == allBranches ? null : option.value)
    );
  }

  /// The board, when it is the branch picked's: it reads the branch worked in
  /// and no other.
  Widget _shipments(BuildContext context) {
    final working = BranchService().activeId;

    if (branch == null || (working != null && branch != working)) {
      return Align(
        alignment: Alignment.topLeft,
        child: TextSmall(
          branch == null ? S.of(context).deliveries_shipments_all : S.of(context).deliveries_shipments_not_yours,
          lines: 4,
          color: ThemeColor.of(context).text.secondary
        )
      );
    }

    return ShipmentList(onOpen: onShipment, lit: litShipment, query: query);
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

    // A branch's map is only known once the branches are read.
    final waiting = branch != null &&
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
    final listed = areas.of(branch);

    if (editor.isOpen) {
      return AreaEditorPanel(
        key: ValueKey(editor.session),
        editor: editor,
        currency: areas.currency,
        count: listed.length,
        branch: branch
      );
    }

    final scheme = ThemeColor.of(context);
    final inForce = areas.inForce([for (final branch in branches) branch.id]);
    final point = editor.probe;
    final reaching = [
      for (final option in DeliveriesPanel.reaches(context.watch<BusinessDeliveryService>().delivery, branch))
        if (query.isEmpty || deliveryOptionName(context, option).toLowerCase().contains(query)) option
    ];

    Color colorOf(DeliveryArea area) => listed.contains(area)
      ? areaColor(context, listed.indexOf(area), active: area.active)
      : scheme.text.secondary;

    // The colours stay the map's: an area keeps its index while others are
    // filtered out of the list.
    final found = query.isEmpty
      ? listed
      : [for (final area in listed) if (area.name.toLowerCase().contains(query)) area];

    return AreaList(
      // In a method's last step its areas are added here; looking, the
      // method comes first.
      add: flow.isOpen ? AddAreaButton(onPick: onAdd) : AddAreaButton.method(onMethod: onNewMethod),
      areas: found,
      colorOf: colorOf,
      empty: listed.isNotEmpty ? S.of(context).deliveries_search_empty : null,
      currency: areas.currency,
      probe: point == null ? null : AreaProbe(
        holding: DeliveryAreasModel(areas: inForce).holding(point),
        currency: areas.currency,
        colorOf: colorOf,
        from: deliveringBranch(point, scope: areas.scope, inForce: inForce, branches: branches)?.name,
        onClear: editor.clearProbe
      ),
      reaches: [
        for (final option in reaching) ReachTile(
          option: option,
          color: scheme.accent,
          currency: areas.currency,
          onFocus: () => editor.fit(reachOutline(option.reach!, branches)),
          onEdit: () => flow.edit(option)
        )
      ],
      footer: listed.isEmpty ? null : _outside(context),
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
