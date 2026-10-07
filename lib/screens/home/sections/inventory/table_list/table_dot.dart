import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES

// WIDGETS

/// A table's colour, as a dot: an adornment, so a colour that doesn't read is no dot.
class TableDot extends StatelessWidget {
  const TableDot({super.key, required this.color});

  /// Flutter ARGB literal (`0xFF2196F3`).
  final String color;

  @override
  Widget build(BuildContext context) {
    final parsed = int.tryParse(color);

    return Container(
      width: AppSize.text * 0.75,
      height: AppSize.text * 0.75,
      decoration: BoxDecoration(
        color: parsed == null ? ThemeColor.of(context).text.secondary : Color(parsed),
        shape: BoxShape.circle
      )
    );
  }
}
