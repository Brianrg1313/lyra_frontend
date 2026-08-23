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
}
