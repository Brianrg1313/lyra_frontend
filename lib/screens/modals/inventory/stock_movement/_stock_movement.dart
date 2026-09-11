import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/stock/movements/stock_movement_model.dart';
import 'package:app/services/stock/summary/stock_summary_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

import 'movement_option.dart';
import 'movement_shape.dart';
import 'quantity_field.dart';

export 'movement_shape.dart' show StockCounter, StockDirection;

/// Opens the movement form from one of the two buttons of a stock summary row.
///
/// The service is received from outside and not read here inside: the modal
/// hangs from the root navigator, far above where the inventory section
/// provides the summary, so a `context.read` from inside would not find it.
/// Whoever opens the modal has it at hand, which is the same listing that is
/// drawing it.
Future<void> showStockMovement(
  BuildContext context, {
  required StockSummaryService service,
  required String productId,
  required StockCounter counter,
  required StockDirection direction,
  required int stock,
  required int reserved
}) {
  final shape = StockMovementShape.of(counter: counter, direction: direction);

  return showModal(
    context: context,
    title: shape.title(context),
    // **Without `minWidth`**, even though this form has its own width: that
    // parameter is not a minimum width but the step to which the panel rounds
    // what it measures. The panel measures the form plus its own air, so
    // passing it the form width rounds it to the following multiple and the
    // box comes out twice as wide. The width is declared by the form inside.
    builder: (BuildContext context) => StockMovementModal(
      service: service,
      productId: productId,
      shape: shape,
      stock: stock,
      reserved: reserved
    )
  );
}

/// The form with which the stock of a product is moved without entering its
/// table.
///
/// It is the same for the four summary buttons —take and put, in the stock and
/// in the reservations— because the four ask the same thing: **how many
/// units**, **what happens to them** and **why**. What changes between them is
/// described by [StockMovementShape]; here only what that shape has to ask is
/// drawn.
///
/// The quantity has a cap when the movement comes out of a counter
/// ([MovementDestination.guard]) and does not have it when it comes in: how
/// much goods arrived today, or how much a client brought back, the summary
/// does not know. The cap on this side does not replace the backend one —which
/// is the one that decides, inside the same write that applies the change—
/// but avoids sending a quantity that is already known to be rejected.
///
/// It does not own the summary: it receives it ([service]) because it is the
/// owner of the table it writes against and the one that corrects the row when
/// the movement goes through. If the backend rejects, the modal stays open
/// with what was written: the error explains that there was not that much to
/// take, and correcting the quantity is a number, not refilling the form.
class StockMovementModal extends StatefulWidget {
  const StockMovementModal({
    super.key,
    required this.service,
    required this.productId,
    required this.shape,
    required this.stock,
    required this.reserved
  });

  /// Width of the form. It is a cap and not a fixed measurement: on desktop
  /// the modal lands at this width anyway —[showStockMovement] asks for it
  /// when opening— and on a narrow phone there is nothing that exceeds the
  /// screen.
  static const double width = 420;

  final StockSummaryService service;

  /// The product being written to, which is the id of the row record.
  final String productId;

  final StockMovementShape shape;

  /// What the row is showing today. It is what the subtitle and the cap come
  /// from, and that is why both numbers arrive even though only one was
  /// touched: setting units aside is limited by the stock, not by what is
  /// already reserved.
  final int stock;
  final int reserved;

  @override
  State<StockMovementModal> createState() => _StockMovementModalState();
}

class _StockMovementModalState extends State<StockMovementModal> {
  final _form = FormController();

  /// How many digits are accepted. Nine is more than any deposit and less
  /// than an overflow: the quantity travels as a number.
  static const int _digits = 9;

  /// By how much the two quantity buttons move.
  ///
  /// One is what serves in a counter, which is where most movements come from:
  /// one was sold, one came in, one is set aside. A business that moves boxes
  /// of ten counts by tens, so this is going to come out of a user preference;
  /// until then it lives written in a single place, which is the only one to
  /// touch when the preference exists.
  static const int _step = 1;

  /// What happens to the units. It starts on the first option, which is the
  /// common one —what leaves the stock was almost always sold— and the only
  /// one when the shape does not offer a choice.
  late MovementDestination _destination = widget.shape.destinations.first;

  /// The quantity error text, which **changes with the chosen option**: with a
  /// cap it says how much can be moved, and without it only that it has to be
  /// a number. That is why the map is mutable and is rewritten in each `build`:
  /// the error is read right when it is painted.
  final _quantityErrors = <InputError, String>{};

  late final _quantity = InputController(
    key: "QUANTITY",
    form: _form,
    pattern: "[0-9]",
    type: InputType.numeric,
    max: _digits,
    obligatory: true,
    customErrors: _quantityErrors
  );

  /// The chosen reason. The `value` of each option is the [StockReason] name
  /// and not its code: two reasons from different operations share the code
  /// (`correction`, `expiration`) and would be the same option.
  late final _reason = InputController.select(
    key: "REASON",
    form: _form,
    obligatory: true,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(
        S.of(context).stock_move_reason
      )
    }
  );

  /// The phrase that explains the movement. Optional for the backend, and it
  /// is what whoever audits this within a year reads.
  late final _note = InputController(
    key: "NOTE",
    form: _form,
    max: 240,
    customErrors: {
      InputError.long: S.of(context).form_long_ma(
        S.of(context).stock_move_note
      )
    }
  );

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// How much can be moved, or null when there is no cap.
  int? get _max => switch (_destination.guard) {
    StockCounter.stock => widget.stock,
    StockCounter.reserved => widget.reserved,
    null => null
  };

  /// The reasons the chosen option offers. Empty when there is nothing to
  /// ask: setting units aside is setting them aside.
  List<StockReason> get _reasons => _destination.reasons;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final max = _max;

    // The error is built before drawing the field: it is the only text of the
    // form that depends on the chosen option.
    _quantityErrors[InputError.empty] = S.of(context).form_empty_ma(
      S.of(context).stock_move_quantity
    );
    _quantityErrors[InputError.invalid] = max == null
      ? S.of(context).stock_move_quantity_error_free
      : S.of(context).stock_move_quantity_error(max);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // What is being talked about. It is first because it is what decides
        // the number that is going to be written below.
        Padding(
          padding: EdgeInsets.only(bottom: AppSize.spaceS),
          child: TextMedium(_subtitle(context))
        ),
        QuantityField(
          controller: _quantity,
          title: S.of(context).stock_move_quantity,
          placeholder: S.of(context).stock_move_quantity_placeholder,
          step: _step,
          // The same cap the submit validates, so the add button does not
          // write a number that is later going to be rejected.
          max: max,
          subtractMessage: S.of(context).stock_move_step_less(_step),
          addMessage: S.of(context).stock_move_step_more(_step),
          autofocus: true,
          // What was written stops being wrong as soon as it is corrected: an
          // error in red over a number that is already valid says nothing.
          onChanged: (_) => _clearQuantityError(),
          onSubmit: _submit
        ),
        if (widget.shape.picks)
          ..._options(context)
        else if (_destination.hint(context) != null)
          Padding(
            padding: EdgeInsets.only(
              left: AppSize.spaceXS,
              bottom: AppSize.spaceS
            ),
            child: TextSmall(
              _destination.hint(context)!,
              lines: 2,
              color: scheme.text.secondary
            )
          ),
        if (_reasons.isNotEmpty)
          SelectInput(
            // Changing the option changes the whole reason list: with the same
            // key the dropdown would keep showing the one chosen from the
            // previous list.
            key: ValueKey(_destination.kind),
            title: S.of(context).stock_move_reason,
            placeholder: S.of(context).stock_move_reason_placeholder,
            emptyText: S.of(context).stock_move_reason_empty,
            controller: _reason,
            options: StockReason.options(context, _reasons)
          ),
        Input(
          title: S.of(context).stock_move_note,
          placeholder: S.of(context).stock_move_note_placeholder,
          controller: _note,
          leftIcon: Icon(CI.pen, color: scheme.icon)
        ),
        SizedBox(height: AppSize.spaceM),
        Button(
          title: widget.shape.action(context),
          loading: _form.loading,
          action: _submit
        )
      ]
    );

    final form = ConstrainedBox(
      // The width goes **fixed** and not as a cap: the modal box measures
      // what its content measures, so a width with only a ceiling leaves it
      // at the width of the longest row inside —the explanation of an option,
      // written to be read in two lines and not in one—. Fixed is not a risk
      // on a narrow screen: what a child declares is clipped against what the
      // parent leaves it, so on a phone it comes out at the width of the
      // sheet.
      constraints: const BoxConstraints(
        minWidth: StockMovementModal.width,
        maxWidth: StockMovementModal.width
      ),
      // This is the longest form of the app —three options with their
      // explanation, the reason and the note— and in a low window it does not
      // fit. It scrolls inside instead of overflowing.
      child: SingleChildScrollView(child: content)
    );

    // And so that scroll is useful, the form needs to know how far it can
    // grow.
    //
    // On a phone sheet it already knows: the modal passes it bounded against
    // the screen. On the desktop panel it does not —it is passed the height
    // **unbounded**, stacks its header and what it is given, and if the sum
    // does not fit it overflows— and there it has to be asked for. [Flexible]
    // is how it is asked: it stops being "whatever the form measures" and
    // becomes "whatever is left after the header", which is exactly the slot
    // there is.
    //
    // The panel is asked about and not the screen size because it is a
    // question about **the shape of the tree**: `Flexible` needs a column
    // above, and the phone sheet does not have it. Guessing with a width
    // —which is what the `Responsive` breaks do— is answering something else.
    return context.findAncestorWidgetOfExactType<ModalDesktop>() == null
      ? form
      : Flexible(child: form);
  }

  /// The options of what happens to the units, when there is more than one.
  List<Widget> _options(BuildContext context) => [
    Padding(
      padding: EdgeInsets.only(bottom: AppSize.gap, left: AppSize.spaceXS),
      child: TextMedium(S.of(context).stock_move_destination)
    ),
    for (final destination in widget.shape.destinations) Padding(
      padding: EdgeInsets.only(bottom: AppSize.gap),
      child: MovementOption(
        icon: destination.icon,
        title: destination.title(context),
        hint: destination.hint(context),
        selected: destination == _destination,
        // Taking from a counter that is at zero cannot be done. The option is
        // shown the same, dimmed: its absence would be read as if the system
        // did not contemplate it.
        enabled: _limitOf(destination) != 0,
        action: () => _pick(destination)
      )
    ),
    SizedBox(height: AppSize.spaceXS)
  ];

  /// How much is left in the counter that limits [destination], or null if
  /// none limits it.
  int? _limitOf(MovementDestination destination) =>
    switch (destination.guard) {
      StockCounter.stock => widget.stock,
      StockCounter.reserved => widget.reserved,
      null => null
    };

  /// How much is available, written. It is the counter that puts the cap and
  /// not always the one that was touched: setting units aside is limited by
  /// the stock.
  String _subtitle(BuildContext context) =>
    switch (_destination.guard ?? widget.shape.counter) {
      StockCounter.stock => S.of(context).stock_move_available(widget.stock),
      StockCounter.reserved => S.of(context).stock_move_reserved(widget.reserved)
    };

  /// Something else was chosen for the units.
  ///
  /// The reason is emptied: the previous option's are from another operation
  /// and sending one of them is an `invalid_reason`. The quantity is kept
  /// —it is the same decision— but its error is cleared, because the cap just
  /// changed.
  void _pick(MovementDestination destination) {
    if (destination == _destination) return;

    setState(() => _destination = destination);

    _reason.selectedValue = null;
    _reason.textController.clear();
    _reason.status.setStatus(InputStatus.unreviewed, null);

    _clearQuantityError();
  }

  void _clearQuantityError() {
    if (_quantity.status.message == null) return;

    _quantity.status.setStatus(InputStatus.unreviewed, null);
  }

  Future<void> _submit() async {
    final quantity = int.tryParse(_quantity.text.trim());
    final max = _max;

    // The quantity is validated by hand and not with the form: a numeric field
    // does not bring a validator —the package only writes one for text, email
    // and code— and what has to be reviewed is not the length of what was
    // written but how much it is worth against a cap that changes with the
    // chosen option.
    if (quantity == null || quantity <= 0 || (max != null && quantity > max)) {
      _quantity.status.setStatus(
        InputStatus.error,
        quantity == null ? InputError.empty : InputError.invalid
      );
      _quantity.focus.requestFocus();

      return;
    }

    _quantity.status.setStatus(InputStatus.valid, null);

    StockReason? reason;

    if (_reasons.isNotEmpty) {
      if (!_reason.validate(_reason)) return;

      reason = StockReason.from(_reason.value, _reasons);

      // This is not reached unless the list and the chosen value got
      // desynchronized. Sending it anyway would be writing a movement with a
      // reason from another operation in the only place that exists to audit
      // it.
      if (reason == null) {
        _reason.status.setStatus(InputStatus.error, InputError.empty);
        return;
      }
    }

    if (!_note.validate(_note)) return;

    _form.loading.value = true;

    final saved = await widget.service.move(
      context,
      productId: widget.productId,
      movement: StockMovement(
        operation: _destination.operation,
        quantity: quantity,
        reason: reason,
        note: _note.text
      )
    );

    if (!mounted) return;

    _form.loading.value = false;

    // If it failed, the error was already shown: the modal stays open with
    // what was written to correct the quantity or close it by hand.
    if (!saved) return;

    FloatFlag.of(context).message(S.of(context).stock_move_saved);
    Navigator.pop(context);
  }
}