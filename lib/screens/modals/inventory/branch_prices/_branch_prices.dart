import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/stock/prices/branch_price_model.dart';
import 'package:app/services/stock/prices/branch_prices_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';

/// Opens a product's prices per branch (`sedes-frontend.md` §6), from its price in the stock
/// summary. [catalogPrice] is its `PRICE` cell, what a branch with none of its own sells at.
Future<void> showBranchPrices(
  BuildContext context, {
  required String productId,
  required String product,
  String tableId = "",
  double? catalogPrice,
  required CurrencyModel currency
}) => showSideModal(
  context: context,
  title: S.of(context).branch_prices_title,
  builder: (context) => BranchPricesModal(
    service: BranchPricesService(productId: productId, tableId: tableId),
    product: product,
    catalogPrice: catalogPrice,
    currency: currency
  )
);

/// Every branch with what it sells the product at — its own price and offer, or the
/// catalog's — and, for the branch worked in, the form that sets or removes its own. A ticket
/// already open keeps the price it opened with.
class BranchPricesModal extends StatefulWidget {
  const BranchPricesModal({
    super.key,
    required this.service,
    required this.product,
    required this.currency,
    this.catalogPrice
  });

  /// Owned by the panel: disposed with it.
  final BranchPricesService service;
  final String product;
  final double? catalogPrice;
  final CurrencyModel currency;

  @override
  State<BranchPricesModal> createState() => _BranchPricesModalState();
}

class _BranchPricesModalState extends State<BranchPricesModal> {
  static const double _width = 420;

  BranchPricesService get _service => widget.service;

  final _form = FormController();
  late final _price = InputController(key: "PRICE", form: _form, pattern: "[0-9.,]", max: 16);
  late final _discount = InputController(key: "DISCOUNT", form: _form, pattern: "[0-9.,]", max: 6);

  /// The form opens on the branch's own figures once they are read.
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_changed);
    Future.microtask(_service.load);
  }

  @override
  void dispose() {
    _service.removeListener(_changed);
    _service.dispose();
    _form.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;

    if (!_filled && _service.status == BranchPricesStatus.ready) {
      _filled = true;
      final here = _service.here;
      _price.textController.text = _plain(here?.price);
      _discount.textController.text = here == null || here.inheritsDiscount ? "" : _plain(here.discount ?? 0);
    }

    setState(() {});
  }

  Future<void> _save() async {
    final price = _read(_price.value);
    final discount = _read(_discount.value);

    if (!price.valid || !discount.valid || (discount.value ?? 0) >= 100) {
      FloatFlag.of(context).error(message: S.of(context).branch_prices_invalid);
      return;
    }

    if (price.value == null && _discount.value.trim().isEmpty) {
      FloatFlag.of(context).error(message: S.of(context).branch_prices_empty);
      return;
    }

    try {
      await _service.set(
        price: price.value,
        discount: discount.value,
        clearDiscount: _discount.value.trim().isNotEmpty && (discount.value ?? 0) == 0
      );
      if (mounted) FloatFlag.of(context).message(S.of(context).branch_prices_saved);
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }

  Future<void> _remove() async {
    try {
      await _service.remove();
      _price.textController.clear();
      _discount.textController.clear();
      if (mounted) FloatFlag.of(context).message(S.of(context).branch_prices_removed);
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final branches = BranchService();

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      child: switch (_service.status) {
        BranchPricesStatus.error => SectionMessage(
          icon: CI.wallet,
          title: s.branch_prices_error,
          action: () => unawaited(_service.load()),
          actionLabel: s.permission_retry
        ),
        BranchPricesStatus.ready => ScrollableWidget(
          padding: EdgeInsets.only(bottom: AppSize.padding),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextMedium(widget.product, bold: true, ellipsis: true),
            SizedBox(height: AppSize.gap * 0.5),
            TextSmall(s.branch_prices_subtitle, lines: 3, color: scheme.text.secondary),
            SizedBox(height: AppSize.spaceS),
            for (final branch in branches.branches) _BranchLine(
              name: branch.name,
              here: branch.id == branches.activeId,
              price: _service.of(branch.id),
              catalogPrice: widget.catalogPrice,
              currency: widget.currency
            ),
            if (_service.canPrice) ...[
              SizedBox(height: AppSize.spaceS),
              TextSmall(s.branch_prices_here(branches.active?.name ?? ""), color: scheme.text.secondary),
              SizedBox(height: AppSize.gap),
              Input(
                title: s.branch_prices_price,
                placeholder: widget.catalogPrice == null
                  ? s.branch_prices_price_hint
                  : s.branch_prices_catalog(_amount(widget.catalogPrice!)),
                controller: _price,
                leftIcon: Icon(CI.wallet, color: scheme.icon)
              ),
              Input(
                title: s.branch_prices_discount,
                placeholder: s.branch_prices_discount_hint,
                controller: _discount,
                leftIcon: Icon(CI.gift, color: scheme.icon)
              ),
              SizedBox(height: AppSize.spaceM),
              Row(children: [
                if (_service.here != null) ...[
                  Expanded(child: FeedbackButton(
                    action: _service.writing ? null : _remove,
                    height: AppSize.button,
                    color: scheme.surfaceOver,
                    radius: AppSize.cornerInset(AppSize.gap),
                    message: s.branch_prices_remove,
                    child: Center(child: TextSmall(s.branch_prices_remove))
                  )),
                  SizedBox(width: AppSize.spaceXS)
                ],
                Expanded(child: Button(title: s.save, action: () { if (!_service.writing) unawaited(_save()); }))
              ])
            ]
          ]
        ),
        _ => const Center(child: Loading())
      }
    );
  }

  String _amount(double value) => "${widget.currency.symbol} ${_plain(value)}";

  static ({bool valid, double? value}) _read(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return (valid: true, value: null);
    if (!RegExp(r"^\d+(?:[.,]\d{1,2})?$").hasMatch(text)) return (valid: false, value: null);

    return (valid: true, value: double.parse(text.replaceAll(",", ".")));
  }

  static String _plain(double? value) => value == null
    ? ""
    : value.toStringAsFixed(2).replaceFirst(RegExp(r"\.?0+$"), "");
}

/// A branch and what it sells the product at.
class _BranchLine extends StatelessWidget {
  const _BranchLine({
    required this.name,
    required this.here,
    required this.price,
    required this.catalogPrice,
    required this.currency
  });

  final String name;
  final bool here;
  final BranchPrice? price;
  final double? catalogPrice;
  final CurrencyModel currency;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final own = price;

    String amount(double value) => "${currency.symbol} ${value.toStringAsFixed(2)}";

    final figure = own?.price != null
      ? amount(own!.price!)
      : catalogPrice != null ? "${amount(catalogPrice!)} · ${s.branch_prices_from_catalog}" : s.branch_prices_from_catalog;

    final offer = own == null || own.inheritsDiscount
      ? null
      : own.discount == null ? s.branch_prices_no_offer : s.branch_prices_offer(own.discount!.toStringAsFixed(0));

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.gap),
      child: Row(children: [
        Expanded(child: TextSmall(
          here ? "$name · ${s.branch_prices_this_branch}" : name,
          bold: here,
          ellipsis: true
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          TextSmall(figure, color: own == null ? scheme.text.secondary : scheme.text.primary),
          if (offer != null) TextSmall(offer, color: scheme.text.secondary, multiplier: 0.8)
        ])
      ])
    );
  }
}
