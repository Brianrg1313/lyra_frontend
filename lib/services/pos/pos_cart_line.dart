// SERVICES
import 'package:app/services/pos/pos_invoice_model.dart';

/// One line of the ticket **as it is drawn** at the counter.
///
/// It is not a [PosProduct] and it is not the backend's line either: it is what
/// the panel needs to paint a row — what is being charged, at what price and how
/// many — kept apart from both because the two under it move for different
/// reasons. The catalog can be searched, filtered and reloaded underneath (every
/// one of those throws the products away and reads them again) and a ticket
/// pointing at those rows would lose its own lines to a search; the invoice, for
/// its part, answers one round trip behind the finger that is tapping.
///
/// A line is also not always a product: [productId] is null on the ones typed in
/// by hand (a delivery charge, something that is not in the catalog yet). Those
/// hold no stock and are addressed by their own [key], which is why they cannot
/// be edited until the backend has answered with one — see [isPending].
class PosCartLine {
  const PosCartLine({
    required this.key,
    required this.label,
    required this.price,
    required this.quantity,
    this.productId,
    this.held = 0,
    this.tracked = true,
    this.omitted = const [],
    this.modifiers = const []
  });

  /// What a key looks like before the backend has given the line its own.
  ///
  /// It is a prefix and not a flag because the key is what the +/− buttons
  /// address: a drafted line has to be addressable on screen from the instant it
  /// is drawn, and it must never be mistaken for an id the backend minted.
  static const String draft = "draft:";

  /// Identity of the line **within the ticket**, which is what the +/− buttons
  /// address: the backend's `lineId` once it is known, and a drafted key until
  /// then. Two typed-in charges written the same way are two lines, so it can
  /// never be what a line says.
  final String key;

  /// What is written on the ticket. For a product it is [PosProduct.label] as
  /// it read when it was added, not a live reference to the catalog row.
  final String label;

  /// Unit price. Never null here —a product with no price cannot be added— and
  /// it is what the backend froze on the line, so it is what will be charged.
  final double price;

  /// Units of this line. Always one or more: it drops off the ticket instead of
  /// reaching zero.
  final int quantity;

  /// The catalog record being sold, or null on an amount typed by hand.
  final String? productId;

  /// Units the shelf is actually holding for this line, which is not the same
  /// number as [quantity].
  ///
  /// They agree in every ordinary case, because putting a product on the ticket
  /// is what holds it. They come apart when the hold is taken away from
  /// somewhere else —released from the stock screen, lost to a crash— and that
  /// is the one thing a counter cannot find out by looking at its own ticket:
  /// the invoice goes on saying it holds them. Zero on a typed-in charge, which
  /// has no shelf to take anything off.
  final int held;

  /// Whether the product's stock is counted. False on a product whose table
  /// counts none (`pos.md` POS-6): it is sold without holds, so its [held] is
  /// zero and that says nothing about the shelf. Only a master answers false.
  final bool tracked;

  /// What a dish goes without, by name («without fries»), as the backend froze it.
  final List<String> omitted;

  /// What the customer chose on it («+ cheese», «medium»). Their prices are already in
  /// [price]: the backend's, never added here.
  final List<PosLineModifier> modifiers;

  /// Whether the line was typed in and does not point at any product.
  bool get isConcept => productId == null;

  /// Whether the units on this line are still set aside for this customer.
  ///
  /// A charge with no product, or a product nobody counts, is always "held":
  /// there is nothing to hold, so there is nothing that can be taken away
  /// either.
  bool get isHeld => isConcept || !tracked || held >= quantity;

  /// Whether the backend has not answered for this line yet.
  ///
  /// A product line is editable regardless —it is addressed by its product, and
  /// the register asks for "one more of this" rather than for a total— so this
  /// only holds back the typed-in charges, which have nothing to be pointed at
  /// until their id arrives.
  bool get isPending => key.startsWith(draft);

  /// What this line adds to the ticket, before tax.
  double get total => price * quantity;

  /// The same line with another quantity — and holding it, because asking for a
  /// unit more is asking for it to be held. It is drawn that way and corrected
  /// by the answer, like everything else on this ticket.
  PosCartLine withQuantity(int value) => PosCartLine(
    key: key,
    label: label,
    price: price,
    quantity: value,
    productId: productId,
    held: isConcept || !tracked ? 0 : value,
    tracked: tracked,
    omitted: omitted,
    modifiers: modifiers
  );

  /// The same line holding [value] units. It is what a shelf that no longer
  /// holds them writes onto the ticket.
  PosCartLine withHeld(int value) => PosCartLine(
    key: key,
    label: label,
    price: price,
    quantity: quantity,
    productId: productId,
    held: value,
    tracked: tracked,
    omitted: omitted,
    modifiers: modifiers
  );
}
