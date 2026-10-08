import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:app/toolkit/toolkit.dart';

import './employee_confirm.dart';
import './employee_fact_frame.dart';

/// An open typed tile: its [field] (one input, or several in a row) and, once
/// it is [changed], the check that sends it. It is the one cell of the panel
/// in the brand color, lifted over its sheet: while a datum is open, it is
/// the only thing on the panel that is not settled. Escape anywhere inside it calls
/// [onCancel]; a press anywhere outside it calls [onOutside].
///
/// Outside is told apart by where the press lands ([TapRegion]), not by the
/// focus: a select inside the tile (a phone's code, a day's month) drops the
/// focus on purpose once an option is picked, and the tile must stay open.
class EmployeeEditFrame extends StatelessWidget {
  const EmployeeEditFrame({
    super.key,
    required this.icon,
    required this.label,
    required this.field,
    required this.saving,
    required this.changed,
    required this.onConfirm,
    required this.onCancel,
    required this.onOutside
  });

  final IconData icon;
  final String label;
  final Widget field;
  final bool saving;

  /// Something differs from what is saved; also kept while [saving].
  final bool changed;
  final void Function() onConfirm;
  final void Function() onCancel;

  /// A press outside the tile. The tile decides: a dropdown of its own is
  /// drawn outside it too, and a press there is not leaving.
  final void Function() onOutside;

  @override
  Widget build(BuildContext context) => TapRegion(
    onTapOutside: (_) => onOutside(),
    child: _tile(context)
  );

  Widget _tile(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface.line(
      color: scheme.surfaceOver,
      borderColor: scheme.primary,
      thickness: 1,
      radius: EmployeeFactFrame.radius,
      padding: EmployeeFactFrame.padding,
      child: EmployeeFactFrame(
        icon: icon,
        label: label,
        accent: scheme.primary,
        child: CallbackShortcuts(
          bindings: {const SingleActivator(LogicalKeyboardKey.escape): onCancel},
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: field),
              if (changed || saving) ...[
                SizedBox(width: AppSize.gap),
                EmployeeConfirm(saving: saving, action: onConfirm)
              ]
            ]
          )
        )
      )
    );
  }
}
