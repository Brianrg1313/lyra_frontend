import 'package:flutter/services.dart';

// PACKAGES
import 'package:intl/intl.dart';

/// A date from a spreadsheet cell: what was stored, understood.
///
/// It exists because a date column receives dates written any
/// way. Nobody types `2026-02-12` in a spreadsheet: they type `12/2/26`, or paste a
/// column from an Excel, or import a CSV that brings something else. Here they are all
/// recognized and written in a single way (see [stored]), so the table
/// converges on a real date without forcing anyone to write in the backend's
/// format.
///
/// **The day is the day.** It is never converted from time zone: the
/// expiry date of a product is a calendar day, not an instant,
/// and turning `2026-02-12T00:00:00Z` into local time would move it to the 11th in half of
/// America. What is read is what was stored.
///
/// The order of the numbers is resolved by how they are written and not by the
/// language:
///
/// - If the first one has four digits, it is the year (`2026-02-12`, `2026/02/12`).
/// - If not, it is the day (`12-02-2026`, `12/02/26`), which is how a
///   date is written in almost the whole world.
/// - And if with that the month goes past twelve but the day does not, they were the other
///   way around (`02/26/2026`): they are swapped instead of losing the date.
///
/// A two-digit year is completed in the nearest century (`26` is 2026, `98`
/// is 1998), which is what any spreadsheet does.
class ProductDate {
  const ProductDate._(this.at, {required this.hasTime});

  /// The understood date.
  final DateTime at;

  /// Whether what was stored carried a time, and not only a day.
  ///
  /// It is remembered because **not having a time is not the same as having it at zero**:
  /// an expiry date does not expire at midnight, it does not expire at
  /// any hour. Without this, showing it complete would invent a `12:00 AM` that
  /// nobody entered.
  final bool hasTime;

  /// Reads a date written any way, or `null` if that is not a date.
  ///
  /// Returning `null` is not an error to show: a cell with text that is not a
  /// date keeps being seen exactly as it was entered. While the datum is not a date,
  /// writing it as one would be asserting something that is not known.
  static ProductDate? parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final match = _pattern.firstMatch(text);

    if (match == null) {
      // What does not fit above but is ISO anyway: what the backend sends with
      // milliseconds and zone (`2026-02-12T00:00:00.000Z`).
      final iso = DateTime.tryParse(text);

      return iso == null
        ? null
        : ProductDate._(iso, hasTime: text.contains(":"));
    }

    final first = int.parse(match[1]!);
    final second = int.parse(match[2]!);
    final third = int.parse(match[3]!);

    // Four digits up front can only be a year; if not, the day goes up front.
    final yearFirst = match[1]!.length == 4;

    final year = yearFirst ? first : _century(third, match[3]!.length);
    var month = second;
    var day = yearFirst ? third : first;

    // `02/26/2026`: the month does not reach twenty-six and the day does. They were the other
    // way around. Only when the year was not up front: with the year up front the order is no longer
    // ambiguous (`2026-13-01` is not a date, it is not January 13).
    if (!yearFirst && month > 12 && day <= 12) (day, month) = (month, day);
    if (month < 1 || month > 12 || day < 1) return null;

    final withTime = match[4] != null;
    final hour = withTime ? _hour(int.parse(match[4]!), match[7]) : 0;
    final minute = withTime ? int.parse(match[5]!) : 0;
    final seconds = withTime && match[6] != null ? int.parse(match[6]!) : 0;

    if (hour < 0 || hour > 23 || minute > 59 || seconds > 59) return null;

    final at = DateTime(year, month, day, hour, minute, seconds);

    // `31/02/2026` does not exist: [DateTime] rolls it over to March 3 instead of
    // failing, so the date is accepted only if it came back whole.
    if (at.month != month || at.day != day) return null;

    return ProductDate._(at, hasTime: withTime);
  }

  /// The same date written the way the table stores it, or the raw text if that
  /// was not a date.
  ///
  /// It is what runs when leaving the cell: it is written in any format and
  /// ends up stored in one single one.
  static String normalize(String raw) => parse(raw)?.stored ?? raw;

  /// How it travels and how it is stored: `2026-02-12`, and with time `2026-02-12 12:30`.
  ///
  /// It goes with a space and not with ISO's `T` because it is also what is seen when
  /// reopening the cell to correct it, and it is the same form
  /// [DateTime.parse] understands anyway.
  String get stored =>
    hasTime ? "$_day ${_two(at.hour)}:${_two(at.minute)}" : _day;

  /// How it is read: `Feb 12, 2026`, in the app's language.
  ///
  /// The month names are not written by this app: `intl` brings them with the
  /// data loaded by `GlobalMaterialLocalizations`, so the date
  /// orders and translates itself wherever it is looked at.
  String short(String locale) => DateFormat.yMMMd(locale).format(at);

  /// The full date: `2026-02-12`, and with its time `2026-02-12 12:30 PM`.
  ///
  /// It is the one for reading an exact number —comparing two rows, copying the date elsewhere—
  /// and that is why the day goes in digits and the time in the language's clock (12-
  /// or 24-hour depending on the place). The time appears only if one was entered: see
  /// [hasTime].
  String full(String locale) =>
    hasTime ? "$_day ${DateFormat.jm(locale).format(at)}" : _day;

  String get _day =>
    "${at.year.toString().padLeft(4, "0")}-${_two(at.month)}-${_two(at.day)}";

  static String _two(int value) => value.toString().padLeft(2, "0");

  /// A two-digit year to the nearest century: up to `69` it is 2000 and from `70`
  /// up it is 1900, which is the window spreadsheets use.
  static int _century(int year, int digits) =>
    digits > 2 ? year : (year < 70 ? 2000 + year : 1900 + year);

  /// The time of a 12-hour clock converted to a 24-hour one, if it came with `am` or `pm`.
  static int _hour(int hour, String? meridiem) {
    if (meridiem == null) return hour;

    if (meridiem.toLowerCase().startsWith("p")) {
      return hour == 12 ? 12 : hour + 12;
    }

    return hour == 12 ? 0 : hour;
  }

  /// Three numbers separated by `-`, `/` or `.`, and behind them an optional time.
  ///
  /// Which of the three is the year is not decided here but by [parse]: here only the
  /// shape is recognized.
  static final RegExp _pattern = RegExp(
    r"^(\d{1,4})[-/.](\d{1,2})[-/.](\d{1,4})"
    r"(?:[\sT]+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(a\.?m\.?|p\.?m\.?)?)?$",
    caseSensitive: false
  );
}

/// The three things that can separate the numbers of a date.
final RegExp _separators = RegExp(r"[-/.]");

/// Writes the slash of a date when the space bar is pressed.
///
/// A date is typed with the numeric keyboard, where the separator is not: you have
/// to take your hand off, find the slash and come back. The thumb, on the other hand, is already
/// over the space. Thus `12 2 26` becomes `12/2/26` without moving the hand off the
/// numbers.
///
/// It puts the slash the date was already using —if it started with `-` it continues with
/// `-`— so as not to leave `2026-02/12`.
///
/// **The time's space stays a space.** With two separators already placed
/// the date is already complete, so what comes next is the time
/// (`2026-02-12 12:30`) and there the space is written as is. Without that
/// check there would be no way to type a date with a time.
///
/// It also does not write two separators in a row nor one at the beginning: a space that
/// separates nothing does not turn into anything, it simply does not enter.
class DateSeparatorFormatter extends TextInputFormatter {
  const DateSeparatorFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue value
  ) {
    // Only the freshly pressed key. Pasting a text with spaces, or deleting, does
    // not come through here: what is pasted is stored as it came and [ProductDate]
    // already understands it.
    if (value.text.length != old.text.length + 1) return value;

    final at = value.selection.baseOffset - 1;
    if (at < 0 || at >= value.text.length || value.text[at] != " ") return value;

    final before = value.text.substring(0, at);

    // The date is already complete: what follows is the time.
    if (_separators.allMatches(before).length >= 2) return value;

    final separator =
      before.isEmpty || _separators.hasMatch(before[before.length - 1])
        ? ""
        : before.contains("-") ? "-" : "/";

    return TextEditingValue(
      text: before + separator + value.text.substring(at + 1),
      selection: TextSelection.collapsed(
        offset: before.length + separator.length
      )
    );
  }
}
