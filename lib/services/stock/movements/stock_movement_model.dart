import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/form.dart';

/// The five endpoints with which inventory is written
/// (`POST /inventory/stock/...`).
///
/// They are five and not one with a parameter because each one **moves
/// different counters**, and the backend separates them precisely for that:
/// adding and removing touch what is on the shelf, reserving and releasing move
/// units between what is left to sell and what is set aside, and a return
/// enters a counter of its own that is none of the others.
///
/// The **why** travels apart ([StockReason]) and is what decides, within a
/// single endpoint, where the units come from or go to. See
/// `models/inventory/reasons.js`, which is where that table lives.
enum StockOperation {
  /// Units enter the shelf: `on_hand +n`, `available +n`.
  add("/inventory/stock/add/"),

  /// Units leave the shelf: `on_hand -n`, `available -n`.
  remove("/inventory/stock/remove/"),

  /// They are set aside: `available -n`, `reserved +n`. They do not leave the
  /// warehouse, they stop being for sale.
  reserve("/inventory/stock/reserve/"),

  /// They are released: `reserved -n`, `available +n`.
  unreserve("/inventory/stock/unreserve/"),

  /// A client returned something: `returns +n`. **It does not go back to the
  /// shelf**: it stays waiting for someone to look at it, and from there it
  /// leaves with an [add] with reason `return` (approved) or with a `remove`
  /// with reason `discard`.
  receiveReturn("/inventory/stock/return/");

  const StockOperation(this.path);

  /// Endpoint path, without version (`api` sets it).
  final String path;
}

/// The **why** of a movement, as the backend expects it in `REASON`.
///
/// It is not a label hung on the movement afterwards: it is what decides which
/// counters move and, above all, it is the only way the ledger can answer later
/// "how much we lost to breakage last month". That question is about a reason,
/// not about a URL.
///
/// The same code can repeat across operations (`correction` exists for adding
/// and for removing, `expiration` for removing and for releasing a hold) and
/// that is why each value carries which [operation] it belongs to: sending a
/// reason of another operation is an `invalid_reason`, not a silent default.
enum StockReason {
  // Entries
  restock(StockOperation.add, "restock"),
  returnApproved(StockOperation.add, "return"),
  addCorrection(StockOperation.add, "correction"),

  // Exits
  sale(StockOperation.remove, "sale"),
  damage(StockOperation.remove, "damage"),
  loss(StockOperation.remove, "loss"),
  expired(StockOperation.remove, "expiration"),
  theft(StockOperation.remove, "theft"),
  removeCorrection(StockOperation.remove, "correction"),

  /// What is lost working (spilled wax, a cut gone wrong; `cocina-frontend.md` §7). The
  /// engine doesn't know it: offered only where `inventory.purchases` is.
  waste(StockOperation.remove, "waste"),

  // Returns
  customer(StockOperation.receiveReturn, "customer"),
  defective(StockOperation.receiveReturn, "defective"),
  wrongItem(StockOperation.receiveReturn, "wrong_item"),
  warranty(StockOperation.receiveReturn, "warranty"),

  // Holds that get released
  reintegration(StockOperation.unreserve, "reintegration"),
  holdExpired(StockOperation.unreserve, "expiration"),
  cancelled(StockOperation.unreserve, "cancelled");

  const StockReason(this.operation, this.key);

  /// Which operation it belongs to. A reason outside its operation does not
  /// exist.
  final StockOperation operation;

  /// The code that travels in `REASON`.
  final String key;

  /// Whether only the cloud knows it: the engine's catalogue (`StockOperations.reasons`)
  /// doesn't, so a screen offers it only where `inventory.purchases` is.
  bool get cloudOnly => this == waste;

  /// How it is named on screen.
  String label(BuildContext context) => switch (this) {
    restock => S.of(context).stock_reason_restock,
    returnApproved => S.of(context).stock_reason_return_approved,
    addCorrection || removeCorrection => S.of(context).stock_reason_correction,
    sale => S.of(context).stock_reason_sale,
    damage => S.of(context).stock_reason_damage,
    loss => S.of(context).stock_reason_loss,
    expired => S.of(context).stock_reason_expiration,
    theft => S.of(context).stock_reason_theft,
    waste => S.of(context).stock_reason_waste,
    customer => S.of(context).stock_reason_customer,
    defective => S.of(context).stock_reason_defective,
    wrongItem => S.of(context).stock_reason_wrong_item,
    warranty => S.of(context).stock_reason_warranty,
    reintegration => S.of(context).stock_reason_reintegration,
    holdExpired => S.of(context).stock_reason_hold_expired,
    cancelled => S.of(context).stock_reason_cancelled
  };

  /// The options of the reasons dropdown, in the order they are offered.
  static List<SelectOption> options(
    BuildContext context,
    List<StockReason> reasons
  ) => [
    for (final reason in reasons) SelectOption(
      value: reason.name,
      placeholder: reason.label(context)
    )
  ];

  /// The reason that was chosen, searched **within the ones that were
  /// offered**.
  ///
  /// It is searched by [name] and not by [key] because two reasons of different
  /// operations share a code (`correction`, `expiration`): with the key alone a
  /// removal by correction and an addition by correction would be the same
  /// option.
  static StockReason? from(String? value, List<StockReason> within) {
    for (final reason in within) {
      if (reason.name == value) return reason;
    }

    return null;
  }
}

/// The four counters of a product, as answered by any endpoint that writes
/// inventory.
///
/// `available` is always `onHand - reserved`, and `returns` stays **outside**
/// of `onHand`: what a client returned is in the store but is not merchandise
/// yet.
///
/// They are [num] and not `int`: a supply counts up to six decimals of its unit
/// (`cocina-frontend.md` §1); a catalog's product still answers whole numbers.
class StockBalance {
  const StockBalance({
    this.onHand = 0,
    this.reserved = 0,
    this.available = 0,
    this.returns = 0
  });

  final num onHand;
  final num reserved;
  final num available;
  final num returns;

  factory StockBalance.fromResponse(dynamic data) {
    if (data is! Map) return const StockBalance();

    return StockBalance(
      onHand: stockNum(data["onHand"] ?? data["ON_HAND"]) ?? 0,
      reserved: stockNum(data["reserved"] ?? data["RESERVED"]) ?? 0,
      available: stockNum(data["available"] ?? data["AVAILABLE"]) ?? 0,
      returns: stockNum(data["returns"] ?? data["RETURNS"]) ?? 0
    );
  }
}

/// A stock counter as it travels: whole numbers stay [int], a supply's decimals a [double].
num? stockNum(dynamic raw) => switch (raw) {
  final num value => value == value.roundToDouble() ? value.round() : value,
  final String text => stockNum(num.tryParse(text.trim())),
  _ => null
};

/// A stock figure written: a whole number as it is, a supply's up to six decimals with no
/// trailing zeros (`1.75`, never `1.750000`).
String stockFigure(num value) {
  if (value == value.roundToDouble()) return value.round().toString();

  return value.toStringAsFixed(6)
    .replaceFirst(RegExp(r"0+$"), "")
    .replaceFirst(RegExp(r"\.$"), "");
}

/// A movement ready to be written: how much, why and against which endpoint.
///
/// The form builds it and the summary service writes it, which is the one that
/// knows which table it is and which has to correct the row when the movement
/// goes in.
class StockMovement {
  const StockMovement({
    required this.operation,
    required this.quantity,
    this.reason,
    this.note = "",
    this.presentation = "",
    this.cost
  });

  final StockOperation operation;

  /// How many units —or presentations, with [presentation]—. Always positive:
  /// the sign is set by the operation. Decimals only on a supply.
  final num quantity;

  /// The chosen reason, or null to let the backend put its own (a manual hold
  /// has no reasons: setting aside is setting aside).
  final StockReason? reason;

  /// The phrase explaining the movement. Optional for the backend, but it is
  /// what whoever audits this in a year reads.
  final String note;

  /// The id of how it was bought («Saco» = 25 kg), or empty for units. With one,
  /// [quantity] counts presentations and the backend adds what they hold
  /// (`cocina-frontend.md` §8).
  final String presentation;

  /// What the **whole** purchase cost. Only a restock carries it: the backend
  /// refuses it on any other reason (`invalid_cost`), and it is where the cost
  /// of every dish comes from.
  final double? cost;

  /// The body of the `POST`, with the table and the product that receive it.
  Map<String, dynamic> request({
    required String tableId,
    required String productId
  }) {
    final written = note.trim();

    return {
      "TABLE_ID": tableId,
      "PRODUCT_ID": productId,
      "QUANTITY": stockNum(quantity) ?? quantity,
      if (reason != null) "REASON": reason!.key,
      if (written.isNotEmpty) "NOTE": written,
      if (presentation.isNotEmpty) "PRESENTATION": presentation,
      if (cost != null && reason == StockReason.restock) "COST": stockNum(cost) ?? cost
    };
  }
}
