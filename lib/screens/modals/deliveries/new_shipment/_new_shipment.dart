import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sale_model.dart';
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/services/shipments/shipments_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/deliveries/widgets/panel_halves.dart';
import 'package:app/screens/home/sections/sales/sale_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// Opens "New delivery" over the deliveries desk: a sale of the branch still in
/// process, sent as a delivery still to assign or already on its way.
///
/// [service] is the desk's, which writes it and places the new row. Answers the
/// shipment on the board, or null when closed (or when the board did not show
/// it back).
Future<Shipment?> showNewShipment(BuildContext context, {required ShipmentsService service}) async {
  final width = math.min(_width, MediaQuery.of(context).size.width * .5);

  final shipment = await showSideModal(
    context: context,
    title: S.of(context).new_shipment_title,
    minWidth: width,
    maxWidth: width,
    builder: (context) => NewShipmentModal(service: service)
  );

  return shipment is Shipment ? shipment : null;
}

const double _width = 460;

/// **A sale becomes a delivery**: there is no shipment without a sale (its id
/// is the sale's), so the board grows through the sale's handover
/// (`PUT /sales/fulfillment`, `MODE: delivery`). The sales offered are the
/// branch's in process that can still be sent (`SaleModel.canShip`): a charged
/// one not handed over, or a channel order paid when it arrives.
///
/// Who carries it, its window and its address are the shipment's own panel,
/// opened by the desk once it is on the board.
class NewShipmentModal extends StatefulWidget {
  const NewShipmentModal({super.key, required this.service});

  final ShipmentsService service;

  @override
  State<NewShipmentModal> createState() => _NewShipmentModalState();
}

enum _Start { pending, dispatched }

class _NewShipmentModalState extends State<NewShipmentModal> {
  final _form = FormController();

  late final _sale = InputController.select(
    key: "ID",
    form: _form,
    obligatory: true,
    customErrors: {InputError.empty: S.of(context).new_shipment_sale_error}
  );

  late final _note = InputController(key: "NOTE", form: _form, max: 500);

  List<SaleModel>? _sales;
  bool _failed = false;
  _Start _start = _Start.pending;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _sales = null;
      _failed = false;
    });

    try {
      final sales = await widget.service.candidates();
      if (mounted) setState(() => _sales = sales);
    } catch (error) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _submit() async {
    if (widget.service.busy != null || !_sale.validate(_sale)) return;

    final s = S.of(context);
    final flag = FloatFlag.of(context);

    try {
      final shipment = await widget.service.add(
        _sale.value,
        dispatched: _start == _Start.dispatched,
        note: _note.value
      );

      if (!mounted) return;

      flag.message(s.new_shipment_added);
      Navigator.pop(context, shipment);
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final sales = _sales;

    if (_failed) {
      return SectionMessage(
        icon: CI.delivery,
        title: s.new_shipment_error,
        subtitle: s.new_shipment_error_subtitle,
        action: _load,
        actionLabel: s.new_shipment_retry
      );
    }

    if (sales == null) return const Center(child: Loading());

    if (sales.isEmpty) {
      return SectionMessage(
        icon: CI.delivery,
        title: s.new_shipment_empty,
        subtitle: s.new_shipment_empty_subtitle
      );
    }

    return ListenableBuilder(
      listenable: widget.service,
      builder: (context, _) => ScrollableWidget(
        padding: EdgeInsets.only(bottom: AppSize.padding),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextSmall(s.new_shipment_subtitle, lines: 4, color: scheme.text.secondary),
          SizedBox(height: AppSize.spaceS),
          SelectInput(
            title: s.new_shipment_sale,
            placeholder: s.new_shipment_sale_placeholder,
            controller: _sale,
            maxOptions: 8,
            options: [for (final sale in sales) _option(sale)],
            emptyText: s.new_shipment_sale_none,
            leftIcon: Icon(CI.receipt, color: scheme.icon)
          ),
          SettingsBlock(
            title: s.new_shipment_start,
            subtitle: _start == _Start.pending ? s.new_shipment_start_pending : s.new_shipment_start_dispatched,
            child: PanelHalves<_Start>(
              values: _Start.values,
              selected: _start,
              label: (start) => start == _Start.pending
                ? widget.service.nameOf(ShipmentState.unassigned, fallback: s.new_shipment_pending)
                : widget.service.nameOf(ShipmentState.enRoute, fallback: s.new_shipment_dispatched),
              onChanged: (start) => setState(() => _start = start)
            )
          ),
          Input(
            title: s.shipment_note,
            placeholder: s.shipment_note_hint,
            controller: _note,
            lines: 3
          ),
          SizedBox(height: AppSize.spaceXS),
          Button(
            title: s.new_shipment_save,
            leftIcon: Icon(CI.plus, color: scheme.button.text),
            action: () => unawaited(_submit())
          )
        ]
      )
    );
  }

  /// A sale as the picker lists it: its number or code and the customer, with
  /// where it stands and what it comes to.
  SelectOption _option(SaleModel sale) {
    final name = sale.number.isNotEmpty ? sale.number : sale.ticket;
    final title = [
      if (name.isNotEmpty) name,
      if (sale.customer.isNotEmpty) sale.customer
    ].join(" · ");

    return SelectOption(
      value: sale.id,
      placeholder: title.isEmpty ? S.of(context).shipments_untitled : title,
      subtitle: [
        if (sale.label.isNotEmpty) sale.label,
        saleAmountLabel(sale.total, sale.currency)
      ].where((part) => part.isNotEmpty).join(" · "),
      icon: CI.receipt
    );
  }
}
