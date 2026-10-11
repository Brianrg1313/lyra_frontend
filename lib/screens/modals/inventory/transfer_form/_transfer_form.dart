import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/stock/transfers/stock_transfer_request.dart';
import 'package:app/services/stock/transfers/stock_transfers_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// Opens the panel that drafts a transfer from the branch worked in. Returns the body of
/// `createTransferRequest` (with `SEND` when "Send now" was pressed), or null.
///
/// [service] only searches the products and remembers their names: the panel writes nothing.
Future<Map<String, dynamic>?> showTransferForm(
  BuildContext context, {
  required StockTransfersService service
}) => showSideModal(
  context: context,
  title: S.of(context).inventory_transfers_new,
  builder: (context) => TransferFormModal(service: service)
).then((value) => value is Map<String, dynamic> ? value : null);

/// Where it goes, which products and how many, a note. A product's free units (stock less what
/// is held) are said beside it: sending more than that is refused for the whole shipment.
class TransferFormModal extends StatefulWidget {
  const TransferFormModal({super.key, required this.service});

  final StockTransfersService service;

  @override
  State<TransferFormModal> createState() => _TransferFormModalState();
}

class _TransferFormModalState extends State<TransferFormModal> {
  static const double _width = 420;

  late final _to = InputController.select(
    key: "TO_BRANCH",
    initial: widget.service.destinations.length == 1 ? widget.service.destinations.first : null
  );
  final _search = InputController(key: "search");
  final _note = InputController(key: "NOTE", max: 255);

  /// What the search found.
  List<TransferProduct> _found = const [];
  bool _searching = false;
  int _searches = 0;

  /// The lines, in the order they were added.
  final List<TransferProduct> _picked = [];
  final Map<String, InputController> _quantities = {};

  @override
  void dispose() {
    _to.form.dispose();
    _search.form.dispose();
    _note.form.dispose();
    for (final quantity in _quantities.values) {
      quantity.form.dispose();
    }
    super.dispose();
  }

  Future<void> _find(String match) async {
    final search = ++_searches;

    if (match.trim().isEmpty) {
      setState(() => _found = const []);
      return;
    }

    setState(() => _searching = true);

    List<TransferProduct> found = const [];
    try {
      found = await widget.service.searchProducts(match);
    } catch (error) {
      FloatFlag.showFromError(error);
    }

    if (!mounted || search != _searches) return;

    setState(() {
      _found = found;
      _searching = false;
    });
  }

  void _add(TransferProduct product) {
    if (_picked.any((line) => line.id == product.id)) return;
    // One table per transfer: its lines are rows of it.
    if (_picked.isNotEmpty && _picked.first.table != product.table) return;

    setState(() {
      _picked.add(product);
      _quantities[product.id] = InputController(key: "QTY_${product.id}", type: InputType.numeric, max: 6, initial: "1");
    });
  }

  void _remove(TransferProduct product) {
    final quantity = _quantities.remove(product.id);
    setState(() => _picked.remove(product));
    if (quantity != null) WidgetsBinding.instance.addPostFrameCallback((_) => quantity.form.dispose());
  }

  void _submit({required bool send}) {
    final to = _to.value.trim();

    if (to.isEmpty) {
      FloatFlag.of(context).error(message: S.of(context).inventory_transfers_destination_required);
      return;
    }

    final items = <StockTransferItem>[
      for (final line in _picked)
        (productId: line.id, quantity: int.tryParse(_quantities[line.id]!.value.trim()) ?? 0)
    ];

    if (!items.any((item) => item.quantity > 0)) {
      FloatFlag.of(context).error(message: S.of(context).inventory_transfers_items_required);
      return;
    }

    widget.service.remember({for (final line in _picked) line.id: line.name});

    Navigator.pop(context, createTransferRequest(
      toBranch: to,
      items: items,
      tableId: _picked.first.table,
      note: _note.value,
      send: send
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final branches = BranchService();

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      child: ScrollableWidget(
        padding: EdgeInsets.only(bottom: AppSize.padding),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: AppSize.spaceS),
            child: TextSmall(
              s.inventory_transfers_form_subtitle(branches.active?.name ?? ""),
              lines: 3,
              color: scheme.text.secondary
            )
          ),
          SelectInput(
            title: s.inventory_transfers_destination,
            placeholder: s.inventory_transfers_destination_placeholder,
            controller: _to,
            searchable: false,
            emptyText: s.business_delivery_select_empty,
            leftIcon: Icon(CI.store, color: scheme.icon),
            options: [
              for (final id in widget.service.destinations)
                SelectOption(value: id, placeholder: branches.nameOf(id))
            ]
          ),
          SearchInput(
            controller: _search,
            placeholder: s.inventory_transfers_search,
            onSearch: (value) => unawaited(_find(value))
          ),
          if (_searching)
            Padding(padding: EdgeInsets.all(AppSize.spaceS), child: const Center(child: Loading()))
          else
            for (final product in _found)
              if (!_picked.any((line) => line.id == product.id)) _FoundProduct(
                product: product,
                enabled: _picked.isEmpty || _picked.first.table == product.table,
                onTap: () => _add(product)
              ),
          if (_picked.isNotEmpty) ...[
            SizedBox(height: AppSize.spaceS),
            TextSmall(s.inventory_transfers_lines, color: scheme.text.secondary),
            SizedBox(height: AppSize.gap),
            for (final product in _picked) _Line(
              product: product,
              quantity: _quantities[product.id]!,
              onRemove: () => _remove(product)
            )
          ],
          SizedBox(height: AppSize.spaceS),
          Input(
            title: "${s.inventory_transfers_note} · ${s.business_delivery_optional}",
            placeholder: s.inventory_transfers_note_hint,
            controller: _note,
            leftIcon: Icon(CI.edit, color: scheme.icon)
          ),
          SizedBox(height: AppSize.spaceM),
          Row(children: [
            Expanded(child: FeedbackButton(
              action: () => _submit(send: false),
              height: AppSize.button,
              color: scheme.surfaceOver,
              radius: AppSize.cornerInset(AppSize.gap),
              message: s.inventory_transfers_save_draft,
              child: Center(child: TextSmall(s.inventory_transfers_save_draft))
            )),
            SizedBox(width: AppSize.spaceXS),
            Expanded(child: Button(
              title: s.inventory_transfers_send_now,
              action: () => _submit(send: true)
            ))
          ])
        ]
      )
    );
  }
}

/// A search result: tap to add it.
class _FoundProduct extends StatelessWidget {
  const _FoundProduct({required this.product, required this.enabled, required this.onTap});

  final TransferProduct product;
  final bool enabled;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: enabled ? onTap : null,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS, vertical: AppSize.gap),
      radius: AppSize.cornerInset(AppSize.gap),
      child: Row(children: [
        Icon(CI.plus, size: AppSize.text, color: enabled ? scheme.icon : scheme.text.secondary),
        SizedBox(width: AppSize.gap),
        Expanded(child: TextSmall(product.name, ellipsis: true, color: enabled ? null : scheme.text.secondary)),
        if (product.available != null)
          TextSmall(S.of(context).inventory_transfers_available(product.available!), color: scheme.text.secondary)
      ])
    );
  }
}

/// A product on the transfer and its units.
class _Line extends StatelessWidget {
  const _Line({required this.product, required this.quantity, required this.onRemove});

  final TransferProduct product;
  final InputController quantity;
  final void Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.gap),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          TextSmall(product.name, ellipsis: true),
          if (product.available != null)
            TextSmall(S.of(context).inventory_transfers_available(product.available!), color: scheme.text.secondary, multiplier: 0.8)
        ])),
        SizedBox(width: AppSize.gap),
        SizedBox(width: AppSize.action * 2, child: Input(controller: quantity, placeholder: "0")),
        FocusableWidget(
          action: onRemove,
          message: S.of(context).inventory_transfers_remove_line,
          child: Padding(
            padding: EdgeInsets.all(AppSize.gap),
            child: Icon(CI.trash, size: AppSize.text, color: scheme.snackBar.error)
          )
        )
      ])
    );
  }
}
