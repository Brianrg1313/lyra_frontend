/// Idioma en el que opera una empresa.
///
/// El backend lo guarda como un tag de locale y lo unico que le hace es
/// recortarlo y pasarlo a minusculas (`Business.language`), asi que esto no es
/// una validacion: es el catalogo de los que se pueden **elegir** desde la app,
/// que es lo que hace falta para ofrecer una lista en vez de un campo de texto
/// donde cualquier cosa pasa por idioma.
///
/// Los nombres no se traducen. Un idioma se nombra en si mismo: quien lo habla
/// lo reconoce escrito asi aunque este leyendo la app en otro, y "Aleman" no le
/// dice mas que "Deutsch" a quien lo va a elegir.
enum BusinessLanguage {
  es(tag: "es", name: "Español"),
  en(tag: "en", name: "English"),
  pt(tag: "pt", name: "Português"),
  fr(tag: "fr", name: "Français"),
  it(tag: "it", name: "Italiano"),
  de(tag: "de", name: "Deutsch");

  const BusinessLanguage({required this.tag, required this.name});

  /// Codigo que viaja al backend. No se traduce.
  final String tag;

  /// Como se llama el idioma en el idioma mismo.
  final String name;

  /// El idioma de un tag guardado, o `null` si no es ninguno del catalogo.
  ///
  /// Se mira solo la parte del idioma: `es-VE` es español escrito en Venezuela,
  /// y para nombrarlo alcanza con "Español". Lo que no se reconoce devuelve
  /// `null` en vez de caer en uno por defecto, porque el tag guardado es un
  /// dato de la empresa y mostrar otro idioma seria mentir sobre el.
  static BusinessLanguage? from(String tag) {
    final code = tag.trim().toLowerCase().split(RegExp("[-_]")).first;
    if (code.isEmpty) return null;

    for (final language in values) {
      if (language.tag == code) return language;
    }

    return null;
  }

  /// Como se lee un tag guardado: el nombre del idioma, o el tag crudo si esta
  /// version todavia no lo conoce.
  static String label(String tag) => from(tag)?.name ?? tag;
}
