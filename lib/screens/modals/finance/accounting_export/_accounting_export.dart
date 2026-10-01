import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/money/money_export_request.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/finance/money_format.dart';

/// What the accounting export holds (`money.md` M-60): the period, the
/// datasets and the format.
///
/// The period is **a whole month or year, never typed in**: an accountant
/// closes by month, and two date boxes are where `03/04` starts meaning two
/// different days. The days are the company's, so the master reads them in its
/// own time zone.
///
/// It **returns the request and the file's name and fetches nothing**, like
/// every panel here; the tab exports and saves. Returns `null` when it was
/// closed without exporting.
Future<({Map<String, dynamic> request, String name, MoneyExportFormat format})?> showAccountingExport(
  BuildContext context
) => showSideModal(
  context: context,
  title: S.of(context).finance_export_title,
  builder: (context) => const AccountingExportModal()
).then((value) => value is ({Map<String, dynamic> request, String name, MoneyExportFormat format}) ? value : null);

/// The panel itself.
class AccountingExportModal extends StatefulWidget {
  const AccountingExportModal({super.key});

  @override
  State<AccountingExportModal> createState() => _AccountingExportModalState();
}

class _AccountingExportModalState extends State<AccountingExportModal> {
  final _form = FormController();

  /// This month, last month, the ten before them, this year and last year,
  /// by their key.
  late final Map<String, ({MoneyExportPeriod period, String label})> _periods = _offered();

  late final _period = InputController.select(
    key: "PERIOD",
    form: _form,
    obligatory: true,
    initial: _periods.keys.elementAt(1)
  );

  late final _format = InputController.select(
    key: "FORMAT",
    form: _form,
    initial: MoneyExportFormat.xlsx.value
  );

  /// Everything but the receivables, which stay empty while a master sells no
  /// credit (`money.md` money.receivable).
  final Set<String> _datasets = {
    for (final name in moneyExportDatasets) if (name != "receivables") name
  };

  bool _datasetsMissing = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Map<String, ({MoneyExportPeriod period, String label})> _offered() {
    final now = DateTime.now();
    final text = S.of(context);

    ({MoneyExportPeriod period, String label}) month(int back, [String? label]) {
      final period = MoneyExportPeriod.month(now.year, now.month - back);

      return (period: period, label: label ?? moneyMonthLabel(context, period.from));
    }

    final rows = [
      month(0, text.finance_export_this_month),
      month(1, text.finance_export_last_month),
      for (var back = 2; back < 12; back++) month(back),
      (period: MoneyExportPeriod.year(now.year), label: text.finance_export_this_year),
      (period: MoneyExportPeriod.year(now.year - 1), label: text.finance_export_last_year)
    ];

    return {for (final row in rows) row.period.key: row};
  }

  /// Same width as the rest of the panels of this app.
  static const double _width = 420;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      child: ScrollableWidget(
        padding: EdgeInsets.only(bottom: AppSize.padding),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: AppSize.spaceS),
            child: TextSmall(
              S.of(context).finance_export_subtitle,
              lines: 4,
              color: scheme.text.secondary
            )
          ),
          SelectInput(
            title: S.of(context).finance_export_period,
            placeholder: S.of(context).finance_export_period,
            controller: _period,
            options: [
              for (final MapEntry(:key, :value) in _periods.entries) SelectOption(
                value: key,
                placeholder: value.label,
                subtitle: "${moneyDayLabel(context, value.period.from)} – "
                  "${moneyDayLabel(context, value.period.to)}"
              )
            ],
            emptyText: S.of(context).finance_select_empty,
            searchable: false,
            maxOptions: 6,
            leftIcon: Icon(CI.calendar, color: scheme.icon)
          ),
          Padding(
            padding: EdgeInsets.only(bottom: AppSize.gap),
            child: TextSmall(
              S.of(context).finance_export_datasets,
              color: scheme.text.secondary
            )
          ),
          Wrap(
            spacing: AppSize.gap,
            runSpacing: AppSize.gap,
            children: [
              for (final name in moneyExportDatasets) _Dataset(
                title: _title(context, name),
                isActive: _datasets.contains(name),
                action: () => setState(() {
                  if (!_datasets.remove(name)) _datasets.add(name);
                  _datasetsMissing = false;
                })
              )
            ]
          ),
          if (_datasetsMissing) Padding(
            padding: EdgeInsets.only(top: AppSize.gap),
            child: TextSmall(
              S.of(context).finance_export_datasets_empty,
              color: scheme.snackBar.error
            )
          ),
          SizedBox(height: AppSize.spaceS),
          SelectInput(
            title: S.of(context).finance_export_format,
            placeholder: S.of(context).finance_export_format,
            controller: _format,
            options: [
              SelectOption(
                value: MoneyExportFormat.xlsx.value,
                placeholder: S.of(context).finance_export_xlsx,
                subtitle: S.of(context).finance_export_xlsx_hint
              ),
              SelectOption(
                value: MoneyExportFormat.csv.value,
                placeholder: S.of(context).finance_export_csv,
                subtitle: S.of(context).finance_export_csv_hint
              )
            ],
            emptyText: S.of(context).finance_select_empty,
            searchable: false,
            leftIcon: Icon(CI.documents_excel, color: scheme.icon)
          ),
          SizedBox(height: AppSize.spaceM),
          Button(title: S.of(context).finance_export, action: _submit)
        ]
      )
    );
  }

  static String _title(BuildContext context, String dataset) => switch (dataset) {
    "sales" => S.of(context).finance_export_sales,
    "sale_lines" => S.of(context).finance_export_sale_lines,
    "payments" => S.of(context).finance_export_payments,
    "receivables" => S.of(context).finance_export_receivables,
    _ => S.of(context).finance_export_stock_movements
  };

  /// Reads the panel and closes with the request.
  void _submit() {
    if (_datasets.isEmpty) {
      setState(() => _datasetsMissing = true);
      return;
    }

    final period = _periods[_period.selectedValue]?.period;
    if (period == null) return;

    final format = MoneyExportFormat.values.firstWhere(
      (value) => value.value == _format.selectedValue,
      orElse: () => MoneyExportFormat.xlsx
    );

    Navigator.pop(context, (
      request: moneyExportRequest(period: period, datasets: _datasets, format: format),
      name: moneyExportName(period, format),
      format: format
    ));
  }
}

/// A dataset that goes in the file or not.
class _Dataset extends StatelessWidget {
  const _Dataset({
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
    final color = isActive ? scheme.text.primary : scheme.text.secondary;

    return FeedbackButton(
      action: action,
      height: AppSize.button,
      message: title,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
      radius: AppSize.cornerInset(AppSize.gap),
      color: isActive ? scheme.line : scheme.surfaceOver,
      feedbackColor: scheme.lineOver,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isActive ? CI.check : CI.plus, size: AppSize.text, color: color),
          SizedBox(width: AppSize.gap),
          TextMedium(title, bold: isActive, multiplier: 0.9, color: color)
        ]
      )
    );
  }
}
