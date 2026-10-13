/// The rules of the list of an `OPTIONS` or `CATEGORIES` field: what counts as
/// a new option, what is the one that already existed, and —in the second one, where a cell
/// stores several— how that list of labels is read and written.
///
/// They live apart from the screen because they are not of the screen: they are what decides
/// whether writing "rojo" in a list that already has "Rojo" adds an option or picks
/// the existing one. No network and no widgets, so they are tested on their own.
library;

import 'package:core/kit/str.dart';

/// When two options are the same.
///
/// They are compared the way the dropdown search compares them ([Str.clear]:
/// ignoring case and accents), and for the same reason: two options that only
/// differ in that would be indistinguishable when choosing them, so they cannot
/// coexist in a list.
bool sameFieldOption(String a, String b) => Str.clear(a) == Str.clear(b);

/// The option in [options] that is already [option], or `null` if it is not there.
///
/// It is what allows creating a repeated option to neither fail nor duplicate anything:
/// the one that already existed is chosen, which is what whoever wrote it meant.
String? fieldOptionLike(List<String> options, String option) {
  final wanted = option.trim();
  if (wanted.isEmpty) return null;

  for (final current in options) {
    if (sameFieldOption(current, wanted)) return current;
  }

  return null;
}

/// The field list with [option] added **at the end**, or `null` if there is nothing
/// to add: the option is empty or already in the list.
///
/// It goes at the end and not sorted alphabetically because the list order is the
/// order in which it is offered, and that is set by whoever builds it: the options were
/// written in some order and a new one is the last one thought of, not one that
/// sneaks in the middle.
///
/// Returning `null` is what distinguishes "there is something to save" from "there is no need
/// to write anything to the backend", which is the difference between a request and
/// none.
List<String>? fieldOptionsWith(List<String> options, String option) {
  final wanted = option.trim();
  if (wanted.isEmpty) return null;

  if (fieldOptionLike(options, wanted) != null) return null;

  return [...options, wanted];
}

/// The separators with which a multi-label cell travels
/// (`TableFieldType.categories`). They are the same three the backend splits with when
/// storing it, and they are here because they are the ones a label **cannot** carry:
/// writing one with a comma inside splits it in two on the other side.
final RegExp _labelSeparators = RegExp(r"[,;|]");

/// The labels a cell has loaded, read from what was stored.
///
/// The list is accepted —which is how the backend stores a multi-value cell— and
/// also the text, because the same datum arrives both ways: a cell that
/// was just chosen is still in the row draft, and there the values
/// are text (see `SheetDrafts`). A text is split by the same separators
/// the backend splits with.
///
/// What cannot be read yields an empty list: a strange cell is seen blank and
/// is chosen again, which is better than breaking the whole row.
List<String> fieldLabelsOf(dynamic raw) {
  if (raw == null) return const [];

  if (raw is List) {
    return [
      for (final label in raw)
        if (label != null && label.toString().trim().isNotEmpty)
          label.toString().trim()
    ];
  }

  return [
    for (final label in raw.toString().split(_labelSeparators))
      if (label.trim().isNotEmpty) label.trim()
  ];
}

/// The labels of a cell written to be read (`Zapatos, Deportivos`).
///
/// It is what is seen in the cell and in the summary: the `toString()` of a list
/// (`[Zapatos, Deportivos]`) shows Dart's brackets, which are not part of
/// anyone's datum.
String fieldLabelsText(dynamic raw) => fieldLabelsOf(raw).join(", ");

/// The labels as they are sent to the backend: the same line that is read,
/// which on the other side gets split again by the same separators.
///
/// It travels as text and not as a list because it is the path a cell already has:
/// a draft stores text and a correction sends text (see
/// `SheetController.finishRecord`), and the backend accepts both forms on
/// purpose —"a string is what a spreadsheet sends"—. Empty is what clears
/// the cell.
String fieldLabelsValue(List<String> labels) => [
  for (final label in labels)
    if (label.trim().isNotEmpty) label.trim()
].join(", ");
