/// Language a business operates in.
///
/// The backend saves it as a locale tag and all it does to it is trim it and
/// lowercase it (`Business.language`), so this isn't a validation: it's the
/// catalog of the languages that can be **picked** from the app, which is what
/// is needed to offer a list instead of a text field where anything passes as
/// a language.
///
/// The names aren't translated. A language names itself: whoever speaks it
/// recognizes it written that way even while reading the app in another
/// language, and "Aleman" doesn't say more to whoever is going to pick it than
/// "Deutsch" does.
enum BusinessLanguage {
  es(tag: "es", name: "Español"),
  en(tag: "en", name: "English"),
  pt(tag: "pt", name: "Português"),
  fr(tag: "fr", name: "Français"),
  it(tag: "it", name: "Italiano"),
  de(tag: "de", name: "Deutsch");

  const BusinessLanguage({required this.tag, required this.name});

  /// Code that travels to the backend. Not translated.
  final String tag;

  /// What the language calls itself in that language.
  final String name;

  /// The language of a saved tag, or `null` if it's none of the catalog's.
  ///
  /// Only the language part is looked at: `es-VE` is Spanish written in
  /// Venezuela, and "Español" is enough to name it. What isn't recognized
  /// returns `null` instead of falling back to a default one, because the saved
  /// tag is a piece of the business's data and showing another language would
  /// be lying about it.
  static BusinessLanguage? from(String tag) {
    final code = tag.trim().toLowerCase().split(RegExp("[-_]")).first;
    if (code.isEmpty) return null;

    for (final language in values) {
      if (language.tag == code) return language;
    }

    return null;
  }

  /// How a saved tag is read: the language name, or the raw tag if this version
  /// doesn't know it yet.
  static String label(String tag) => from(tag)?.name ?? tag;
}
