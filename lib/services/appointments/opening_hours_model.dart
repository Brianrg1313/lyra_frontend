// SERVICES
import 'package:app/services/catalog/catalog_table.dart';

/// One stretch of a weekday a branch attends (`GET /appointments/hours`):
/// `weekday` 0 (Sunday) to 6 (Saturday) and the minutes from midnight, all in
/// the company's own zone. A day with a lunch break is two stretches.
///
/// A row with a [service] narrows that weekday for that one service and
/// replaces the branch's stretches for it; it is not the branch's own week and
/// the week editor never shows it, but sends it back untouched (a week is
/// written whole, every row of the branch).
class OpeningStretch {
  const OpeningStretch({
    required this.weekday,
    required this.opens,
    required this.closes,
    this.branch,
    this.service
  });

  final int weekday;

  /// Minutes from the company's midnight.
  final int opens;
  final int closes;

  final String? branch;
  final String? service;

  /// `HH:MM`, as the hours are typed and read.
  static String clock(int minutes) =>
    "${(minutes ~/ 60).toString().padLeft(2, "0")}:${(minutes % 60).toString().padLeft(2, "0")}";

  /// Minutes from `HH:MM` (or `H:MM`, or `HHMM`), or null when it isn't a time
  /// of day. `24:00` is the end of the day, as a closing hour.
  static int? minutes(String text) {
    final match = RegExp(r"^(\d{1,2}):?(\d{2})$").firstMatch(text.trim());
    if (match == null) return null;

    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);

    if (minutes > 59 || hours > 24 || (hours == 24 && minutes > 0)) return null;

    return hours * 60 + minutes;
  }

  static List<OpeningStretch> list(dynamic data) => [
    for (final row in catalogRows(data))
      if (_int(row["weekday"]) case final int weekday)
        if (_int(row["opens"]) case final int opens)
          if (_int(row["closes"]) case final int closes)
            OpeningStretch(
              weekday: weekday,
              opens: opens,
              closes: closes,
              branch: _text(row["branch"]).isEmpty ? null : _text(row["branch"]),
              service: _text(row["service"]).isEmpty ? null : _text(row["service"])
            )
  ];
}

/// A day the timetable does not apply to (`GET /appointments/closures`): for
/// one branch, or for every branch ([branch] null, a national holiday).
class ClosedDay {
  const ClosedDay({required this.day, this.reason = "", this.branch});

  /// `YYYY-MM-DD` in the company's zone: a calendar day, not a moment.
  final String day;
  final String reason;
  final String? branch;

  bool get everywhere => branch == null;

  static List<ClosedDay> list(dynamic data) => [
    for (final row in catalogRows(data))
      if (_text(row["day"]).isNotEmpty) ClosedDay(
        day: _text(row["day"]),
        reason: _text(row["reason"]),
        branch: _text(row["branch"]).isEmpty ? null : _text(row["branch"])
      )
  ];
}

String _text(dynamic value) => value?.toString().trim() ?? "";

int? _int(dynamic value) => switch (value) {
  final num number => number.toInt(),
  final String text => int.tryParse(text.trim()),
  _ => null
};
