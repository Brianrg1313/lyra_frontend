import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/form/style.dart';

/// The quantity field of a movement, with a button on each side that moves it
/// one step at a time.
///
/// The buttons are not a shortcut of the numeric keyboard: they are **the**
/// gesture of this form. Most counter movements are of one, two or three units
/// —one was sold, two came in, one is set aside— and for that touching a
/// button is faster and mistakes less than writing a number. The field keeps
/// being there for the big loads, which is when writing wins.
///
/// **The step is a parameter and not a one written inside** ([step]): a
/// business that moves boxes of ten counts by tens, and that setting is going
/// to come out of a user preference. Today it arrives at one from the form,
/// which is the only thing that has to change when the preference exists.
///
/// The field is drawn disassembled —the title, the box and the error
/// separately— and not with a whole [Input] inside a row, because an [Input]
/// brings its title above and its error row below: put in the row, the buttons
/// would end up centered against the three and not against the box. It is what
/// [InputRow] does for several fields in a row, and that is why its same
/// pieces are used ([FormStyle]): the box looks like any other field of the
/// form.
class QuantityField extends StatefulWidget {
  const QuantityField({
    super.key,
    required this.controller,
    required this.title,
    required this.placeholder,
    this.step = 1,
    this.min = 1,
    this.max,
    this.subtractMessage,
    this.addMessage,
    this.autofocus = false,
    this.onChanged,
    this.onSubmit
  });

  final InputController controller;

  final String title;
  final String placeholder;

  /// How much the buttons move. One until the preference does not exist.
  final int step;

  /// The floor: a movement of zero units is not a movement.
  final int min;

  /// The ceiling, or null when there is none. It is the same cap the form
  /// validates when submitting, so the add button never writes a number that
  /// is later going to be rejected.
  final int? max;

  final String? subtractMessage;
  final String? addMessage;

  final bool autofocus;

  /// What is typed, as soon as it is typed. It is what clears the error as
  /// soon as the number is corrected, without waiting for typing to stop.
  final void Function(String value)? onChanged;

  final VoidCallback? onSubmit;

  @override
  State<QuantityField> createState() => _QuantityFieldState();
}

class _QuantityFieldState extends State<QuantityField> {
  @override
  void initState() {
    super.initState();

    // The buttons turn on and off with what the field says —nothing is
    // subtracted below the floor nor added above the cap— so they have to be
    // repainted with each key, not only with each touch.
    widget.controller.textController.addListener(_listener);
    widget.controller.form.loading.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.textController.removeListener(_listener);
    widget.controller.form.loading.removeListener(_listener);

    super.dispose();
  }

  void _listener() => mounted ? setState(() {}) : null;

  /// What is written, or null if it is not a number (the field is empty: it
  /// only admits digits).
  int? get _value => int.tryParse(widget.controller.text.trim());

  bool get _loading => widget.controller.form.loading.value;

  /// Subtracting needs something to subtract from. With the empty field it is
  /// not turned off for neatness: it is not known from which number it would
  /// be going down.
  bool get _canSubtract {
    final value = _value;

    return !_loading && value != null && value > widget.min;
  }

  bool get _canAdd {
    if (_loading) return false;

    final max = widget.max;
    final value = _value;

    // With the empty field the button writes one step, so it is enough that
    // the floor fits in the cap: a counter at zero does not offer adding
    // anything.
    if (value == null) return max == null || widget.min <= max;

    return max == null || value < max;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FormStyle.titleBuilder(context, widget.title),
      Row(children: [
        _Step(
          sign: "−",
          message: widget.subtractMessage,
          action: _canSubtract ? () => _move(-widget.step) : null
        ),
        SizedBox(width: AppSize.gap),
        Expanded(child: _Box(
          controller: widget.controller,
          placeholder: widget.placeholder,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          onSubmit: widget.onSubmit
        )),
        SizedBox(width: AppSize.gap),
        _Step(
          sign: "+",
          message: widget.addMessage,
          action: _canAdd ? () => _move(widget.step) : null
        )
      ]),
      // The error repaints itself: the field no longer draws it, and the one
      // who writes it is the form when validating.
      ListenableBuilder(
        listenable: widget.controller.status,
        builder: (context, _) =>
          FormStyle.errorBuilder(context, widget.controller)
      )
    ]
  );

  /// Moves the quantity one step, without leaving the floor or the cap.
  ///
  /// Over an empty field, adding writes **one step** and not a one: whoever
  /// counts by tens expects ten from the first touch. Subtracting does not get
  /// here with the empty field —its button is off— because it is not known
  /// from which number it would go down.
  void _move(int delta) {
    final max = widget.max;
    final current = _value;

    var next = current == null ? widget.step : current + delta;

    if (next < widget.min) next = widget.min;
    if (max != null && next > max) next = max;

    final written = next.toString();

    widget.controller.textController.value = TextEditingValue(
      text: written,
      selection: TextSelection.collapsed(offset: written.length)
    );

    // What a button writes always fits: there is no error to leave in red.
    widget.controller.status.setStatus(InputStatus.unreviewed, null);
  }
}

/// The number box.
///
/// It is its own field and not an [Input] for a single reason: **the number
/// goes centered**. A quantity is not a text read from left to right but a
/// figure between two buttons that move it, and leaning against the left edge
/// it is read as if it were not part of the control. The package [Input] does
/// not offer which side what is written leans on, and adding it is touching
/// the field of all the forms of all the apps for a case that is this one.
///
/// It looks like any other field —the same fill, the same border, the same
/// red border when something is wrong— because [FormStyle] takes care of
/// that, which is where the decoration of all of them comes from.
///
/// What it does **not** bring is the valid or error mark on the right. It is
/// not an omission: that icon takes one side and not the other, and over a
/// centered number it looks as if it were shifted. What was wrong keeps being
/// said with the border and with the row below.
class _Box extends StatefulWidget {
  const _Box({
    required this.controller,
    required this.placeholder,
    required this.autofocus,
    this.onChanged,
    this.onSubmit
  });

  final InputController controller;
  final String placeholder;
  final bool autofocus;

  final void Function(String value)? onChanged;
  final VoidCallback? onSubmit;

  @override
  State<_Box> createState() => _BoxState();
}

class _BoxState extends State<_Box> {
  @override
  void initState() {
    super.initState();

    // The same thing [Input] does when it mounts: without this the controller
    // does not stay registered in the form, and the form does not release it
    // when closing.
    widget.controller.findForm();

    // The border changes with the focus, so it has to be repainted when it
    // enters and when it leaves.
    widget.controller.focus.addListener(_listener);
    widget.controller.form.loading.addListener(_listener);

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.controller.focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.focus.removeListener(_listener);
    widget.controller.form.loading.removeListener(_listener);

    super.dispose();
  }

  void _listener() => mounted ? setState(() {}) : null;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller.status,
    builder: (context, child) => Container(
      width: double.infinity,
      height: AppSize.action,
      decoration: FormStyle.decoration(
        context,
        widget.controller.status,
        widget.controller.focus.hasFocus
      ),
      child: child
    ),
    child: Center(child: TextField(
      focusNode: widget.controller.focus,
      controller: widget.controller.textController,
      // While saving nothing is written, same as in the rest of the form.
      enabled: !widget.controller.form.loading.value,
      style: FormStyle.text(context),
      textAlign: TextAlign.center,
      keyboardType: FormStyle.keyboardType(widget.controller.type),
      // Units: there is no comma, no sign, nothing that is not a digit.
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: widget.onChanged,
      onSubmitted: (_) => widget.onSubmit?.call(),
      decoration: InputDecoration(
        filled: true,
        hintText: widget.placeholder,
        fillColor: Colors.transparent,
        hoverColor: Colors.transparent,
        border: FormStyle.voidBorder(context),
        hintStyle: FormStyle.placeholder(context),
        errorBorder: FormStyle.voidBorder(context),
        focusedBorder: FormStyle.voidBorder(context),
        enabledBorder: FormStyle.voidBorder(context),
        focusedErrorBorder: FormStyle.voidBorder(context),
        contentPadding: EdgeInsets.symmetric(horizontal: AppSize.padding)
      )
    ))
  );
}

/// One of the two buttons of the field.
///
/// It is square and the height of the box so the row reads as a single
/// control, and it goes over the fill and the border of the field for the
/// same reason: they are three pieces of one, not a field with two loose
/// buttons around.
///
/// The sign goes written and not drawn with an icon because there is no minus
/// in the icon set, and an icon plus next to a text minus would be read with
/// different weights. Both written, they are the same stroke.
class _Step extends StatelessWidget {
  const _Step({required this.sign, required this.action, this.message});

  final String sign;
  final String? message;

  /// Null when that step would leave the floor or the cap. Without an action
  /// the button stops responding to tap and keyboard.
  final void Function()? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final enabled = action != null;

    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: FeedbackButton(
        action: action,
        message: message,
        mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
        width: AppSize.action,
        height: AppSize.action,
        radius: AppSize.corner,
        color: scheme.input.fill,
        feedbackColor: scheme.input.focus,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSize.corner),
            border: Border.all(color: scheme.input.border)
          ),
          child: Center(child: TextMedium(
            sign,
            bold: true,
            textAlign: TextAlign.center,
            color: scheme.text.secondary
          ))
        )
      )
    );
  }
}