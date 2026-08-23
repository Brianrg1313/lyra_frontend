import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/stock/tables/table_ready_model.dart';

/// El evento `table/ready` tal cual lo emite `Normalizer.prepare`: el aviso de
/// que una tabla importada termino de prepararse, medio minuto despues de que
/// la importacion haya contestado.
Map<String, dynamic> get _event => {
  "id": "8f2c1a90-3d7b-4e21-9c55-6ab0f1d2e4c7",
  "ok": true,
  "normalized": true,
  "retyped": 7,
  "narrowed": 3,
  "image": "a1b2c3d4-1111-4aaa-8bbb-000000000001",
  "ai": {"used": true, "provider": "anthropic", "cost": 0.0142}
};

void main() {
  group('aviso de tabla lista', () {
    test('lee lo que hizo el backend', () {
      final report = TableReadyModel.fromEvent(_event);

      expect(report.id, "8f2c1a90-3d7b-4e21-9c55-6ab0f1d2e4c7");
      expect(report.ok, isTrue);
      expect(report.normalized, isTrue);
      expect(report.retyped, 7);
      expect(report.narrowed, 3);
      expect(report.image, "a1b2c3d4-1111-4aaa-8bbb-000000000001");
      expect(report.isEmpty, isFalse);
    });

    test('sin normalizar tambien es un aviso bueno', () {
      // `NORMALIZE=0`: la tabla se importo tal como estaba escrita, y el evento
      // llega igual. No es un fallo y no trae contadores.
      final report = TableReadyModel.fromEvent({
        "id": "tabla",
        "ok": true,
        "normalized": false,
        "image": "campo-imagen"
      });

      expect(report.ok, isTrue);
      expect(report.normalized, isFalse);
      expect(report.retyped, 0);
      expect(report.changedValues, isFalse);
    });

    test('un fallo trae el motivo y sigue nombrando la tabla', () {
      final report = TableReadyModel.fromEvent({
        "id": "tabla",
        "ok": false,
        "normalized": false,
        "reason": "table"
      });

      expect(report.isEmpty, isFalse);
      expect(report.ok, isFalse);
      expect(report.reason, "table");
    });

    test('lo que no se puede leer se descarta', () {
      // La unica forma de tirar un aviso es que no diga de que tabla es: no hay
      // a quien devolverle un error, asi que nada de esto lanza.
      expect(TableReadyModel.fromEvent(null).isEmpty, isTrue);
      expect(TableReadyModel.fromEvent("table/ready").isEmpty, isTrue);
      expect(TableReadyModel.fromEvent(const []).isEmpty, isTrue);
      expect(TableReadyModel.fromEvent({"ok": true}).isEmpty, isTrue);
    });

    test('los numeros y los booleanos aguantan venir como texto', () {
      final report = TableReadyModel.fromEvent({
        "id": "tabla",
        "ok": "true",
        "normalized": 1,
        "retyped": "2",
        "narrowed": null,
        "image": null
      });

      expect(report.ok, isTrue);
      expect(report.normalized, isTrue);
      expect(report.retyped, 2);
      expect(report.narrowed, 0);
      expect(report.image, "");
    });
  });

  group('que hay que releer', () {
    test('retipar una columna invalida los registros leidos', () {
      // Al retipar, el backend reescribe los valores guardados
      // (`Products.recast`): los campos pueden ser los mismos y sus valores no.
      final report = TableReadyModel.fromEvent(_event);

      expect(report.changedValues, isTrue);
    });

    test('ganar la columna de imagen no los invalida', () {
      // Nada se reescribio: la tabla tiene una columna mas y las filas leidas
      // siguen sirviendo, solo hay que reacomodarlas.
      final report = TableReadyModel.fromEvent({
        "id": "tabla",
        "ok": true,
        "normalized": true,
        "retyped": 0,
        "narrowed": 4,
        "image": "campo-imagen"
      });

      expect(report.changedValues, isFalse);
    });
  });
}
