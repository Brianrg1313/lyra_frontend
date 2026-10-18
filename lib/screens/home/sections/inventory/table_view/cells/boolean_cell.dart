import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/inventory/field_boolean.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_view/sheet_theme.dart';

/// The cell of a `BOOLEAN` field: a switch. A tap on the cell flips it
/// (`SheetController.tap`), so there is no editor to open and nothing to type.
///
/// What is neither a yes nor a no (an imported «maybe») is shown as written, next to a
/// switch that is off: drawing only the switch would claim a «no» nobody wrote.
class BooleanCell extends StatelessWidget {
  const BooleanCell({
    super.key,
    required this.raw,
    required this.style,
    required this.editable
  });

  /// The stored value: a real boolean from the engine, or the text a draft holds.
  final dynamic raw;

  final TextStyle style;

  /// Whether a tap flips it. A read-only box is drawn dimmed.
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final sheet = SheetTheme.of(context);
    final scheme = sheet.scheme;
    final value = fieldBoolean(raw);
    final checked = value ?? false;
    final text = "${raw ?? ""}".trim();

    // A track one letter and a half tall: it has to be hit with the pointer without
    // making the row taller.
    final height = AppSize.text * 1.3;
    final width = height * 1.8;
    final inset = height * .15;
    final knob = height - inset * 2;
    const duration = Duration(milliseconds: 140);

    final box = Opacity(
      opacity: editable ? 1 : .5,
      child: AnimatedContainer(
        duration: duration,
        width: width,
        height: height,
        padding: EdgeInsets.all(inset),
        decoration: BoxDecoration(
          color: checked ? scheme.primary : scheme.line,
          borderRadius: BorderRadius.circular(height / 2)
        ),
        child: AnimatedAlign(
          duration: duration,
          curve: Curves.easeOut,
          alignment: checked ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: knob,
            height: knob,
            decoration: BoxDecoration(
              color: scheme.button.text,
              shape: BoxShape.circle
            )
          )
        )
      )
    );

    if (value != null || text.isEmpty) return Align(alignment: Alignment.centerLeft, child: box);

    return Row(children: [
      box,
      SizedBox(width: AppSize.gap),
      Expanded(child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style
      ))
    ]);
  }
}
