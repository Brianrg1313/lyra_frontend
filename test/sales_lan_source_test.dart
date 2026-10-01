import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lyra_protocol/lyra_protocol.dart';

import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/sales/sale_detail_service.dart';
import 'package:app/services/sales/sale_fulfillment_request.dart';
import 'package:app/services/sales/sale_model.dart';
import 'package:app/services/sales/sales_catalog_service.dart';
import 'package:app/services/sales/sources/sales_lan_source.dart';

/// The sales release of plan phase 4 on the app's side: the board, the handover and the detail
/// reach the master in its keys, and its answers (as `lyra_node` sends them,
/// `lyra_node/test/sales_test.dart`) reach the models with money as amounts.
void main() {
  late _Master master;

  setUp(() => master = _Master());

  test('a page of the board: money in minor units reads as the amount; mine travels (SA-10)', () async {
    master.answers[Ops.salesList.name] = {
      "section": "done", "page": 1, "size": 30, "total": 1,
      "sales": [
        {"id": "i1", "source": "ticket", "ticket": "A-000001", "stage": "completed", "label": "Venta completada",
          "level": "success", "attention": false, "since": "2026-09-30T12:00:00.000Z", "channel": "pos",
          "customer": null, "units": 2, "total": 580, "currency": "USD", "method": "cash", "collected": null,
          "outstanding": null, "mode": "immediate", "state": "done", "seller": "Ada Owner", "chat": ""},
      ],
    };

    final page = await SalesLanSource(master).page(section: SaleSection.done, mine: true, page: 1, size: 30);
    final row = page.sales.single;

    expect(master.calls.single.$2, {"section": "done", "mine": true, "page": 1, "size": 30});
    expect(page.section, SaleSection.done);
    expect(row.total, 5.8);
    expect(row.outstanding, isNull);
    expect(row.seller, "Ada Owner");
    expect(row.canFulfil, isFalse);
  });

  test('the handover travels in the master\'s keys and answers the row with its section (SA-22, SA-24)', () async {
    master.answers[Ops.salesFulfil.name] = {
      "id": "i1", "source": "ticket", "stage": "shipping", "section": "process", "total": 1500, "currency": "CLP",
      "mode": "delivery", "state": "pending",
    };

    final row = await SalesLanSource(master).fulfil(fulfilSaleRequest(id: "i1", mode: "delivery", note: " TRK-1 "));

    expect(master.calls.single.$2, {"id": "i1", "mode": "delivery", "note": "TRK-1"});
    expect(row!.section, SaleSection.process);
    expect(row.total, 1500);
    expect(row.canFulfil, isTrue);
  });

  test('the detail: lines, taxes and totals as amounts; a ticket has no holds list (SA-31, SA-32)', () async {
    master.answers[Ops.salesDetail.name] = {
      "id": "i1", "source": "ticket", "ticket": "A-000001", "status": "completed", "stage": "completed",
      "section": "done", "currency": "USD", "units": 2, "subtotal": 500, "tax": 80, "total": 580,
      "taxes": [{"rate": "16", "base": 500, "amount": 80}],
      "payment": {"method": "transfer", "name": "Transferencia", "reference": "0099", "credit": false,
        "collected": null, "outstanding": null, "proofs": []},
      "fulfillment": {"mode": "immediate", "modeName": "Entregado en el momento", "state": "done",
        "stateName": "Entregado", "stored": false},
      "held": 0, "reservations": null,
      "items": [
        {"productId": "p1", "name": "Café", "qty": 2, "price": 250, "list": 300, "discount": "16.67",
          "subtotal": 500, "taxRate": "16", "tax": 80, "total": 580, "held": 0, "state": "", "gone": false},
      ],
      "origin": {"kind": "pos", "channel": "pos", "terminal": "Caja 1"},
    };

    final sale = await SalesLanSource(master).detail("a-000001");
    final item = sale.items.single;

    expect(master.calls.single.$2, {"reference": "a-000001"});
    expect([sale.subtotal, sale.tax, sale.total], [5.0, 0.8, 5.8]);
    expect(sale.taxes.single.rate, 16);
    expect(sale.taxes.single.amount, 0.8);
    expect([item.price, item.list, item.discount, item.taxRate], [2.5, 3.0, 16.67, 16]);
    expect(sale.reservations, isNull);
    expect(sale.payment.proofs, isEmpty);
    expect(sale.handover!.isDelivered, isTrue);
    expect(sale.origin!.terminal, "Caja 1");
  });

  test('a reference the master doesn\'t know is news, not an error (SA-30)', () async {
    master.failures[Ops.salesDetail.name] = {
      "message": "There is no sale with that reference.", "action": null, "code": "sale_not_found",
    };
    final detail = SaleDetailService(source: SalesLanSource(master));
    addTearDown(detail.dispose);

    await detail.load("Z-000009");

    expect(detail.status, SaleDetailStatus.missing);
  });

  test('stages, handover modes and channels come from one catalogue (SA-2)', () async {
    master.answers[Ops.salesCatalog.name] = {
      "stages": [{"stage": "open", "name": "Ticket abierto", "section": "process", "level": "info", "attention": true}],
      "handover": [
        {"mode": "pickup", "name": "Retiro en tienda", "states": [{"state": "pending", "name": "Sin entregar"}]},
      ],
      "channels": [{"channel": "pos", "name": "Punto de venta", "default": true}],
    };
    final catalog = SalesCatalogService(source: SalesLanSource(master));
    addTearDown(catalog.dispose);

    await catalog.load();

    expect(catalog.stages.single.attention, isTrue);
    expect(catalog.handover.single.find("pending")!.name, "Sin entregar");
    expect(catalog.channels.single.isDefault, isTrue);
  });
}

class _Master extends LanService {
  final Map<String, Object?> answers = {};
  final Map<String, Map<String, Object?>> failures = {};
  final List<(String, Map<String, Object?>)> calls = [];

  @override
  LanStatus get status => LanStatus.ready;

  @override
  Future<Object?> call(Op op, {Map<String, Object?> args = const {}}) async {
    calls.add((op.name, args));

    final failure = failures[op.name];
    if (failure != null) throw failure;

    return answers[op.name];
  }

  @override
  Future<String> upload(String purpose, Uint8List bytes) async => "uploaded";
}
