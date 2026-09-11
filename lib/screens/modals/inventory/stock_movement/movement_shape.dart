import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/stock/movements/stock_movement_model.dart';

/// Which of the two numbers of the summary is being touched.
enum StockCounter {
  /// What is left to sell (the book's `available`).
  stock,

  /// What is set aside for someone.
  reserved
}

/// Which way the movement goes: the left button takes, the right one put.
enum StockDirection { take, put }

/// Where the units of a movement go —or come from—.
///
/// It is what the form asks with the cards in the middle, and it is what the
/// endpoint chooses: taking from stock can be three different things, and each
/// one writes against a different place of the book.
enum MovementDestinationKind {
  /// They leave and do not come back: they were sold, broken, lost.
  leave,

  /// They are set aside for someone: they stop being for sale without leaving
  /// the warehouse.
  hold,

  /// A client brought them back: they come into the returns counter.
  returns,

  /// They come into the shelf.
  restock,

  /// A reservation that is released: they go back to being for sale.
  release
}

/// One of the things that can happen to the units of a movement: with what
/// endpoint it is written, what reasons it admits and what counter limits it.
class MovementDestination {
  const MovementDestination({
    required this.kind,
    required this.operation,
    required this.icon,
    this.reasons = const [],
    this.guard
  });

  final MovementDestinationKind kind;
  final StockOperation operation;
  final IconData icon;

  /// The reasons it offers. Empty when the operation has only one (setting
  /// aside is setting aside): then nothing is asked and the backend puts its
  /// own.
  final List<StockReason> reasons;

  /// Which counter has to reach for the movement to go through, or null if
  /// there is none.
  ///
  /// It is the same `guard` the backend applies inside the atomic write, put
  /// on this side to not offer a quantity that is going to be rejected. It
  /// does not replace it: the one that decides is still the backend, because
  /// between reading the summary and touching the button someone else could
  /// have sold.
  ///
  /// Null in the entries and the returns: adding goods does not depend on
  /// what there is, and what a client returns does not leave the shelf.
  final StockCounter? guard;

  /// What this option is called in the list.
  String title(BuildContext context) => switch (kind) {
    MovementDestinationKind.leave => S.of(context).stock_move_dest_leave,
    MovementDestinationKind.hold => S.of(context).stock_move_dest_reserve,
    MovementDestinationKind.returns => S.of(context).stock_move_dest_returns,
    MovementDestinationKind.restock => S.of(context).stock_move_add_stock,
    MovementDestinationKind.release => S.of(context).stock_move_take_reserved
  };

  /// The line that explains what happens to the units. It is the one that
  /// breaks the tie between two similar options, so it is also shown when the
  /// option is unique: there it is the only thing that says where they ended
  /// up.
  String? hint(BuildContext context) => switch (kind) {
    MovementDestinationKind.leave => S.of(context).stock_move_dest_leave_hint,
    MovementDestinationKind.hold => S.of(context).stock_move_dest_reserve_hint,
    MovementDestinationKind.returns =>
      S.of(context).stock_move_dest_returns_hint,
    MovementDestinationKind.restock => null,
    MovementDestinationKind.release => S.of(context).stock_move_release_hint
  };
}

/// The shape the movement form takes according to which button it was opened
/// from.
///
/// They are four buttons —take and put, on each of the two numbers— and a
/// single form, because the four ask the same thing: how many units, what
/// happens to them, and why. The only thing that changes between them is
/// **how many answers there are for the second question**, and this class
/// takes care of that.
///
/// The only one with more than one is taking from stock: units that leave the
/// shelf can have been sold, can be being set aside for someone, or can be a
/// return that just came in. The other three have only one —a reservation is
/// released to the shelf and nowhere else— and there the list is not drawn: it
/// is said in a line what is going to happen and the reason is asked, which is
/// the only thing left to decide.
class StockMovementShape {
  const StockMovementShape._({
    required this.counter,
    required this.direction,
    required this.destinations
  });

  /// Taking from stock: the three things that can happen to what leaves.
  ///
  /// The return is the odd one of the three and it is on purpose: the returns
  /// counter **does not leave the shelf** —what a client brings is in the
  /// store but is not goods yet—, so it has no cap and does not discount what
  /// is available. It is closed later, approving it (it goes back to sale) or
  /// discarding it.
  static const _takeStock = StockMovementShape._(
    counter: StockCounter.stock,
    direction: StockDirection.take,
    destinations: [
      MovementDestination(
        kind: MovementDestinationKind.leave,
        operation: StockOperation.remove,
        icon: CI.shopping_delete,
        guard: StockCounter.stock,
        reasons: [
          StockReason.sale,
          StockReason.damage,
          StockReason.loss,
          StockReason.expired,
          StockReason.theft,
          StockReason.removeCorrection
        ]
      ),
      MovementDestination(
        kind: MovementDestinationKind.hold,
        operation: StockOperation.reserve,
        icon: CI.bookmark,
        guard: StockCounter.stock
      ),
      MovementDestination(
        kind: MovementDestinationKind.returns,
        operation: StockOperation.receiveReturn,
        icon: CI.delivery,
        reasons: [
          StockReason.customer,
          StockReason.defective,
          StockReason.wrongItem,
          StockReason.warranty
        ]
      )
    ]
  );

  /// Adding to stock. Without a cap: how much goods came in today nobody
  /// knows except the one loading it.
  static const _putStock = StockMovementShape._(
    counter: StockCounter.stock,
    direction: StockDirection.put,
    destinations: [
      MovementDestination(
        kind: MovementDestinationKind.restock,
        operation: StockOperation.add,
        icon: CI.delivery_square,
        reasons: [
          StockReason.restock,
          StockReason.returnApproved,
          StockReason.addCorrection
        ]
      )
    ]
  );

  /// Releasing reservations: they go back to sale, always. The only thing
  /// asked is why they were released, which is what later answers how much of
  /// what is set aside never ends in a sale.
  static const _takeReserved = StockMovementShape._(
    counter: StockCounter.reserved,
    direction: StockDirection.take,
    destinations: [
      MovementDestination(
        kind: MovementDestinationKind.release,
        operation: StockOperation.unreserve,
        icon: CI.shopping,
        guard: StockCounter.reserved,
        reasons: [
          StockReason.reintegration,
          StockReason.holdExpired,
          StockReason.cancelled
        ]
      )
    ]
  );

  /// Setting aside: the units leave what is available, so the cap is put by
  /// the stock and not the reservations.
  static const _putReserved = StockMovementShape._(
    counter: StockCounter.reserved,
    direction: StockDirection.put,
    destinations: [
      MovementDestination(
        kind: MovementDestinationKind.hold,
        operation: StockOperation.reserve,
        icon: CI.bookmark,
        guard: StockCounter.stock
      )
    ]
  );

  factory StockMovementShape.of({
    required StockCounter counter,
    required StockDirection direction
  }) => switch ((counter, direction)) {
    (StockCounter.stock, StockDirection.take) => _takeStock,
    (StockCounter.stock, StockDirection.put) => _putStock,
    (StockCounter.reserved, StockDirection.take) => _takeReserved,
    (StockCounter.reserved, StockDirection.put) => _putReserved
  };

  final StockCounter counter;
  final StockDirection direction;
  final List<MovementDestination> destinations;

  /// Whether there is something to choose. With a single option the list is
  /// not drawn: a choice between one thing is not a choice.
  bool get picks => destinations.length > 1;

  /// The title of the modal, which is also where it is understood which
  /// number is being talked about.
  String title(BuildContext context) => switch ((counter, direction)) {
    (StockCounter.stock, StockDirection.take) =>
      S.of(context).stock_move_take_stock,
    (StockCounter.stock, StockDirection.put) =>
      S.of(context).stock_move_add_stock,
    (StockCounter.reserved, StockDirection.take) =>
      S.of(context).stock_move_take_reserved,
    (StockCounter.reserved, StockDirection.put) =>
      S.of(context).stock_move_add_reserved
  };

  /// What the button that writes it says.
  String action(BuildContext context) => direction == StockDirection.take
    ? S.of(context).stock_move_take_action
    : S.of(context).stock_move_add_action;
}