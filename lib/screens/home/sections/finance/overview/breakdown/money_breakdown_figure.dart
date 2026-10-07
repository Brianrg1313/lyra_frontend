import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/finance/money_format.dart';

/// One amount of a breakdown row.
///
/// A zero is drawn dimmed and not hidden: in the methods block the two columns
/// have to line up top to bottom, and a missing figure would make a rail that
/// only took money in look like one that has no column at all.
class MoneyBreakdownFigure extends StatelessWidget {
  const MoneyBreakdownFigure({
    super.key,
    required this.value,
    required this.currency,
    required this.color
  });

  final double value;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) => TextSmall(
    moneyLabel(value, currency),
    color: value == 0 ? ThemeColor.of(context).text.secondary : color
  );
}
