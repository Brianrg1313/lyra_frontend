import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/money/money_summary_model.dart';

import '../money_format.dart';

/// Where the money of the window came in and went out through.
///
/// The two breakdowns answer different questions and that is why they are two
/// blocks and not one table with a column for each:
///
/// * **By method** —cash, transfer, mobile— is what a register is reconciled
///   against: the drawer is counted, the bank statement is read. A method goes
///   both ways, so it carries the two figures and the balance between them.
/// * **By concept** —a supplier, a refund, a settlement— is what the money was
///   for. A concept only goes one way (its direction is part of what it means),
///   so it carries one figure and its direction says which side of the screen
///   it belongs on.
///
/// They are grouped by settlement kind and not by the company's own accounts:
/// two bank accounts of one shop are both transfers, and "cuanto entro en
/// efectivo" is a question about the rail.
class MoneyBreakdown extends StatelessWidget {
  const MoneyBreakdown({super.key, required this.summary});

  final MoneySummary summary;

  /// Below this width the two blocks stop fitting side by side with their four
  /// columns and go one under the other. It is measured against the body of the
  /// section, not the window: the side bar takes its share first.
  static const double _twoColumns = 760;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final methods = _MethodsBlock(summary: summary);
      final concepts = _ConceptsBlock(summary: summary);

      if (constraints.maxWidth < _twoColumns) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            methods,
            SizedBox(height: AppSize.gap),
            concepts
          ]
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: methods),
          SizedBox(width: AppSize.gap),
          Expanded(child: concepts)
        ]
      );
    }
  );
}

/// A block over the body's sheet: a title and its rows.
class _Block extends StatelessWidget {
  const _Block({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface.over(
      padding: EdgeInsets.all(AppSize.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextMedium(
            title,
            bold: true,
            multiplier: 0.9,
            color: scheme.text.secondary
          ),
          SizedBox(height: AppSize.spaceXS),
          if (children.isEmpty)
            TextSmall(
              S.of(context).finance_breakdown_empty,
              color: scheme.text.secondary
            )
          else
            ...children
        ]
      )
    );
  }
}

/// What moved through each settlement kind.
class _MethodsBlock extends StatelessWidget {
  const _MethodsBlock({required this.summary});

  final MoneySummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return _Block(
      title: S.of(context).finance_by_method,
      children: [
        for (final row in summary.methods) Padding(
          padding: EdgeInsets.only(top: AppSize.gap),
          child: Row(children: [
            Expanded(child: TextSmall(
              // The backend writes the name; a kind it has no name for is
              // still drawn, with its code, rather than as a blank row.
              row.name.isNotEmpty ? row.name : row.method,
              ellipsis: true
            )),
            SizedBox(width: AppSize.gap),
            _Figure(
              value: row.income,
              currency: summary.currency,
              color: scheme.snackBar.success
            ),
            SizedBox(width: AppSize.spaceXS),
            _Figure(
              value: row.expense,
              currency: summary.currency,
              color: scheme.snackBar.error
            )
          ])
        )
      ]
    );
  }
}

/// What moved under each concept.
class _ConceptsBlock extends StatelessWidget {
  const _ConceptsBlock({required this.summary});

  final MoneySummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return _Block(
      title: S.of(context).finance_by_concept,
      children: [
        for (final row in summary.concepts) Padding(
          padding: EdgeInsets.only(top: AppSize.gap),
          child: Row(children: [
            Icon(
              row.direction.isIncoming ? CI.arrow_down : CI.arrow_top,
              size: AppSize.text * 0.9,
              color: row.direction.isIncoming
                ? scheme.snackBar.success
                : scheme.snackBar.error
            ),
            SizedBox(width: AppSize.gap),
            Expanded(child: TextSmall(
              row.name.isNotEmpty ? row.name : row.concept,
              ellipsis: true
            )),
            SizedBox(width: AppSize.gap),
            _Figure(
              value: row.total,
              currency: summary.currency,
              color: row.direction.isIncoming
                ? scheme.snackBar.success
                : scheme.snackBar.error
            )
          ])
        )
      ]
    );
  }
}

/// One amount of a breakdown row.
///
/// A zero is drawn dimmed and not hidden: in the methods block the two columns
/// have to line up top to bottom, and a missing figure would make a rail that
/// only took money in look like one that has no column at all.
class _Figure extends StatelessWidget {
  const _Figure({
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
