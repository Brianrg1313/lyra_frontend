import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/home/sections/inventory/table_view/state/field_edit.dart';

/// Lo que se hace al salir de la celda de un campo. Es la regla con la que la
/// planilla agrega, renombra y elimina columnas sin un solo boton: lo unico que
/// mira es que titulo habia y cual quedo.
void main() {
  test('escribir en una columna libre la crea', () {
    expect(
      FieldEdit.of(isField: false, current: "", text: "Precio"),
      FieldEdit.create
    );
  });

  test('una columna libre que queda en blanco no crea nada', () {
    expect(
      FieldEdit.of(isField: false, current: "", text: "   "),
      FieldEdit.none
    );
  });

  test('otro titulo renombra el campo', () {
    expect(
      FieldEdit.of(isField: true, current: "Precio", text: "Costo"),
      FieldEdit.rename
    );
  });

  test('el mismo titulo no manda nada', () {
    // Entrar y salir de la celda es lo mas comun al recorrer la planilla con el
    // teclado: no puede disparar una escritura.
    expect(
      FieldEdit.of(isField: true, current: "Precio", text: "  Precio  "),
      FieldEdit.none
    );
  });

  test('vaciar el titulo elimina el campo', () {
    expect(
      FieldEdit.of(isField: true, current: "Precio", text: ""),
      FieldEdit.delete
    );

    // Espacios sueltos tambien es vacio: lo que se ve es una celda en blanco.
    expect(
      FieldEdit.of(isField: true, current: "Precio", text: "   "),
      FieldEdit.delete
    );
  });
}
