// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart' show AccountingExport;

/// The two files the accounting export makes (`money.md` M-60, M-61).
enum MoneyExportFormat {
  /// One workbook, a sheet per dataset: what a person opens.
  xlsx("xlsx", "xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"),

  /// A `.zip` with one CSV per dataset: what an accounting program imports.
  csv("csv", "zip", "application/zip");

  const MoneyExportFormat(this.value, this.extension, this.mimeType);

  /// What `export.accounting` takes as `format`.
  final String value;
  final String extension;
  final String mimeType;
}

/// The datasets an export can hold, in the order the file lists them.
const List<String> moneyExportDatasets = AccountingExport.datasets;

/// A period of whole calendar days, both ends included (M-60).
///
/// Only whole months and years are offered: an accountant closes by month, and
/// a typed date is where `03/04` starts meaning two different days.
class MoneyExportPeriod {
  const MoneyExportPeriod(this.from, this.to);

  final DateTime from;
  final DateTime to;

  /// The month [month] of [year] (the constructor rolls a month over).
  factory MoneyExportPeriod.month(int year, int month) =>
    MoneyExportPeriod(DateTime(year, month), DateTime(year, month + 1, 0));

  factory MoneyExportPeriod.year(int year) =>
    MoneyExportPeriod(DateTime(year), DateTime(year, 12, 31));

  /// `2026-09-01`: the calendar day as the master reads it, in the company's
  /// zone and not this device's.
  static String day(DateTime date) =>
    "${date.year.toString().padLeft(4, "0")}-"
    "${date.month.toString().padLeft(2, "0")}-"
    "${date.day.toString().padLeft(2, "0")}";

  String get key => "${day(from)}_${day(to)}";

  @override
  bool operator ==(Object other) =>
    other is MoneyExportPeriod && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// The body of `export.accounting`.
Map<String, dynamic> moneyExportRequest({
  required MoneyExportPeriod period,
  required Iterable<String> datasets,
  required MoneyExportFormat format
}) => {
  "from": MoneyExportPeriod.day(period.from),
  "to": MoneyExportPeriod.day(period.to),
  "datasets": [
    for (final name in moneyExportDatasets)
      if (datasets.contains(name)) name
  ],
  "format": format.value
};

/// The file's suggested name: `lyra-accounting-2026-09-01-2026-09-30.zip`.
String moneyExportName(MoneyExportPeriod period, MoneyExportFormat format) =>
  "lyra-accounting-${MoneyExportPeriod.day(period.from)}-"
  "${MoneyExportPeriod.day(period.to)}.${format.extension}";
