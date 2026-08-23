import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/stock/tables/table_detail_model.dart';

/// La respuesta de `GET /tables/details/<UUID>` tal cual la define el
/// contrato: la cabecera con sus dos fechas, las cuentas de columnas, lo que
/// puede hacer la IA con la tabla, los bots que la leen y las columnas en
/// forma columnar.
Map<String, dynamic> get _response => {
  "id": "8f2c1a90-3d7b-4e21-9c55-6ab0f1d2e4c7",
  "name": "Productos",
  "description": "Catálogo de la tienda",
  "color": "0xFF2196F3",
  "date": "2026-03-02T09:00:00.000Z",
  "updated": "2026-07-14T10:32:11.000Z",
  "records": {"total": 1287, "last": "2026-08-20T14:05:00.000Z"},
  "columns": {
    "total": 4,
    "types": {"vector": 2, "price": 1, "stock": 1},
    "visibility": {"visible": 2, "declared": 1, "hidden": 1},
    "untyped": 0
  },
  "agent": {
    "searchable": true,
    "filterable": 3,
    "stock": true,
    "image": false
  },
  "channels": {
    "reached": true,
    "linked": [
      {
        "id": "c1",
        "name": "Ventas",
        "description": null,
        "provider": "whatsapp",
        "connection_name": "Cuenta principal",
        "scope": "messages",
        "scope_name": "Mensajes directos",
        "role": "seller",
        "enabled": true,
        "ready": true
      }
    ],
    "open": [
      {
        "id": "c2",
        "name": "Soporte",
        "provider": "instagram",
        "connection_name": "Instagram",
        "scope_name": "Comentarios",
        "role": "support",
        "enabled": false,
        "ready": false
      }
    ]
  },
  "fields": {
    "keys": [
      "id", "name", "description", "position",
      "type", "width", "options", "visibility", "date", "updated"
    ],
    "values": [
      [
        "f1", "Nombre", "Como se llama", 0,
        "vector", 240, [], "visible",
        "2026-03-02T09:00:00.000Z", "2026-03-02T09:00:00.000Z"
      ],
      [
        "f2", "Descripción", null, 1,
        "vector", null, null, "visible",
        "2026-03-02T09:00:00.000Z", null
      ],
      [
        "f3", "Costo", null, 2,
        "price", null, null, "declared",
        "2026-03-02T09:00:00.000Z", "2026-07-14T10:32:11.000Z"
      ],
      [
        "f4", "Proveedor", null, 3,
        "select", null, ["Acme", "Globex"], "hidden",
        "2026-03-02T09:00:00.000Z", null
      ]
    ]
  }
};

void main() {
  group('detalle de una tabla', () {
    test('lee la cabecera y sus dos fechas', () {
      final detail = TableDetailModel.fromResponse(_response);

      expect(detail.id, "8f2c1a90-3d7b-4e21-9c55-6ab0f1d2e4c7");
      expect(detail.name, "Productos");
      expect(detail.description, "Catálogo de la tienda");
      expect(detail.color, "0xFF2196F3");
      expect(detail.date, DateTime.utc(2026, 3, 2, 9));
      expect(detail.updated, DateTime.utc(2026, 7, 14, 10, 32, 11));
      expect(detail.isEmpty, isFalse);
    });

    test('la fecha del ultimo registro no es la de la estructura', () {
      // Son dos preguntas distintas: cuando cambio la tabla y cuando entro el
      // ultimo dato. Una lista de precios recargada hoy tiene la primera vieja
      // y la segunda de hoy.
      final detail = TableDetailModel.fromResponse(_response);

      expect(detail.records, 1287);
      expect(detail.lastRecord, DateTime.utc(2026, 8, 20, 14, 5));
      expect(detail.lastRecord, isNot(detail.updated));
    });

    test('unos registros que no se pudieron contar no son cero', () {
      // El backend manda `records: null` cuando la cuenta fallo: las filas
      // viven en otra base que las columnas. Una tabla que no se pudo contar
      // no es una tabla vacia.
      final detail = TableDetailModel.fromResponse({
        ..._response,
        "records": null
      });

      expect(detail.records, isNull);
      expect(detail.lastRecord, isNull);
    });

    test('una tabla vacia si cuenta cero', () {
      final detail = TableDetailModel.fromResponse({
        ..._response,
        "records": {"total": 0, "last": null}
      });

      expect(detail.records, 0);
      expect(detail.lastRecord, isNull);
    });

    test('lee las cuentas de columnas por tipo y por visibilidad', () {
      final columns = TableDetailModel.fromResponse(_response).columns;

      expect(columns.total, 4);
      expect(columns.untyped, 0);
      expect(columns.types[TableFieldType.vector], 2);
      expect(columns.types[TableFieldType.price], 1);
      expect(columns.types[TableFieldType.stock], 1);
      expect(columns.of(TableFieldVisibility.visible), 2);
      expect(columns.of(TableFieldVisibility.declared), 1);
      expect(columns.of(TableFieldVisibility.hidden), 1);
    });

    test('los tipos se ordenan del mas usado al menos', () {
      final columns = TableDetailModel.fromResponse(_response).columns;

      expect(columns.sorted.first.key, TableFieldType.vector);
      expect(columns.sorted.first.value, 2);
    });

    test('dos tipos desconocidos caen juntos en texto sin pisarse', () {
      // Un tipo que esta version no conoce se lee como texto. Si el backend
      // manda dos, el segundo no puede reemplazar la cuenta del primero.
      final columns = TableDetailModel.fromResponse({
        ..._response,
        "columns": {
          "total": 5,
          "types": {"text": 1, "geo": 2, "json": 3},
          "visibility": {"visible": 5},
          "untyped": 1
        }
      }).columns;

      expect(columns.types[TableFieldType.text], 6);
    });

    test('lee lo que la IA puede hacer con la tabla', () {
      final agent = TableDetailModel.fromResponse(_response).agent;

      expect(agent.searchable, isTrue);
      expect(agent.filterable, 3);
      expect(agent.stock, isTrue);
      expect(agent.image, isFalse);
    });

    test('lee las columnas en el orden en que vienen', () {
      final fields = TableDetailModel.fromResponse(_response).fields;

      expect(
        [for (final field in fields) field.name],
        ["Nombre", "Descripción", "Costo", "Proveedor"]
      );
      expect(
        [for (final field in fields) field.position],
        [0, 1, 2, 3]
      );
      expect(fields[2].type, TableFieldType.price);
      expect(fields[2].visibility, TableFieldVisibility.declared);
      expect(fields[3].options, ["Acme", "Globex"]);
      expect(fields[0].description, "Como se llama");
      // Una columna que nunca se toco no trae `updated`, y eso no es un error.
      expect(fields[1].updated, isNull);
    });

    test('una visibilidad desconocida se lee como visible', () {
      expect(TableFieldVisibility.from("restricted"),
        TableFieldVisibility.visible);
      expect(TableFieldVisibility.from(null), TableFieldVisibility.visible);
      expect(TableFieldVisibility.from("HIDDEN"), TableFieldVisibility.hidden);
    });

    test('separa los bots que eligieron la tabla de los que leen todas', () {
      // Es la razon de ser de las dos listas: un bot sin fuentes configuradas
      // lee esta tabla sin que nadie lo haya elegido, y no decirlo seria
      // mostrar "no esta conectada a nada" mientras contesta con ella.
      final channels = TableDetailModel.fromResponse(_response).channels;

      expect(channels.reached, isTrue);
      expect([for (final bot in channels.linked) bot.id], ["c1"]);
      expect([for (final bot in channels.open) bot.id], ["c2"]);
      expect(channels.linked.first.connectionName, "Cuenta principal");
      expect(channels.linked.first.scopeName, "Mensajes directos");
      expect(channels.linked.first.enabled, isTrue);
      expect(channels.open.first.enabled, isFalse);
      expect(channels.open.first.ready, isFalse);
    });

    test('sin ningun bot la tabla no esta alcanzada', () {
      final channels = TableDetailModel.fromResponse({
        ..._response,
        "channels": {"reached": false, "linked": [], "open": []}
      }).channels;

      expect(channels.reached, isFalse);
    });

    test('el color se lee como el literal ARGB que es', () {
      expect(
        TableDetailModel.fromResponse(_response).tint,
        const Color(0xFF2196F3)
      );

      // Sin color, o con uno ilegible, la pantalla se ve igual: es un adorno.
      expect(
        TableDetailModel.fromResponse({..._response, "color": ""}).tint,
        isNull
      );
      expect(
        TableDetailModel.fromResponse({..._response, "color": "azul"}).tint,
        isNull
      );
    });

    test('un renombre no toca nada mas del detalle', () {
      // Es lo que deja que la ficha muestre el texto nuevo sin esperar a releer
      // las tres bases: lo unico que cambio es lo que se acaba de escribir.
      final detail = TableDetailModel.fromResponse(_response);
      final renamed = detail.withText(name: "Catalogo");

      expect(renamed.name, "Catalogo");
      expect(renamed.description, detail.description);
      expect(renamed.records, detail.records);
      expect(renamed.updated, detail.updated);
      expect(renamed.columns.total, detail.columns.total);
      expect(renamed.channels.linked.length, detail.channels.linked.length);
      expect(renamed.fields.length, detail.fields.length);
      expect(renamed.id, detail.id);
    });

    test('lo que no se cambia no se pisa, y vaciar si borra', () {
      // `null` es "no se toco" y el vacio es un valor, igual que en el cuerpo
      // que viaja al backend.
      final detail = TableDetailModel.fromResponse(_response);

      expect(detail.withText(description: "Otra cosa").name, detail.name);
      expect(detail.withText(name: "Catalogo").description,
        detail.description);
      expect(detail.withText(description: "").description, isEmpty);
    });

    test('una columna cambia sola: lo demas de la ficha queda igual', () {
      // Cambiar el tipo de una columna desde la ficha no puede tocar las otras
      // ni la cabecera de la tabla.
      final detail = TableDetailModel.fromResponse(_response);
      final field = detail.fields.first;

      final changed = detail.withField(field.withEdits(
        type: TableFieldType.price,
        visibility: TableFieldVisibility.declared
      ));

      expect(changed.fields.first.type, TableFieldType.price);
      expect(changed.fields.first.visibility, TableFieldVisibility.declared);

      // Lo que no se toco: el nombre, la descripcion y el lugar de la columna.
      expect(changed.fields.first.name, field.name);
      expect(changed.fields.first.description, field.description);
      expect(changed.fields.first.position, field.position);

      // Y el resto de la ficha.
      expect(changed.fields.length, detail.fields.length);
      expect(changed.fields.last.type, detail.fields.last.type);
      expect(changed.name, detail.name);
      expect(changed.updated, detail.updated);
    });

    test('las cuentas de arriba no se recalculan: las hace el backend', () {
      // Se corrigen con la relectura que dispara la propia escritura, no
      // contando las columnas de este lado.
      final detail = TableDetailModel.fromResponse(_response);

      final changed = detail.withField(
        detail.fields.first.withEdits(type: TableFieldType.price)
      );

      expect(changed.columns.types, detail.columns.types);
      expect(changed.columns.untyped, detail.columns.untyped);
      expect(changed.agent.searchable, detail.agent.searchable);
    });

    test('una columna que ya no esta no se agrega de vuelta', () {
      // El detalle se releyo y la columna se borro desde la planilla: lo que
      // vuelve de una escritura vieja no la resucita.
      final detail = TableDetailModel.fromResponse(_response);

      final changed = detail.withField(const TableDetailFieldModel(
        id: "no-existe",
        name: "Fantasma"
      ));

      expect(changed.fields.length, detail.fields.length);
      expect(changed.fields.any((field) => field.id == "no-existe"), isFalse);
    });

    test('las opciones se vacian con una lista vacia, no con null', () {
      final field = const TableDetailFieldModel(
        id: "f1",
        name: "Color",
        type: TableFieldType.select,
        options: ["Rojo"]
      );

      expect(field.withEdits().options, ["Rojo"]);
      expect(field.withEdits(options: const []).options, isEmpty);
    });

    test('una respuesta que no es un detalle queda vacia', () {
      expect(TableDetailModel.fromResponse(null).isEmpty, isTrue);
      expect(TableDetailModel.fromResponse("nada").isEmpty, isTrue);
      expect(TableDetailModel.fromResponse(const {}).isEmpty, isTrue);
    });
  });
}
