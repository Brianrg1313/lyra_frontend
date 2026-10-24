import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';
import 'package:app/services/business/business_delivery_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/_section/page_switcher.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/deliveries/area/state/area_editor.dart';
import 'package:app/screens/home/sections/deliveries/widgets/map_panel.dart';

import 'package:app/screens/home/sections/deliveries/delivery_format.dart';
import './method_form.dart';
import './method_list.dart';
import './state/method_flow.dart';
import './widgets/method_card.dart';

/// Adding (or editing) a delivery method, in the desk's own panel, as three
/// steps: who carries the order, that method's price and time, and where the
/// company delivers — the areas, drawn on the map right beside it.
///
/// In the panel and not in a side panel over the map: the last step is the
/// map, and a panel on top of it would hide what is being drawn. Nothing but
/// the current step is on screen, so nothing under the cards can be mistaken
/// for part of the answer.
///
/// [areas] is the desk's areas list, the same one its Areas view shows: an
/// area added here is shaped by the panel's area editor and comes back to
/// this step (see [MethodFlow]). The company's own delivery has no such step:
/// how far it goes is shaped in its form, on the same map ([editor]).
class MethodFlowPanel extends StatefulWidget {
  const MethodFlowPanel({
    super.key,
    required this.flow,
    required this.areas,
    required this.onDone,
    this.ownName,
    this.hoursOf,
    this.branchName,
    this.editor,
    this.reachFrom,
    this.reachBranch
  });

  final MethodFlow flow;
  final Widget Function(BuildContext context) areas;

  /// See `DeliveryOptionForm`: the name a new own delivery opens with, and
  /// the branch whose hours stand beside its prices.
  final String? ownName;
  final String? hoursOf;
  final String? branchName;

  /// See `DeliveryOptionForm`: the map an own delivery's reach is shaped on,
  /// the point it is measured from and that point's branch.
  final AreaEditor? editor;
  final LatLng? reachFrom;
  final String? reachBranch;

  /// The flow ended on its last step.
  final void Function() onDone;

  @override
  State<MethodFlowPanel> createState() => _MethodFlowPanelState();
}

class _MethodFlowPanelState extends State<MethodFlowPanel> {
  bool _saving = false;

  MethodFlow get _flow => widget.flow;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessDeliveryService>();
    final delivery = service.delivery;

    if (delivery == null) {
      return service.status == BusinessDeliveryStatus.error
        ? SectionMessage(
            icon: CI.info,
            title: S.of(context).business_delivery_error_title,
            subtitle: S.of(context).business_delivery_error_subtitle,
            action: service.retry,
            actionLabel: S.of(context).business_list_retry
          )
        : const Center(child: Loading());
    }

    final scheme = ThemeColor.of(context);
    final step = _flow.step ?? MethodStep.kind;
    final editing = _flow.editing;
    final mode = _flow.mode;

    final (title, note) = switch (step) {
      MethodStep.kind => (S.of(context).deliveries_method_how, S.of(context).deliveries_method_subtitle),
      MethodStep.form when editing != null => (
        deliveryOptionName(context, editing),
        S.of(context).deliveries_method_edit_note
      ),
      MethodStep.form => (deliveryMethodName(context, mode!), deliveryMethodNote(context, mode)),
      MethodStep.areas => (S.of(context).deliveries_method_where, S.of(context).deliveries_method_where_note)
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          if (step != MethodStep.areas) ...[
            // The app's back arrow (an employee's page, a channel's form):
            // same box, same icon size.
            FeedbackButton(
              action: _flow.back,
              width: AppSize.action,
              height: AppSize.action,
              message: S.of(context).deliveries_method_back,
              child: Center(child: Icon(CI.arrow_left, color: scheme.text.primary))
            ),
            SizedBox(width: AppSize.gap)
          ],
          if (step == MethodStep.form && mode != null) ...[
            Icon(mode.icon, size: AppSize.text, color: scheme.primary),
            SizedBox(width: AppSize.gap)
          ],
          Expanded(child: TextMedium(title, bold: true, ellipsis: true)),
          // An edit is one step; a new method shows where it is in three.
          if (editing == null) ...[
            SizedBox(width: AppSize.gap),
            TextSmall(
              S.of(context).deliveries_method_step(step.index + 1, _flow.steps),
              color: scheme.text.secondary
            )
          ]
        ]),
        SizedBox(height: AppSize.gap * 0.5),
        TextSmall(note, lines: 3, color: scheme.text.secondary),
        SizedBox(height: AppSize.spaceS),
        Expanded(child: PageSwitcher(
          id: "${step.name}:${editing?.id ?? mode?.name}",
          child: switch (step) {
            MethodStep.kind => _kinds(context, service, delivery),
            MethodStep.form => DeliveryOptionForm(
              catalog: service.catalog,
              currency: delivery.currency,
              option: editing,
              mode: editing == null ? mode : null,
              saving: _saving,
              ownName: widget.ownName,
              hoursOf: widget.hoursOf,
              branchName: widget.branchName,
              editor: widget.editor,
              reachFrom: widget.reachFrom,
              reachBranch: widget.reachBranch,
              onSubmit: (request) => _save(service, delivery, request)
            ),
            MethodStep.areas => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: widget.areas(context)),
                Padding(
                  padding: EdgeInsets.only(bottom: MapPanel.inset),
                  child: Button(title: S.of(context).deliveries_method_done, action: widget.onDone)
                )
              ]
            )
          }
        ))
      ]
    );
  }

  /// The three kinds of service, each naming the country's carriers of it.
  Widget _kinds(BuildContext context, BusinessDeliveryService service, BusinessDeliveryModel delivery) {
    final catalog = service.catalog;

    if (delivery.options.length >= MethodList.limit) {
      return Align(
        alignment: Alignment.topLeft,
        child: TextSmall(
          S.of(context).deliveries_method_limit(MethodList.limit),
          lines: 3,
          color: ThemeColor.of(context).text.secondary
        )
      );
    }

    return ScrollableWidget(
      showBar: false,
      padding: EdgeInsets.only(bottom: MapPanel.inset),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final mode in catalog?.modes ?? DeliveryMode.values) Padding(
          padding: EdgeInsets.only(bottom: AppSize.gap),
          child: DeliveryMethodCard(
            mode: mode,
            examples: [for (final provider in catalog?.of(mode) ?? const []) provider.name],
            onPick: () => _pick(service, mode)
          )
        )
      ]
    );
  }

  /// Opens the form of [mode] once the catalog is read: a carrier picker that
  /// fills itself in halfway through a form is one somebody already scrolled past.
  Future<void> _pick(BusinessDeliveryService service, DeliveryMode mode) async {
    await service.loadCatalog();
    if (mounted) _flow.pick(mode);
  }

  /// Writes the method and moves on (see [MethodFlow.saved]).
  ///
  /// A new method also turns delivery back on when the company had said no —
  /// adding a way to deliver is saying yes, and leaving it off would keep the
  /// new one from ever being offered.
  Future<void> _save(
    BusinessDeliveryService service,
    BusinessDeliveryModel delivery,
    Map<String, dynamic> request
  ) async {
    final creating = _flow.editing == null;

    setState(() => _saving = true);

    final written = creating
      ? await service.createOption(context, request)
      : await service.updateOption(context, request);

    if (written && mounted && creating && delivery.delivers == false) {
      await service.setFlag(context, DeliveryFlag.delivers, true);
    }

    if (!mounted) return;

    setState(() => _saving = false);

    if (!written) return;

    FloatFlag.of(context).message(S.of(context).deliveries_method_saved);
    _flow.saved();
  }
}
