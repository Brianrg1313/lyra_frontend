import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';

/// The one action of the tab, on its own line above the filters: everything
/// else here reads, and this is the only thing that writes.
class PaymentsBar extends StatelessWidget {
  const PaymentsBar({super.key, required this.onRecord});

  final void Function() onRecord;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Button(
        width: null,
        title: S.of(context).finance_payments_record,
        leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
        action: onRecord
      )
    ]
  );
}
