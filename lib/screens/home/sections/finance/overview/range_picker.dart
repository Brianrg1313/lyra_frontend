import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/money/money_service.dart';

/// The window the summary is read over.
///
/// It is a row of options and not a date picker because that is how the
/// question is actually asked —"hoy", "este mes"— and because the four cover
/// what a shop looks at daily. A picker for an arbitrary period would be a
/// fifth option of this same control: the backend answers the same shape for
/// any window (see [MoneyService]), so nothing below it would change.
///
/// It does not store which one is on: it receives [range] and reports through
/// [onRange]. The one in charge is the service, which is what rereads — and it
/// is not always the same one: the tab's own window belongs to [MoneyService]
/// and the bot's card below it keeps a second window of its own, which is the
/// whole reason this control holds no state.
class MoneyRangePicker extends StatelessWidget {
  const MoneyRangePicker({
    super.key,
    required this.range,
    required this.onRange
  });

  final MoneyRange range;
  final void Function(MoneyRange range) onRange;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: [
      for (final value in MoneyRange.values) Padding(
        padding: EdgeInsets.only(right: AppSize.gap),
        child: _Range(
          title: _title(context, value),
          isActive: value == range,
          action: () => onRange(value)
        )
      )
    ])
  );

  static String _title(BuildContext context, MoneyRange range) =>
    switch (range) {
      MoneyRange.today => S.of(context).finance_range_today,
      MoneyRange.week => S.of(context).finance_range_week,
      MoneyRange.month => S.of(context).finance_range_month,
      MoneyRange.year => S.of(context).finance_range_year
    };
}

/// One option of the row.
///
/// The active one is filled with the line colour instead of the primary: the
/// summary below is already full of colour that means something —money in,
/// money out— and a coloured chip on top of it would read as a fifth figure.
class _Range extends StatelessWidget {
  const _Range({
    required this.title,
    required this.isActive,
    required this.action
  });

  final String title;
  final bool isActive;
  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: action,
      height: AppSize.button,
      message: title,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
      radius: AppSize.cornerInset(AppSize.gap),
      color: isActive ? scheme.line : scheme.surface,
      feedbackColor: scheme.lineOver,
      child: Center(child: TextMedium(
        title,
        bold: isActive,
        multiplier: 0.9,
        color: isActive ? scheme.text.primary : scheme.text.secondary
      ))
    );
  }
}
