import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/inventory/table_field_options.dart';

void main() {
  test('una opcion nueva se agrega al final', () {
    // El orden de la lista es el orden en que se ofrece: la ultima que se penso
    // va ultima, no se cuela en el medio de las que ya estaban.
    expect(
      fieldOptionsWith(const ["Rojo", "Verde"], "Azul"),
      ["Rojo", "Verde", "Azul"]
    );
  });

  test('la primera opcion de un campo sin lista', () {
    expect(fieldOptionsWith(const [], "Rojo"), ["Rojo"]);
  });

  test('la opcion se guarda recortada', () {
    expect(fieldOptionsWith(const [], "  Rojo  "), ["Rojo"]);
  });

  test('una opcion vacia no agrega nada', () {
    // No hay nada que guardar: ni peticion ni opcion en blanco en la lista.
    expect(fieldOptionsWith(const ["Rojo"], "   "), isNull);
  });

  test('una opcion repetida no se duplica', () {
    expect(fieldOptionsWith(const ["Rojo", "Verde"], "Verde"), isNull);
  });

  test('mayusculas y tildes no hacen otra opcion', () {
    // El buscador del desplegable ignora las dos cosas, asi que dos opciones
    // que solo se distinguen en eso serian indistinguibles al elegirlas.
    expect(fieldOptionsWith(const ["Rojo"], "ROJO"), isNull);
    expect(fieldOptionsWith(const ["Marron"], "marrón"), isNull);
  });

  test('agregar no toca la lista que se le paso', () {
    final options = ["Rojo"];
    fieldOptionsWith(options, "Verde");

    expect(options, ["Rojo"]);
  });

  test('la opcion repetida se resuelve a la que ya estaba', () {
    // Escribir "rojo" en una lista que tiene "Rojo" elige la que hay: es lo que
    // quiso decir quien la escribio, y ademas es la que esta guardada en las
    // celdas que ya la usan.
    expect(fieldOptionLike(const ["Rojo", "Verde"], "  rojo "), "Rojo");
  });

  test('una opcion que no esta no coincide con ninguna', () {
    expect(fieldOptionLike(const ["Rojo", "Verde"], "Azul"), isNull);
    expect(fieldOptionLike(const ["Rojo"], "  "), isNull);
  });

  test('dos opciones son la misma sin mirar mayusculas ni tildes', () {
    expect(sameFieldOption("Rojo", "rojo"), isTrue);
    expect(sameFieldOption("Marrón", "marron"), isTrue);
    expect(sameFieldOption("Rojo", "Rojizo"), isFalse);
  });

  group('las etiquetas de una celda de varias', () {
    test('se leen de la lista que guarda el backend', () {
      expect(
        fieldLabelsOf(const ["Zapatos", "  Deportivos  ", "", null]),
        ["Zapatos", "Deportivos"]
      );
    });

    test('se leen tambien del texto de un borrador', () {
      // Una celda que se acaba de elegir todavia es texto, y el backend parte
      // por los mismos tres separadores.
      expect(fieldLabelsOf("Zapatos, Deportivos"), ["Zapatos", "Deportivos"]);
      expect(fieldLabelsOf("a;b|c"), ["a", "b", "c"]);
    });

    test('una celda vacia o ilegible no tiene ninguna', () {
      expect(fieldLabelsOf(null), isEmpty);
      expect(fieldLabelsOf(""), isEmpty);
      expect(fieldLabelsOf("  ,  "), isEmpty);
    });

    test('se escriben en una linea y no con los corchetes de Dart', () {
      // Es lo que se ve en la celda y en el resumen: `[a, b]` no es el dato de
      // nadie.
      expect(
        fieldLabelsText(const ["Zapatos", "Deportivos"]),
        "Zapatos, Deportivos"
      );
      expect(fieldLabelsText(null), "");
    });

    test('viajan como la misma linea que se lee', () {
      expect(
        fieldLabelsValue(const ["Zapatos", " Deportivos "]),
        "Zapatos, Deportivos"
      );
      // Vacia es lo que borra la celda.
      expect(fieldLabelsValue(const []), "");
    });

    test('elegir una etiqueta la pone o la saca', () {
      // El desplegable es de una sola eleccion, asi que tocar una que ya estaba
      // solo puede querer decir "sacala": reemplazar a todas las demas seria
      // perder lo que alguien cargo de a una.
      expect(
        fieldLabelsToggled(const ["Zapatos"], "Deportivos"),
        ["Zapatos", "Deportivos"]
      );
      expect(
        fieldLabelsToggled(const ["Zapatos", "Deportivos"], "Zapatos"),
        ["Deportivos"]
      );
    });

    test('dos etiquetas que solo se distinguen en tildes son la misma', () {
      // La misma regla que en la lista del campo: serian indistinguibles al
      // elegirlas.
      expect(fieldLabelsToggled(const ["Marrón"], "marron"), isEmpty);
    });
  });
}
