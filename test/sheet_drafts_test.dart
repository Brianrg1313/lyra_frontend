import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/home/sections/inventory/table_view/state/sheet_drafts.dart';

void main() {
  test('una fila en blanco no tiene borrador hasta que se escribe', () {
    // La planilla muestra decenas de filas vacias debajo de los registros: si
    // cada una tuviera su borrador, abrirla ya costaria.
    final drafts = SheetDrafts();

    expect(drafts.at(0), isNull);
    expect(drafts.length, 0);
  });

  test('escribir en una fila la vuelve un borrador', () {
    final drafts = SheetDrafts();

    drafts.write(0, 1, "Yerba");

    expect(drafts.at(0)?.hasData, isTrue);
    expect(drafts.textAt(0, 1), "Yerba");
  });

  test('vaciar la ultima celda saca la fila de las que se guardan', () {
    // Una fila que se vacia deja de tener algo que mandar: salir de ella no
    // manda nada.
    final drafts = SheetDrafts();
    drafts.write(0, 1, "Yerba");

    drafts.write(0, 1, "");

    expect(drafts.at(0)?.hasData, isFalse);
    expect(drafts.textAt(0, 1), "");
  });

  test('solo espacios es una celda vacia', () {
    final drafts = SheetDrafts();

    drafts.write(0, 1, "   ");

    expect(drafts.at(0)?.hasData ?? false, isFalse);
  });

  test('escribir en una fila de mas abajo no llena las de arriba', () {
    // Se puede empezar a cargar en la tercera fila en blanco: las dos de arriba
    // siguen vacias y no se guardan al pasar por ellas.
    final drafts = SheetDrafts();

    drafts.write(2, 0, "Azucar");

    expect(drafts.at(2)?.hasData, isTrue);
    expect(drafts.at(0)?.hasData, isFalse);
    expect(drafts.length, 3);
  });

  group('avisa solo cuando cambia algo que se ve', () {
    test('la primera letra avisa, las que siguen no', () {
      // Con la primera letra la planilla gana una fila y aparece otra en blanco
      // detras. Con la segunda no cambia nada en pantalla, y avisar ahi seria
      // repintar por cada tecla.
      final drafts = SheetDrafts();
      int notices = 0;
      drafts.addListener(() => notices += 1);

      drafts.write(0, 0, "Y");
      expect(notices, 1);

      drafts.write(0, 0, "Ye");
      drafts.write(0, 0, "Yer");
      expect(notices, 1);
    });

    test('vaciar la fila vuelve a avisar', () {
      final drafts = SheetDrafts();
      drafts.write(0, 0, "Yerba");

      int notices = 0;
      drafts.addListener(() => notices += 1);

      drafts.write(0, 0, "");

      expect(notices, 1);
    });

    test('una fila con otra celda cargada no se vacia por una sola', () {
      final drafts = SheetDrafts();
      drafts.write(0, 0, "Yerba");
      drafts.write(0, 1, "1500");

      int notices = 0;
      drafts.addListener(() => notices += 1);

      drafts.write(0, 1, "");

      expect(notices, 0, reason: "la fila sigue teniendo el nombre");
      expect(drafts.at(0)?.hasData, isTrue);
    });
  });

  test('guardar una fila la saca de la planilla', () {
    final drafts = SheetDrafts();
    drafts.write(0, 0, "Yerba");
    final draft = drafts.at(0)!;

    drafts.setSaving(draft, true);
    expect(draft.saving, isTrue);

    drafts.remove(draft);

    expect(drafts.length, 0);
    expect(drafts.at(0), isNull);
  });

  test('una fila en blanco entre medio no tiene nada que mandar', () {
    final drafts = SheetDrafts();
    drafts.write(0, 0, "Yerba");
    drafts.write(2, 0, "Azucar");

    // La fila 1 quedo en blanco entre medio: salir de ella no manda nada.
    expect(drafts.at(1)?.hasData, isFalse);
    expect(drafts.length, 3);
  });

  group('elegir en una celda sin editor', () {
    test('avisa aunque la fila ya tuviera algo escrito', () {
      // Una celda de lista no tiene editor delante: lo elegido no se ve hasta
      // que la celda se rehaga, y quien la rehace es este aviso. Escribiendo,
      // en cambio, el texto ya lo muestra el editor y no hace falta.
      final drafts = SheetDrafts();
      drafts.write(0, 0, "Yerba");

      int notices = 0;
      drafts.addListener(() => notices += 1);

      drafts.write(0, 1, "Rojo");
      expect(notices, 0, reason: "escribir lo muestra el editor");

      drafts.choose(0, 2, "Verde");
      expect(notices, 1);
      expect(drafts.textAt(0, 2), "Verde");
    });

    test('elegir lo mismo no avisa', () {
      final drafts = SheetDrafts();
      drafts.write(0, 0, "Yerba");
      drafts.choose(0, 1, "Rojo");

      int notices = 0;
      drafts.addListener(() => notices += 1);

      drafts.choose(0, 1, "Rojo");

      expect(notices, 0);
    });

    test('vaciar una celda de lista la deja sin valor', () {
      // Es la opcion de "sin valor" del desplegable: la unica vuelta atras que
      // tiene una celda que no se escribe.
      final drafts = SheetDrafts();
      drafts.write(0, 0, "Yerba");
      drafts.choose(0, 1, "Rojo");

      int notices = 0;
      drafts.addListener(() => notices += 1);

      drafts.choose(0, 1, "");

      expect(notices, 1);
      expect(drafts.textAt(0, 1), isEmpty);
      // La fila sigue teniendo algo que mandar: lo que se vacio fue una celda,
      // no la fila.
      expect(drafts.at(0)?.hasData, isTrue);
    });

    test('elegir es lo que crea el borrador de una fila en blanco', () {
      final drafts = SheetDrafts();

      int notices = 0;
      drafts.addListener(() => notices += 1);

      drafts.choose(1, 0, "Rojo");

      // Un solo aviso: el de la fila que paso de vacia a escrita.
      expect(notices, 1);
      expect(drafts.at(1)?.hasData, isTrue);
      expect(drafts.textAt(1, 0), "Rojo");
    });
  });
}
