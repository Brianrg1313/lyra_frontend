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
class StockBalance {
  const StockBalance({
    this.onHand = 0,
    this.reserved = 0,
    this.available = 0,
    this.returns = 0
  });

  final int onHand;
  final int reserved;
  final int available;
  final int returns;

  factory StockBalance.fromResponse(dynamic data) {
    if (data is! Map) return const StockBalance();

    return StockBalance(
      onHand: _int(data["onHand"] ?? data["ON_HAND"]),
      reserved: _int(data["reserved"] ?? data["RESERVED"]),
      available: _int(data["available"] ?? data["AVAILABLE"]),
      returns: _int(data["returns"] ?? data["RETURNS"])
    );
  }

  static int _int(dynamic raw) => switch (raw) {
    final num value => value.toInt(),
    final String text => int.tryParse(text) ?? 0,
    _ => 0
  };
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
    this.note = ""
  });

  final StockOperation operation;

  /// How many units. Always positive: the sign is set by the operation.
  final int quantity;

  /// The chosen reason, or null to let the backend put its own (a manual hold
  /// has no reasons: setting aside is setting aside).
  final StockReason? reason;

  /// The phrase explaining the movement. Optional for the backend, but it is
  /// what whoever audits this in a year reads.
  final String note;

  /// The body of the `POST`, with the table and the product that receive it.
  Map<String, dynamic> request({
    required String tableId,
    required String productId
  }) {
    final written = note.trim();

    return {
      "TABLE_ID": tableId,
      "PRODUCT_ID": productId,
      "QUANTITY": quantity,
      if (reason != null) "REASON": reason!.key,
      if (written.isNotEmpty) "NOTE": written
    };
  }
}
