import 'package:flutter/material.dart';

import './own_section.dart';

/// One row of a subsection, as the search finds it.
class OwnSetting {
  const OwnSetting(this.section, this.icon, this.label, [this.hint]);

  final OwnSection section;
  final IconData icon;
  final String label;
  final String? hint;

  /// Whether each of [words] (already [fold]ed) is in its label, its hint or its subsection's
  /// title, in any order: "step two" finds "Two-step verification".
  bool matches(List<String> words, String sectionTitle) {
    final text = fold("$label ${hint ?? ""} $sectionTitle");
    return words.every(text.contains);
  }

  /// Lower case without accents or hyphens, so a typed "codigo" or "two step" finds its row
  /// whichever language the copy is in.
  static String fold(String text) {
    const from = "áàäâéèëêíìïîóòöôúùüûñç-";
    const to = "aaaaeeeeiiiioooouuuunc ";

    final lower = text.toLowerCase();
    final buffer = StringBuffer();
    for (final char in lower.split("")) {
      final at = from.indexOf(char);
      buffer.write(at < 0 ? char : to[at]);
    }
    return buffer.toString();
  }
}
