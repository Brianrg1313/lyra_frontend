import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// A value as every tile says it: an empty one in words and in grey, like
/// every empty value of the panel.
class EmployeeFactValue extends StatelessWidget {
  const EmployeeFactValue({super.key, required this.value, this.empty, this.lines = 1});

  final String value;
  final String? empty;
  final int lines;

  @override
  Widget build(BuildContext context) {
    final blank = value.trim().isEmpty;

    return TextMedium(
      blank ? (empty ?? "") : value,
      lines: lines,
      ellipsis: true,
      color: blank ? ThemeColor.of(context).text.secondary : null
    );
  }
}
