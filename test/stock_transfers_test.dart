import 'package:flutter_test/flutter_test.dart';
import 'package:lyra_protocol/lyra_protocol.dart' show Grant, PermissionCatalog;

import 'package:app/services/business/branch_service.dart';
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/permissions/permission_member_model.dart';
import 'package:app/services/permissions/sources/permissions_source.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';
import 'package:app/services/stock/transfers/stock_transfer_model.dart';
import 'package:app/services/stock/transfers/stock_transfer_request.dart';
import 'package:app/services/stock/transfers/stock_transfers_service.dart';

/// Stock moving between branches (`sedes-frontend.md` §6): the sender drafts, sends and calls
/// back; the receiver counts in, and what is missing is written off with a reason.
Map<String, dynamic> _transfer({
  String id = "t1",
  String from = "centro",
  String to = "chacao",
  String status = "sent",
  List<Map<String, dynamic>>? lines
}) => {
  "id": id,
  "from": from,
  "to": to,
  "tableId": "table-1",
  "status": status,
  "lines": lines ?? [
    {"productId": "p1", "sku": "SKU-1", "qty": 5, "received": null, "shortage": null},
    {"productId": "p2", "sku": null, "qty": 2, "received": null, "shortage": null}
  ],
  "units": 7,
  "received": null,
  "note": "Fragile",
  "settled": true,
  "createdAt": "2026-10-08T12:00:00Z",
  "sentAt": "2026-10-08T13:00:00Z"
};

void main() {
  setUp(() => BranchService().seed("b-1", [
    BusinessBranchModel.from({"id": "centro", "name": "Centro", "main": true})!,
    BusinessBranchModel.from({"id": "chacao", "name": "Chacao"})!
  ], active: "chacao"));
  tearDown(() => BranchService().clear());

  group("reading", () {
    test("a transfer reads its branches, lines and figures", () {
      final transfer = StockTransfer.read(_transfer())!;

      expect(transfer.status, StockTransferStatus.sent);
      expect(transfer.from, "centro");
      expect(transfer.lines.map((line) => line.quantity), [5, 2]);
      expect(transfer.lines.first.sku, "SKU-1");
      expect(transfer.units, 7);
      expect(transfer.received, isNull);
      expect(transfer.movedAt, DateTime.parse("2026-10-08T13:00:00Z").toLocal());
      expect(transfer.sentBy("chacao"), isFalse);
    });

    test("a received line says what arrived and what the rest was written off as", () {
      final transfer = StockTransfer.read({
        ..._transfer(status: "received"),
        "lines": [{"productId": "p1", "qty": 5, "received": 3, "shortage": "damage"}],
        "received": 3
      })!;

      expect(transfer.lines.single.received, 3);
      expect(transfer.lines.single.shortage, StockShortage.damage);
      expect(transfer.received, 3);
    });

    test("what can't be a transfer is not one", () {
      expect(StockTransfer.read({"id": "t1", "status": "lost", "from": "a", "to": "b"}), isNull);
      expect(StockTransfer.read({"status": "sent", "from": "a", "to": "b"}), isNull);
      expect(StockTransfersPage.fromJson({"total": 1, "transfers": [_transfer(), {"id": ""}]}).transfers, hasLength(1));
    });
  });

  test("the summary's transit column is a number: what is on its way here", () {
    final page = StockSummaryPage.fromResponse({
      "columns": [{"key": "stock"}, {"key": "reserved"}, {"key": "transit"}],
      "data": {"keys": ["id", "stock", "reserved", "transit"], "values": [["p1", 4, 0, 6]]}
    });

    expect(page.columns.last.isTransit, isTrue);
    expect(page.columns.last.isNumber, isTrue);
    expect(page.columns.last.fixed, isTrue);
    expect(page.rows.single.transit, 6);
  });

  group("bodies", () {
    test("a new transfer sends its lines with units, and SEND only to send at once", () {
      final body = createTransferRequest(
        toBranch: "chacao",
        items: [(productId: "p1", quantity: 3), (productId: "p2", quantity: 0)],
        tableId: "table-1",
        note: "  ",
        send: true
      );

      expect(body, {
        "TO_BRANCH": "chacao",
        "ITEMS": [{"PRODUCT_ID": "p1", "QUANTITY": 3}],
        "TABLE_ID": "table-1",
        "SEND": true
      });
      expect(createTransferRequest(toBranch: "x", items: const []).containsKey("SEND"), isFalse);
    });

    test("receiving names only the lines that arrived short", () {
      final transfer = StockTransfer.read(_transfer())!;
      final body = receiveTransferRequest(transfer, {
        "p1": (received: 5, reason: StockShortage.loss),
        "p2": (received: 1, reason: StockShortage.theft)
      });

      expect(body, {
        "ID": "t1",
        "ITEMS": [{"PRODUCT_ID": "p2", "RECEIVED": 1, "REASON": "theft"}]
      });
    });

    test("send and cancel are one action each; the search filters by side and status", () {
      expect(transferActionRequest("t1", send: true), {"ID": "t1", "ACTION": "send"});
      expect(transferActionRequest("t1", send: false), {"ID": "t1", "ACTION": "cancel"});
      expect(searchTransfersRequest(direction: "in", status: StockTransferStatus.sent), {
        "DIRECTION": "in", "STATUS": "sent", "PAGE": 1, "SIZE": 50
      });
    });
  });

  group("the service", () {
    test("opens on what is on its way here, and the buttons follow the person's grant", () async {
      final source = _Source([StockTransfer.read(_transfer())!]);
      final service = StockTransfersService(
        source: source,
        permissions: _Permissions(Grant(sections: PermissionCatalog.fromKeys(["inventory", "inventory.receive"])))
      );
      await service.load();
      await pumpEventQueue();

      expect(source.searches.first, {"DIRECTION": "in", "STATUS": "sent", "PAGE": 1, "SIZE": 30});
      expect(service.transfers, hasLength(1));
      expect(service.canReceive, isTrue);
      expect(service.canSend, isFalse);
      expect(service.destinations, ["centro"]);

      service.dispose();
    });

    test("a transfer received elsewhere leaves the on-its-way list", () {
      final service = StockTransfersService(source: _Source(const []), permissions: _Permissions(Grant.none()))
        ..seed([StockTransfer.read(_transfer())!], filter: StockTransferStatus.sent);

      service.receiveEvent(_transfer(status: "received"));

      expect(service.transfers, isEmpty);
      expect(service.status, StockTransfersStatus.empty);

      service.dispose();
    });

    test("a write's answer replaces its row", () async {
      final source = _Source(const [])..answer = StockTransfer.read(_transfer(status: "sent", from: "chacao", to: "centro"))!;
      final service = StockTransfersService(source: source, permissions: _Permissions(Grant.everything()))
        ..seed([StockTransfer.read(_transfer(status: "draft", from: "chacao", to: "centro"))!], side: StockTransferSide.outgoing);

      await service.send(service.transfers.single);

      expect(source.updates.single, {"ID": "t1", "ACTION": "send"});
      expect(service.transfers.single.status, StockTransferStatus.sent);

      service.dispose();
    });

    test("the lines' names come from their table's summary, its first text column", () async {
      final service = StockTransfersService(source: _Source([StockTransfer.read(_transfer())!]), permissions: _Permissions(Grant.none()));
      await service.load();
      await pumpEventQueue();

      expect(service.nameOf("p1"), "Harina");
      expect(service.nameOf("p2"), "");

      service.dispose();
    });

    test("a product to send says what is free of it: stock less what is held", () async {
      final service = StockTransfersService(source: _Source(const []), permissions: _Permissions(Grant.none()));

      final found = await service.searchProducts("har");

      expect(found.single.name, "Harina");
      expect(found.single.available, 8);
      expect(found.single.table, "table-1");

      service.dispose();
    });
  });
}

class _Source implements StockSource {
  _Source(this.transfersFound);

  final List<StockTransfer> transfersFound;
  final searches = <Map<String, dynamic>>[];
  final updates = <Map<String, dynamic>>[];
  StockTransfer? answer;

  @override
  Future<StockTransfersPage> transfers(Map<String, dynamic> request) async {
    searches.add(request);
    return StockTransfersPage(total: transfersFound.length, transfers: transfersFound);
  }

  @override
  Future<StockTransfer> updateTransfer(Map<String, dynamic> request) async {
    updates.add(request);
    return answer!;
  }

  @override
  Future<StockSummaryPage> summary({
    required int page,
    required int size,
    String match = "",
    String tableId = "",
    StockSummarySort? sort
  }) async => StockSummaryPage.fromResponse({
    "table": "table-1",
    "total": 1,
    "page": 1,
    "size": size,
    "columns": [
      {"key": "image"},
      {"key": "f-name", "name": "Name", "type": "text"},
      {"key": "stock"},
      {"key": "reserved"}
    ],
    "data": {
      "keys": ["id", "image", "f-name", "stock", "reserved"],
      "values": [["p1", null, "Harina", 10, 2]]
    }
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Permissions implements PermissionsSource {
  _Permissions(this._grant);

  final Grant _grant;

  @override
  Future<Grant> mine() async => _grant;

  @override
  Future<PermissionMemberModel> member(String username) => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
