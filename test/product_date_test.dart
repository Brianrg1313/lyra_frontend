import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'package:app/services/inventory/product_date.dart';

/// Lo que queda escrito al salir de la celda.
String _stored(String raw) => ProductDate.normalize(raw);

/// Simula tipear [key] al final de [text], como lo ve el editor.
TextEditingValue _type(String text, String key) {
  const formatter = DateSeparatorFormatter();

  return formatter.formatEditUpdate(
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length)
    ),
    TextEditingValue(
      text: text + key,
      selection: TextSelection.collapsed(offset: text.length + 1)
    )
  );
}

void main() {
  // Los nombres de los meses los trae `intl`. En la app los deja cargados
  // `GlobalMaterialLocalizations`; aca no hay app, asi que se cargan a mano.
  setUpAll(() => initializeDateFormatting("en"));

  group('la fecha se escribe como a uno le salga', () {
    test('con el ano adelante, con guion o con barra', () {
      // Cuatro cifras adelante solo pueden ser un ano.
      expect(_stored("2026-02-12"), "2026-02-12");
      expect(_stored("2026/02/12"), "2026-02-12");
      expect(_stored("2026.02.12"), "2026-02-12");
    });

    test('con el dia adelante, que es como se escribe una fecha', () {
      expect(_stored("12-02-2026"), "2026-02-12");
      expect(_stored("12/02/2026"), "2026-02-12");
    });

    test('con el ano de dos cifras', () {
      // La ventana de cualquier planilla: hasta 69 es este siglo.
      expect(_stored("12/02/26"), "2026-02-12");
      expect(_stored("12/02/98"), "1998-02-12");
    });

    test('sin ceros adelante', () {
      // Es lo que sale de tipear rapido, y es una fecha igual.
      expect(_stored("12/2/26"), "2026-02-12");
      expect(_stored("1/2/2026"), "2026-02-01");
    });

    test('al reves, con el mes adelante', () {
      // `02/26/2026`: el mes no llega a veintiseis y el dia si, asi que estaban
      // dados vuelta. Se acomoda en vez de perder la fecha.
      expect(_stored("02/26/2026"), "2026-02-26");
    });
  });

  group('la hora viaja con la fecha o no viaja', () {
    test('una fecha sin hora se guarda sin hora', () {
      // No es lo mismo no tener hora que tenerla en cero: un vencimiento no
      // vence a las doce de la noche.
      final date = ProductDate.parse("2026-02-12")!;

      expect(date.hasTime, isFalse);
      expect(date.stored, "2026-02-12");
    });

    test('con hora se guarda con hora', () {
      final date = ProductDate.parse("2026-02-12 12:30")!;

      expect(date.hasTime, isTrue);
      expect(date.stored, "2026-02-12 12:30");
    });

    test('un reloj de doce se pasa a uno de veinticuatro', () {
      expect(_stored("12/02/2026 1:05 pm"), "2026-02-12 13:05");
      expect(_stored("12/02/2026 12:30 am"), "2026-02-12 00:30");
      expect(_stored("12/02/2026 12:30 pm"), "2026-02-12 12:30");
    });

    test('lo que manda el backend en ISO se entiende igual', () {
      final date = ProductDate.parse("2026-02-12T00:00:00.000Z")!;

      // Y no se corre de dia: una fecha de catalogo es un dia del calendario,
      // no un instante. Pasarla a hora local la mandaria al 11 en media
      // America.
      expect(date.at.year, 2026);
      expect(date.at.month, 2);
      expect(date.at.day, 12);
    });
  });

  group('lo que no es una fecha se queda como esta', () {
    test('un texto cualquiera', () {
      expect(ProductDate.parse("consultar"), isNull);
      expect(_stored("consultar"), "consultar");
    });

    test('una celda vacia', () {
      expect(ProductDate.parse(""), isNull);
      expect(ProductDate.parse("   "), isNull);
    });

    test('un dia que no existe', () {
      // [DateTime] corre el 31 de febrero al 3 de marzo en vez de fallar: eso
      // seria inventarle una fecha a alguien que se equivoco tipeando.
      expect(ProductDate.parse("31/02/2026"), isNull);
      expect(ProductDate.parse("2026-13-01"), isNull);
      expect(ProductDate.parse("00/02/2026"), isNull);
    });

    test('una hora que no existe', () {
      expect(ProductDate.parse("12/02/2026 25:00"), isNull);
      expect(ProductDate.parse("12/02/2026 10:75"), isNull);
    });
  });

  group('como se lee una fecha', () {
    test('escrita, con el mes en letras', () {
      final date = ProductDate.parse("2026-02-12")!;

      expect(date.short("en"), "Feb 12, 2026");
    });

    test('completa, en cifras y con su hora', () {
      final date = ProductDate.parse("2026-02-12 12:30")!;

      // El hueco antes del `PM` lo pone `intl` y no siempre es un espacio de
      // los de siempre: los datos de CLDR usan uno fino que no se parte de
      // renglon.
      expect(date.full("en"), matches(RegExp(r"^2026-02-12 12:30\sPM$")));
    });

    test('completa, sin inventarle una hora a la que no tiene', () {
      final date = ProductDate.parse("2026-02-12")!;

      expect(date.full("en"), "2026-02-12");
    });
  });

  group('el espacio escribe la barra de la fecha', () {
    test('entre los numeros', () {
      expect(_type("12", " ").text, "12/");
      expect(_type("12/2", " ").text, "12/2/");
    });

    test('con la barra que la fecha ya venia usando', () {
      // Para no dejar `2026-02/12`.
      expect(_type("2026-02", " ").text, "2026-02-");
    });

    test('el espacio de la hora sigue siendo un espacio', () {
      // Con dos separadores la fecha ya esta entera: lo que sigue es la hora.
      // Sin esto no habria forma de tipear `2026-02-12 12:30`.
      expect(_type("2026-02-12", " ").text, "2026-02-12 ");
    });

    test('un espacio que no separa nada no entra', () {
      expect(_type("", " ").text, "");
      expect(_type("12/", " ").text, "12/");
    });

    test('el cursor queda detras de la barra', () {
      final value = _type("12", " ");

      expect(value.selection.baseOffset, value.text.length);
    });

    test('pegar un texto no lo toca', () {
      // Solo se convierte la tecla recien apretada: lo que se pega se guarda
      // como vino, y [ProductDate] ya lo entiende.
      const formatter = DateSeparatorFormatter();

      const pasted = TextEditingValue(
        text: "12 02 2026",
        selection: TextSelection.collapsed(offset: 10)
      );

      expect(
        formatter.formatEditUpdate(TextEditingValue.empty, pasted).text,
        "12 02 2026"
      );
    });
  });
}
