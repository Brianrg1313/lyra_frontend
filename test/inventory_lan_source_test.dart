import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyra_protocol/lyra_protocol.dart';

import 'package:core/core.dart' show Navis, AppSize, ThemeColor, SchemeColor;
import 'package:app/generated/l10n.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/inventory/import_file.dart';
import 'package:app/services/stock/tables/table_normalizing_model.dart';
import 'package:app/services/stock/tables/table_ready_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';

import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/files/cdn_service.dart';
import 'package:app/services/files/file_model.dart';
import 'package:app/services/inventory/product_image.dart';
import 'package:app/services/inventory/table_field_request.dart';
import 'package:app/services/inventory/table_record_request.dart';
import 'package:app/services/inventory/table_request.dart';
import 'package:app/services/business/business_model.dart';
import 'package:app/services/client/sources/session_lan_source.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/stock/movements/stock_movement_model.dart';
import 'package:app/services/stock/sources/inventory_lan_source.dart';
import 'package:app/services/stock/sources/stock_lan_source.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';
import 'package:app/services/stock/summary/stock_summary_service.dart';
import 'package:app/toolkit/backend/deployment.dart';
import 'package:app/toolkit/lan/image.dart';

/// The inventory and stock release of plan phase 4 on the app's side: the services' cloud
/// bodies reach the master in the spec's keys, and its answers (as `lyra_node` sends them,
/// `lyra_node/test/inventory_test.dart`) reach the same models the cloud's do. Also the
/// master's files: drawn over its channel, never from a URL.
void main() {
  late _Master master;

  setUp(() => master = _Master());
  tearDown(() => Deployment.use(DeploymentMode.cloud));

  group('inventory', () {
    test('a cloud body travels in the spec\'s keys', () async {
      final source = InventoryLanSource(master);

      master.answers[Ops.inventoryTablesCreate.name] = {"id": "t1"};
      expect(await source.createTable(createTableRequest(title: " Wines ", description: "", color: "0xFF60A5FA", template: "FOOD")), "t1");
      await source.editField(editFieldRequest(id: "f1", name: "Price", summary: true, width: 180));
      await source.createRecord(createRecordRequest(tableId: "t1", values: {"f1": "22.50"}));

      expect(master.calls.map((call) => call.$2), [
        {"title": "Wines", "color": "0xFF60A5FA", "template": "FOOD"},
        {"id": "f1", "name": "Price", "width": 180, "summary": 1},
        {"tableId": "t1", "data": {"f1": "22.50"}},
      ]);
    });

    test('a page of records lines up with the structure, the record id apart', () async {
      final source = InventoryLanSource(master);
      master.answers[Ops.inventoryTablesStructure.name] = _structure;
      master.answers[Ops.inventoryRecordsList.name] = {
        "keys": ["id", "f-name", "f-stock"],
        "values": [["r1", "Café", 4], ["r2", "Té", 0]],
        "page": 1, "size": 50, "total": 2,
      };

      final structure = await source.structure("t1");
      final (:page, :total) = await source.records("t1", page: 1, size: 50, match: "caf");
      final rows = page.alignedTo(structure.fields).rows;

      expect(total, 2);
      expect(rows.map((row) => row.id), ["r1", "r2"]);
      expect(rows.first.values, ["Café", 4]);
      expect(master.calls.last.$2, {"tableId": "t1", "page": 1, "size": 50, "match": "caf"});
    });

    test('the detail reads its counts, and no agent or channel reaches the table', () async {
      master.answers[Ops.inventoryTablesDetails.name] = {
        "id": "t1", "name": "Products", "description": "", "color": "0xFF60A5FA", "date": "2026-09-30T12:00:00.000Z",
        "records": {"total": 2, "last": "2026-09-30T12:05:00.000Z"},
        "columns": {"total": 2, "types": {"TITLE": 1, "STOCK": 1}, "visibility": {"visible": 2}, "summary": 1, "untyped": 0},
        "agent": {"searchable": false, "filterable": 0, "stock": true, "image": false},
        "channels": {"reached": false, "linked": [], "open": []},
        "fields": {"keys": ["id", "name", "type", "summary"], "values": [["f-name", "Name", "TITLE", true]]},
      };

      final detail = await InventoryLanSource(master).detail("t1");

      expect(detail.records, 2);
      expect(detail.columns.summary, 1);
      expect(detail.channels.reached, isFalse);
      expect(detail.fields.single.summary, isTrue);
    });

    test('a photo goes up first, then into the record\'s image cell', () async {
      final folder = await Directory.systemTemp.createTemp("lyra-photo");
      addTearDown(() => folder.delete(recursive: true));
      final photo = File("${folder.path}/p.png")..writeAsBytesSync([1, 2, 3]);
      master.answers[Ops.inventoryImagesAdd.name] = {"images": [{"id": "0192f0aa-0000-7000-8000-000000000001"}]};

      final images = await InventoryLanSource(master).addImage("t1", "r1", photo);

      expect(master.uploads.single.$1, "product_image");
      expect(master.uploads.single.$2, [1, 2, 3]);
      expect(master.calls.single.$2, {"tableId": "t1", "productId": "r1", "fileId": "uploaded-1"});
      expect(images.single.id, "0192f0aa-0000-7000-8000-000000000001");
    });

    test('an import uploads the file for each step; a master reads .xlsx and .csv only (I-40)', () async {
      final folder = await Directory.systemTemp.createTemp("lyra-import");
      addTearDown(() => folder.delete(recursive: true));
      final file = File("${folder.path}/lista.csv")..writeAsStringSync("Nombre\nCafé\n");
      final source = InventoryLanSource(master);
      master.answers[Ops.inventoryImportStructure.name] = {"id": "t9"};
      master.answers[Ops.inventoryTablesNormalize.name] = {"id": "t9", "retyped": 1, "recast": 1, "reindexed": false};

      expect(await source.importStructure(ImportFormat.csv, file, name: "lista", headerRow: 1), "t9");
      await source.importRecords(ImportFormat.csv, file, tableId: "t9", headerRow: 1);
      final normalized = await source.normalize("t9", timeout: const Duration(minutes: 3));

      expect(master.uploads.map((upload) => upload.$1), ["import", "import"]);
      expect(master.calls.map((call) => call.$2), [
        {"fileId": "uploaded-1", "format": "csv", "name": "lista", "row": 1},
        {"fileId": "uploaded-2", "format": "csv", "tableId": "t9", "row": 1},
        {"tableId": "t9"},
      ]);
      expect(normalized.changedValues, isTrue);

      Deployment.use(DeploymentMode.local, role: DeploymentRole.master);
      expect(CapabilityService().shows("inventory.import"), isTrue);
      expect(importFormatOf("lista.xlsx"), ImportFormat.excel);
      expect(importFormatOf("lista.xls"), isNull);
      expect(importFormatOf("lista.ods"), isNull);
      expect(CapabilityService().shows("channels"), isFalse);
    });

    testWidgets("a master's ready notice can arrive before the wait starts: the rows still go right up (I-45)", (tester) async {
      final folder = (await tester.runAsync(() => Directory.systemTemp.createTemp("lyra-import")))!;
      addTearDown(() => folder.deleteSync(recursive: true));
      final file = File("${folder.path}/lista.csv")..writeAsStringSync("Nombre\nCafé\n");
      master.answers[Ops.inventoryImportStructure.name] = {"id": "t9"};
      master.answers[Ops.inventoryImportRecords.name] = {"imported": 1, "withInvalidCells": 0};
      // The master types before it answers: both notices come with the answer.
      master.before[Ops.inventoryImportStructure.name] = () {
        ConnectionService().receive(TableNormalizingModel.event, {"id": "t9", "normalize": true});
        ConnectionService().receive(TableReadyModel.event, {"id": "t9", "ok": true, "normalized": true});
      };
      final tables = TablesService(source: InventoryLanSource(master));
      late BuildContext context;
      // The banner that says the import ended draws with the theme.
      ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
      ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));

      await tester.pumpWidget(MaterialApp(
        navigatorKey: Navis.delegate.navigatorKey,
        localizationsDelegates: const [S.delegate, GlobalWidgetsLocalizations.delegate, GlobalMaterialLocalizations.delegate],
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(builder: (built) {
          context = built;
          AppSize.instance(built);
          return const SizedBox();
        }),
      ));

      final started = await tester.runAsync(() async {
        final result = await tables.import(context, file);
        // The second step reads the file again; real I/O needs real time.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return result;
      });

      expect(started, TableImportResult.started);
      expect(master.calls.map((call) => call.$1), [Ops.inventoryImportStructure.name, Ops.inventoryImportRecords.name]);
      expect(tables.importStage("t9"), isNull);

      await tester.pump(const Duration(seconds: 10));
      tables.dispose();
    });
  });

  group('stock', () {
    test('a movement is one stock.move with its operation, reason and note', () async {
      master.answers[Ops.stockMove.name] = {"onHand": 9, "reserved": 3, "available": 6, "returns": 0, "needsReview": false};

      final balance = await StockLanSource(master).move(
        const StockMovement(operation: StockOperation.receiveReturn, quantity: 2, reason: StockReason.defective, note: " torn "),
        tableId: "t1",
        productId: "r1",
      );

      expect(balance.available, 6);
      expect(master.calls.single.$2, {
        "operation": "return", "tableId": "t1", "productId": "r1", "quantity": 2, "reason": "defective", "note": "torn",
      });
      for (final operation in StockOperation.values) {
        expect(StockOperations.reasons.keys, contains(StockLanSource.operationOf(operation)));
      }
      // A cloud-only reason (waste) is never offered against a master.
      for (final reason in StockReason.values.where((reason) => !reason.cloudOnly)) {
        expect(StockOperations.reasons[StockLanSource.operationOf(reason.operation)], contains(reason.key));
      }
    });

    test('the summary reads its cover, numbers and fixed columns', () async {
      master.answers[Ops.stockSummary.name] = {
        "table": "t1", "total": 1, "page": 1, "size": 30,
        "columns": [
          {"key": "image", "name": null, "type": "IMAGE", "fixed": true},
          {"key": "f-name", "name": "Name", "type": "TITLE", "fixed": false},
          {"key": "stock", "name": null, "type": "STOCK", "fixed": true},
          {"key": "reserved", "name": null, "type": "NUMBER", "fixed": true},
          {"key": "performance", "name": null, "type": "NUMBER", "fixed": true},
        ],
        "data": {
          "keys": ["id", "image", "f-name", "stock", "reserved", "performance", "needsReview"],
          "values": [["r1", {"id": "0192f0aa-0000-7000-8000-000000000001"}, "Café", 4, 1, null, false]],
        },
      };

      final page = await StockLanSource(master).summary(page: 1, size: 30);
      final row = page.rows.single;

      expect(page.columns.map((column) => column.fixed), [true, false, true, true, true]);
      expect(row.id, "r1");
      expect(row.cover?.id, "0192f0aa-0000-7000-8000-000000000001");
      expect((row.stock, row.reserved), (4, 1));
    });

    test("the summary's order reaches the master as sort (ST-35)", () async {
      master.answers[Ops.stockSummary.name] = {"table": "t1", "total": 0, "columns": [], "data": {"keys": ["id"], "values": []}};

      await StockLanSource(master).summary(page: 1, size: 30, sort: const StockSummarySort("f-price", descending: true));

      expect(master.calls.single.$2, {"page": 1, "size": 30, "sort": {"field": "f-price", "dir": "desc"}});
    });

    test('a master without a main table says so by code, and the summary reads it as missing', () async {
      Deployment.use(DeploymentMode.local, role: DeploymentRole.client);
      master.refusals[Ops.stockSummary.name] = {"message": "There is no main table yet.", "action": null, "code": "no_primary_table"};

      final service = StockSummaryService(source: StockLanSource(master));
      await service.load();

      expect(service.status, StockSummaryStatus.missing);
    });
  });

  group('files', () {
    test('on a master a file is an address of its channel, drawn by LanFileImage', () {
      Deployment.use(DeploymentMode.local, role: DeploymentRole.client);

      const photo = ProductImage.stored("0192f0aa-0000-7000-8000-000000000001");
      expect(photo.thumbnail, "lyra-file:0192f0aa-0000-7000-8000-000000000001@${FileSizes.thumbnail}");
      expect(mediaImage(photo.thumbnail), const LanFileImage("0192f0aa-0000-7000-8000-000000000001", size: FileSizes.thumbnail));
      expect(mediaImage(photo.url), const LanFileImage("0192f0aa-0000-7000-8000-000000000001"));
      expect(mediaImage("https://example.com/a.png"), isA<NetworkImage>());
      expect(CdnService().url(FileScope.media, ""), "");
    });

    test('the bootstrap\'s logo is a file with its one thumbnail', () {
      Deployment.use(DeploymentMode.local, role: DeploymentRole.client);

      final init = SessionLanSource.initFrom({
        "client": {"name": "Ada"},
        "businesses": [{"id": "c1", "name": "Lovelace Café", "logo": "l1", "currency": "USD"}],
        "catalogs": {},
      });
      final logo = BusinessModel.fromTable(init["businesses"]).single.logo!;

      expect(logo.thumbnail, "lyra-file:l1@${FileSizes.thumbnail}");
    });
  });
}

const _structure = {
  "id": "t1", "name": "Products", "description": "", "color": "0xFF60A5FA", "date": "2026-09-30T12:00:00.000Z",
  "records": 2,
  "fields": {
    "keys": ["id", "name", "type", "width", "options", "unit"],
    "values": [["f-name", "Name", "TITLE", null, [], ""], ["f-stock", "Stock", "STOCK", null, [], ""]],
  },
};

/// The master as a LAN source sees it: [LanService.call] and [LanService.upload] answering what
/// `lyra_node` would.
class _Master extends LanService {
  final Map<String, Object?> answers = {};
  final Map<String, Map<String, Object?>> refusals = {};
  final Map<String, void Function()> before = {};
  final List<(String, Map<String, Object?>)> calls = [];
  final List<(String, List<int>)> uploads = [];

  @override
  LanStatus get status => LanStatus.ready;

  @override
  Future<Object?> call(Op op, {Map<String, Object?> args = const {}}) async {
    calls.add((op.name, args));
    before[op.name]?.call();
    final refusal = refusals[op.name];
    if (refusal != null) throw refusal;

    return answers[op.name];
  }

  @override
  Future<String> upload(String purpose, Uint8List bytes) async {
    uploads.add((purpose, bytes.toList()));

    return "uploaded-${uploads.length}";
  }
}
