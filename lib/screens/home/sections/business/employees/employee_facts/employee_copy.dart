import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:app/toolkit/toolkit.dart';

/// Copies [value] and says which datum went to the clipboard.
Future<void> employeeCopy(BuildContext context, String value, String label) async {
  await Clipboard.setData(ClipboardData(text: value));

  if (!context.mounted) return;

  FloatFlag.of(context).message(S.of(context).employee_copied(label));
}
