import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/kitchen/till_kitchen_service.dart';
import 'package:app/services/pos/pos_invoice_service.dart';
import 'package:app/services/pos/pos_product_model.dart';

// WIDGETS
import 'package:app/screens/modals/pos/pos_modifiers/_pos_modifiers.dart';

import './pos_currency.dart';

/// Rings [product] up the way the kitchen asks (`cocina-frontend.md` §5–6).
///
/// A product that offers modifiers and isn't on the ticket yet asks for them first; closing
/// the picker rings nothing up. A second tap of a dish already on the ticket adds a unit with
/// what it was chosen with, and asks nothing. A refusal is then answered ([posAnswerRefusal]).
Future<void> posRingUp(BuildContext context, PosProduct product) async {
  final ticket = context.read<PosInvoiceService>();
  final kitchen = context.read<TillKitchenService>();

  List<PosModifierPick>? picks;

  if (kitchen.offers(product.id) && !ticket.carries(product.id)) {
    final asked = await _askModifiers(context, kitchen, product);
    if (asked == null) return;

    picks = asked.isEmpty ? null : asked;
  }

  if (await ticket.add(product, modifiers: picks)) return;
  if (!context.mounted) return;

  await posAnswerRefusal(context, ticket, product: product);
}

/// Says why a write of the ticket didn't go, or asks what it needs to go:
///
/// - `negotiable_short`: «Today there is no fries. Without fries?» — yes sends it again with
///   `WITHOUT`, no forgets it (nothing moved).
/// - `invalid_modifiers` on a [product] being rung up: a required group the till didn't know
///   about; its modifiers are asked for and the product rung up with them.
/// - anything else is the backend's, already worded.
Future<void> posAnswerRefusal(BuildContext context, PosInvoiceService ticket, {PosProduct? product}) async {
  final kitchen = context.read<TillKitchenService>();

  if (ticket.short != null) return _askWithout(context, ticket, kitchen);

  if (product != null && ticket.asksModifiers && TillKitchenService.shown) {
    final picks = await _askModifiers(context, kitchen, product);
    if (picks == null || picks.isEmpty || !context.mounted) return;

    if (await ticket.add(product, modifiers: picks)) return;
    if (!context.mounted) return;

    return posAnswerRefusal(context, ticket);
  }

  final error = ticket.error;
  if (error != null) FloatFlag.of(context).fromError(error);
}

/// The product's groups, and what the customer picked of them: null when closed, empty when
/// it offers none after all.
Future<List<PosModifierPick>?> _askModifiers(BuildContext context, TillKitchenService kitchen, PosProduct product) async {
  final groups = await kitchen.groupsOf(product.id);
  if (groups.isEmpty) return const [];
  if (!context.mounted) return null;

  return showPosModifiers(
    context,
    product: product.label.isEmpty ? S.of(context).pos_product_unnamed : product.label,
    groups: groups,
    currency: posCurrency(context)
  );
}

Future<void> _askWithout(BuildContext context, PosInvoiceService ticket, TillKitchenService kitchen) async {
  final refused = ticket.short!;
  final error = ticket.error;
  final short = await kitchen.shortOf(refused.productId);

  if (!context.mounted) return;

  // Nothing short any more (someone restocked between the two reads): the backend's own
  // words, and the cashier taps again.
  if (short.isEmpty) {
    ticket.dropShort();
    if (error != null) FloatFlag.of(context).fromError(error);
    return;
  }

  final s = S.of(context);
  final names = short.map((line) => line.name).where((name) => name.isNotEmpty).join(", ");

  final accepted = await showAlertModal(
    context: context,
    title: s.pos_without_title(names),
    message: s.pos_without_message(names),
    confirmText: s.pos_without_confirm(names),
    cancelText: s.pos_without_cancel
  );

  if (!context.mounted) return;

  if (!accepted) {
    ticket.dropShort();
    return;
  }

  if (await ticket.confirmWithout([for (final line in short) line.line])) return;
  if (!context.mounted) return;

  await posAnswerRefusal(context, ticket);
}
