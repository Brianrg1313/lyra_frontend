import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/kitchen/presentation_model.dart';
import 'package:app/services/stock/movements/stock_movement_model.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/services/stock/tables/table_stock_mover.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_model.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

/// A row written in the sheet becomes a record where it was written, with the id the backend
/// answered, and the rows already read stay: the sheet neither empties nor re-reads its
/// structure for it (it blinked, and every row lost its id until the re-read came back, so
/// a tap only selected). A stock cell's movement leaves the balance in its row.
void main() {
  group('a created row', () {
    test('is placed behind the last record, writable, with the rows read kept', () async {
      final source = _Inventory();
      final service = TableViewService(source: source);
      await service.open("t1");

      expect(service.records, 2);
      expect(source.structures, 1);

      var emptied = false;
      service.addListener(() {
        if (service.rowAt(0) == null) emptied = true;
      });

      final saved = await service.add(_NoContext(), {"f-name": "Sugar"}, row: ["Sugar", null]);

      expect(saved, isTrue);
      expect(service.records, 3);
      expect(service.rowAt(2)?.id, "r3");
      expect(service.rowAt(2)?.at(0), "Sugar");
      expect(emptied, isFalse, reason: "the rows read stay drawn");
      expect(source.structures, 1, reason: "no structure re-read");

      // Its page is read again in place: what the backend filled arrives over the row.
      await Future<void>.delayed(Duration.zero);
      expect(source.pages, 2);
      expect(service.records, 3);
      expect(service.rowAt(2)?.at(1), 0);
      service.dispose();
    });

    test('without an id answered, the table is read again whole', () async {
      final source = _Inventory()..answerId = "";
      final service = TableViewService(source: source);
      await service.open("t1");

      await service.add(_NoContext(), {"f-name": "Sugar"}, row: ["Sugar", null]);

      expect(source.structures, 2);
      service.dispose();
    });
  });

  test('a stock movement from the sheet writes its balance in the row', () async {
    final source = _Inventory();
    final service = TableViewService(source: source);
    await service.open("t1");

    final mover = TableStockMover(table: service, tableId: "t1", supplies: true, source: _Stock());
    final moved = await mover.move(
      _NoContext(),
      productId: "r1",
      movement: StockMovement(operation: StockOperation.values.first, quantity: 4)
    );

    expect(moved, isTrue);
    expect(service.rowAt(0)?.at(1), 7);
    expect(service.rowAt(1)?.at(1), 1, reason: "another product is not touched");
    service.dispose();
  });
}

class _Inventory implements InventorySource {
  int structures = 0;
  int pages = 0;
  String answerId = "r3";
  final List<List<dynamic>> _rows = [
    ["r1", "Flour", 3],
    ["r2", "Milk", 1]
  ];

  @override
  Future<TableStructureModel> structure(String tableId) async {
    structures++;
    return TableStructureModel(
      id: tableId,
      records: _rows.length,
      fields: const [
        TableFieldModel(id: "f-name", name: "Name", type: "TEXT"),
        TableFieldModel(id: "f-stock", name: "Stock", type: "STOCK")
      ]
    );
  }

  @override
  Future<({TableViewModel page, int? total})> records(
    String tableId, {
    required int page,
    required int size,
    String match = ""
  }) async {
    pages++;
    return (
      page: TableViewModel(
        columns: const [
          TableColumnModel(id: "id", name: "id"),
          TableColumnModel(id: "f-name", name: "Name"),
          TableColumnModel(id: "f-stock", name: "Stock")
        ],
        rows: [for (final row in _rows.skip((page - 1) * size).take(size)) TableRowModel(row)]
      ),
      total: null
    );
  }

  @override
  Future<String> createRecord(Map<String, dynamic> request) async {
    _rows.add([answerId.isEmpty ? "r3" : answerId, "Sugar", 0]);
    return answerId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Stock implements StockSource {
  @override
  Future<StockBalance> move(StockMovement movement, {required String tableId, required String productId}) async =>
    const StockBalance(onHand: 7, available: 7);

  @override
  Future<List<Presentation>> presentations(String productId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The writes only reach the context to report a failure; these do not fail.
class _NoContext implements BuildContext {
  @override
  bool get mounted => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
