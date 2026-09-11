import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sale_fulfillment_request.dart';
import 'package:app/services/sales/sale_model.dart';
import 'package:app/services/sales/sale_stage_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// Records **how a sale reaches its customer, and how far that got**.
///
/// It is the one write the sales board makes, and it exists because it is the
/// one thing about a sale that no collection in this platform can see. The
/// ledger knows the units left the shelf, the ticket knows the money arrived,
/// the conversation knows what was agreed — and not one of them knows whether
/// the driver went out, or whether the customer came in and picked their box
/// up. Somebody has to say it, so this is where they say it.
///
/// **It returns the request body and writes nothing**, which is what this
/// module asks of every modal and what it has to do anyway: `SalesService` is
/// provided by the sales section, which lives *under* the navigator this panel
/// opens on. For the same reason the handover catalog comes in as a parameter —
/// whoever opens this has already read it.
///
/// Returns `null` when it was closed without recording anything.
Future<Map<String, dynamic>?> showSaleFulfillment(
  BuildContext context, {
  required SaleModel sale,
  required List<SaleHandoverMode> modes
}) => showSideModal(
  context: context,
  title: S.of(context).sales_handover_title,
  builder: (context) => SaleFulfillmentModal(sale: sale, modes: modes)
).then((value) => value is Map<String, dynamic> ? value : null);

/// The panel itself.
///
/// **It sets a fact and never a stage.** Where the sale then reads as standing
/// —"esperando el envío", "en camino", "esperando el retiro"— is computed on
/// the other side from these two words and handed back. A form that could write
/// the stage directly could put a delivery in the queue for a customer who is
/// coming to collect.
///
/// **The mode only travels when it changes.** Naming a mode moves the sale to
/// that mode's *opening* state, so re-sending the mode a delivery already has
/// would quietly walk a dispatched order back to "sin despachar" — somebody
/// opening this panel to write a tracking number would undo the dispatch. So
/// what is sent is the difference: the mode when it is a new one, the state when
/// it is a new one, and a refusal when neither is.
class SaleFulfillmentModal extends StatefulWidget {
  const SaleFulfillmentModal({
    super.key,
    required this.sale,
    required this.modes
  });

  /// The sale being handed over. Only a charged one gets here: an open invoice
  /// has not been paid for (the backend answers 409) and a conversation has no
  /// document at all.
  final SaleModel sale;

  /// The ways a sale can reach a customer, each with the states it can be in.
  /// The narrowing is the backend's: `dispatched` belongs to a delivery and to
  /// nothing else, and a counter handover is over by definition.
  final List<SaleHandoverMode> modes;

  @override
  State<SaleFulfillmentModal> createState() => _SaleFulfillmentModalState();
}

class _SaleFulfillmentModalState extends State<SaleFulfillmentModal> {
  final _form = FormController();

  /// Longest note. It is the line somebody reads a week later —a tracking
  /// number, who collected it— and not a document.
  static const int _maxNote = 200;

  /// Same width as the rest of the panels of this app.
  static const double _width = 420;

  /// The two pickers open on what the sale already says, so the panel reads as
  /// the state of this delivery and not as a blank form: the usual edit is one
  /// step forward from where it is, and the other field must not be retyped to
  /// take it.
  late final _mode = InputController.select(
    key: "MODE",
    form: _form,
    obligatory: true,
    initial: widget.sale.mode,
    customErrors: {
      InputError.empty: S.of(context).sales_handover_mode_error,
      // The field is not wrong, the form is: nothing on it differs from what
      // the sale already says. It is reported here because the mode is the
      // first control somebody looks at, and an error with no field is an
      // error nobody finds.
      InputError.invalid: S.of(context).sales_handover_same_error
    }
  );

  late final _state = InputController.select(
    key: "STATE",
    form: _form,
    initial: widget.sale.state
  );

  late final _note = InputController(
    key: "NOTE",
    form: _form,
    max: _maxNote
  );

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      // The panel is as tall as the window and the form is not. The bottom
      // padding is the panel's own, which it leaves out so that whatever
      // scrolls reaches the edge; the button is the last thing here and must
      // not sit on it.
      child: ScrollableWidget(
        padding: EdgeInsets.only(bottom: AppSize.padding),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Identity(sale: widget.sale),
          SizedBox(height: AppSize.spaceS),
          Padding(
            padding: EdgeInsets.only(bottom: AppSize.spaceS),
            child: TextSmall(
              S.of(context).sales_handover_subtitle,
              lines: 4,
              color: scheme.text.secondary
            )
          ),
          SelectInput(
            title: S.of(context).sales_handover_mode,
            placeholder: S.of(context).sales_handover_mode_placeholder,
            controller: _mode,
            options: [
              for (final mode in widget.modes) SelectOption(
                value: mode.mode,
                placeholder: mode.name
              )
            ],
            emptyText: S.of(context).sales_select_empty,
            leftIcon: Icon(CI.delivery, color: scheme.icon),
            onSelected: _pickMode
          ),
          // The states belong to the mode, so the field is only offered once
          // there is one: a picker whose options depend on an empty field is a
          // control that can only say the wrong thing.
          if (_states().isNotEmpty) SelectInput(
            title: S.of(context).sales_handover_state,
            placeholder: S.of(context).sales_handover_state_placeholder,
            controller: _state,
            options: [
              for (final state in _states()) SelectOption(
                value: state.state,
                placeholder: state.name
              )
            ],
            emptyText: S.of(context).sales_select_empty,
            leftIcon: Icon(CI.task_list, color: scheme.icon)
          ),
          Input(
            title: S.of(context).sales_handover_note,
            placeholder: S.of(context).sales_handover_note_placeholder,
            controller: _note,
            leftIcon: Icon(CI.edit, color: scheme.icon),
            onSubmit: _submit
          ),
          SizedBox(height: AppSize.spaceM),
          Button(title: S.of(context).sales_handover_save, action: _submit)
        ]
      )
    );
  }

  /// The states the picked mode can be in, empty while none is picked.
  List<SaleHandoverState> _states() => _modeOf(_mode.value)?.states ?? const [];

  SaleHandoverMode? _modeOf(String code) {
    if (code.isEmpty) return null;

    for (final mode in widget.modes) {
      if (mode.mode == code) return mode;
    }

    return null;
  }

  /// Another way of handing the sale over was picked.
  ///
  /// The state is cleared when the new mode cannot be in it —a dispatched
  /// delivery turned into a pickup, which has no middle— and it is cleared
  /// **here**, in the gesture, and not left to the select to notice when its
  /// options change: that would write a label into a controller while the tree
  /// is being rebuilt, which is a `setState` during build.
  void _pickMode(SelectOption option) {
    final mode = _modeOf(option.value);
    final current = _state.value;

    if (current.isNotEmpty && mode?.find(current) == null) {
      _state.selectedValue = null;
      _state.textController.text = "";
    }

    setState(() {});
  }

  /// Reads the form and closes with the body, or leaves the wrong field in red.
  ///
  /// What travels is the **difference** with what the sale already says (see
  /// the class doc): re-sending a mode a delivery already has would walk it
  /// back to its opening state. When there is no difference the panel refuses
  /// rather than writing a no-op that would restamp the sale's clock and move
  /// the row to the top of somebody else's board for nothing.
  void _submit() {
    if (!_mode.validate(_mode)) return;

    final mode = _mode.value;
    final state = _state.value;

    final movedMode = mode.isNotEmpty && mode != widget.sale.mode;
    final movedState = state.isNotEmpty && state != widget.sale.state;

    if (!movedMode && !movedState) {
      _mode.status.setStatus(InputStatus.error, InputError.invalid);
      _mode.focus.requestFocus();

      return;
    }

    _mode.status.setStatus(InputStatus.valid, null);

    Navigator.pop(context, fulfilSaleRequest(
      id: widget.sale.id,
      mode: movedMode ? mode : "",
      state: movedState ? state : "",
      note: _note.text
    ));
  }
}

/// Which sale this is, and where its handover stands right now.
///
/// It is at the top and read-only because the panel is opened from a row and
/// the row is the question: without it, two deliveries dispatched a minute
/// apart are the same blank form.
class _Identity extends StatelessWidget {
  const _Identity({required this.sale});

  final SaleModel sale;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface.over(
      padding: EdgeInsets.all(AppSize.spaceXS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextMedium(
            sale.customer.isEmpty ? sale.ticket : sale.customer,
            bold: true,
            ellipsis: true
          ),
          if (sale.customer.isNotEmpty && sale.ticket.isNotEmpty) ...[
            SizedBox(height: AppSize.gap),
            TextSmall(sale.ticket, ellipsis: true, color: scheme.text.secondary)
          ],
          SizedBox(height: AppSize.gap),
          TextSmall(
            sale.label,
            ellipsis: true,
            color: scheme.text.secondary
          )
        ]
      )
    );
  }
}
