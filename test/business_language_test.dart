import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/business/business_language.dart';

void main() {
  group('idioma de la empresa', () {
    test('lee el tag guardado', () {
      expect(BusinessLanguage.from("es"), BusinessLanguage.es);
      expect(BusinessLanguage.from("EN"), BusinessLanguage.en);
      expect(BusinessLanguage.from("  pt  "), BusinessLanguage.pt);
    });

    test('un tag con region es el mismo idioma', () {
      // `es-VE` es español escrito en Venezuela: para nombrarlo alcanza con
      // "Español", que es lo unico que se muestra.
      expect(BusinessLanguage.from("es-VE"), BusinessLanguage.es);
      expect(BusinessLanguage.from("pt_BR"), BusinessLanguage.pt);
    });

    test('lo que no esta en el catalogo no se traduce a otro idioma', () {
      expect(BusinessLanguage.from("zz"), isNull);
      expect(BusinessLanguage.from(""), isNull);
    });

    test('un tag desconocido se muestra tal como se guardo', () {
      // Inventarle un nombre —o caer en el primero de la lista— seria decir que
      // la empresa opera en un idioma que no eligio.
      expect(BusinessLanguage.label("zz-ZZ"), "zz-ZZ");
      expect(BusinessLanguage.label("es"), "Español");
    });

    test('el codigo que viaja al backend es el que se lee', () {
      for (final language in BusinessLanguage.values) {
        expect(BusinessLanguage.from(language.tag), language);
      }
    });
  });
}
