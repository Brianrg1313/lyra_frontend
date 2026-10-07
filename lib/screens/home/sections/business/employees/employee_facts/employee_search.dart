import 'package:flutter/material.dart';

import './_employee_facts.dart';

/// What the detail's search box holds, for the sections and tiles below it.
///
/// A tile is found by its name ("phone") or by what it says ("Caracas"); a
/// section by its title, which then shows whole. Case and accents are
/// ignored: "direccion" finds "Dirección".
class EmployeeSearch extends InheritedWidget {
  EmployeeSearch({super.key, required String query, required super.child})
    : query = _plain(query);

  /// Already plain (lowercase, no accents, trimmed).
  final String query;

  bool get isEmpty => query.isEmpty;
  bool get isNotEmpty => query.isNotEmpty;

  bool matches(String text) => query.isEmpty || _plain(text).contains(query);

  /// Whether a tile of [EmployeeFacts] answers the query; anything that is
  /// not a tile never does.
  bool tile(Widget fact) =>
    query.isEmpty || fact is EmployeeTile && (matches((fact as EmployeeTile).label) || matches((fact as EmployeeTile).value));

  /// No search above it: everything shows.
  static EmployeeSearch of(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<EmployeeSearch>() ?? _none;

  /// Shared by every tile drawn outside a search, instead of one per lookup.
  static final EmployeeSearch _none = EmployeeSearch(query: "", child: const SizedBox.shrink());

  static const Map<String, String> _accents = {
    "á": "a", "à": "a", "ä": "a", "â": "a", "ã": "a",
    "é": "e", "è": "e", "ë": "e", "ê": "e",
    "í": "i", "ì": "i", "ï": "i", "î": "i",
    "ó": "o", "ò": "o", "ö": "o", "ô": "o", "õ": "o",
    "ú": "u", "ù": "u", "ü": "u", "û": "u",
    "ñ": "n", "ç": "c"
  };

  /// Runs once per tile and key: plain ASCII (most values) is returned as is.
  static String _plain(String text) {
    final lower = text.trim().toLowerCase();

    if (!lower.runes.any((rune) => rune > 0x7F)) return lower;

    final out = StringBuffer();

    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      out.write(_accents[char] ?? char);
    }

    return out.toString();
  }

  @override
  bool updateShouldNotify(EmployeeSearch old) => old.query != query;
}
