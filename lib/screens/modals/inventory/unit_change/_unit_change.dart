import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/inventory/measure_units.dart';
import 'package:app/services/stock/movements/stock_movement_model.dart' show stockFigure;

/// What a unit change does to the figures already written.
enum UnitChange {
  /// They follow it: 30 kg become 30 000 g.
  convert,

  /// Only the word changes: 30 kg read 30 g, which is what fixing a unit that was wrong is.
  keep
}

/// Asks what a change of unit does to the figures, when they can follow it: [from] and [to]
/// measure the same thing ([measureFactor] is not null), so 30 kg can become 30 000 g, or stay
/// 30 and read 30 g. Converting comes chosen: changing the unit of something that was counted
/// right is the common case, and the other one is a mistake being fixed.
///
/// [figure] is the one shown in the example (the product's stock); without one, or at 0, the
/// example is one of [from]. [note] says what else follows (the presentations and recipes of a
/// product, every row of a column). `null` when it is cancelled.
Future<UnitChange?> askUnitChange(
  BuildContext context, {
  required String from,
  required String to,
  required double factor,
  required String note,
  num? figure
}) async {
  final s = S.of(context);
  final count = s.product_table_view_unit_count_symbol;
  String named(String unit) => unit.isEmpty ? count : unit;
  String written(num value, String unit) => "${stockFigure(value)} ${named(unit)}";

  final example = figure == null || figure == 0 ? 1 : figure;
  final choice = ValueNotifier(UnitChange.convert);

  final confirmed = await showAlertModal(
    context: context,
    title: s.unit_change_title(named(from), named(to)),
    body: _Choices(
      choice: choice,
      convert: s.unit_change_convert_detail(written(example, from), written(measureConvert(example, factor), to)),
      keep: s.unit_change_keep_detail(written(example, from), written(example, to)),
      note: note
    ),
    confirmText: s.unit_change_confirm,
    cancelText: s.cancel
  );

  final picked = choice.value;
  choice.dispose();

  return confirmed ? picked : null;
}

/// The two answers, one under the other, the one chosen marked.
class _Choices extends StatelessWidget {
  const _Choices({required this.choice, required this.convert, required this.keep, required this.note});

  final ValueNotifier<UnitChange> choice;
  final String convert;
  final String keep;
  final String note;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    return ValueListenableBuilder<UnitChange>(
      valueListenable: choice,
      builder: (context, picked, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Choice(
            title: s.unit_change_convert,
            detail: convert,
            selected: picked == UnitChange.convert,
            onTap: () => choice.value = UnitChange.convert
          ),
          SizedBox(height: AppSize.gap),
          _Choice(
            title: s.unit_change_keep,
            detail: keep,
            selected: picked == UnitChange.keep,
            onTap: () => choice.value = UnitChange.keep
          ),
          SizedBox(height: AppSize.spaceS),
          TextSmall(
            picked == UnitChange.convert ? note : s.unit_change_keep_note,
            color: scheme.text.secondary,
            lines: 3
          )
        ]
      )
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.title, required this.detail, required this.selected, required this.onTap});

  final String title;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: onTap,
      radius: AppSize.corner,
      color: selected ? scheme.surfaceOver : scheme.surface,
      padding: EdgeInsets.all(AppSize.spaceS),
      child: Row(children: [
        Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          size: AppSize.text * 1.4,
          color: selected ? scheme.primary : scheme.text.secondary
        ),
        SizedBox(width: AppSize.spaceS),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextMedium(title, bold: true),
          SizedBox(height: AppSize.gap * 0.5),
          TextSmall(detail, color: scheme.text.secondary, lines: 2)
        ]))
      ])
    );
  }
}
