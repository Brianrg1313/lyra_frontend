import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lyra_protocol/lyra_protocol.dart';

import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/pos/pos_invoice_service.dart';
import 'package:app/services/pos/pos_product_model.dart';
import 'package:app/services/pos/sources/pos_lan_source.dart';

/// The POS release of plan phase 4 on the app's side: the services' cloud bodies reach the master
/// in the spec's keys with money in minor units and percents as text, and its answers (as
/// `lyra_node` sends them, `lyra_node/test/pos_test.dart`) reach the models as the amounts the
/// cloud's do.
void main() {
  late _Master master;

  setUp(() => master = _Master());

  Map<String, Object?> invoice({List<Map<String, Object?>> items = const [], String currency = "USD"}) => {
    "id": "i1", "ticket": "A-000001", "status": "open", "open": true, "currency": currency,
    "items": items, "units": 2, "held": 2, "subtotal": 900, "tax": 68, "total": 968,
    "taxes": [{"rate": "7.5", "base": 900, "amount": 68}], "payment": null,
  };

  test('the catalogue: a price in minor units reads as the amount; an untracked product counts nothing (POS-1, POS-6)', () async {
    master.answers[Ops.posCatalog.name] = {
      "table": "t1", "size": 2, "cursor": "abc", "more": true, "currency": "CLP",
      "data": {
        "keys": ["id", "name", "sku", "barcode", "price", "stock", "reserved", "image", "categories"],
        "values": [
          ["r1", "Café", "C-1", null, 1500, 4, 1, {"id": "0192f0aa-0000-7000-8000-000000000001"}, ["Bebidas"]],
          ["r2", "Corte", null, null, null, null, null, null, []],
        ],
      },
    };

    final page = await PosLanSource(master).catalog(size: 2, search: "caf");
    final [cafe, corte] = page.products;

    expect(master.calls.single.$2, {"size": 2, "search": "caf"});
    expect(page.cursor, "abc");
    expect(cafe.price, 1500);
    expect(cafe.stock, 4);
    expect(cafe.categories, ["Bebidas"]);
    expect(corte.price, isNull);
    expect(corte.stock, isNull);
    expect(corte.isSoldOut, isFalse);
  });

  test('a ticket\'s money reads as amounts, per line and per rate (POS-20)', () async {
    master.answers[Ops.posInvoicesList.name] = {
      "invoices": [
        invoice(items: [
          {"lineId": "l1", "productId": "r1", "name": "Pan", "qty": 3, "held": 3, "price": 300, "list": 333,
            "discount": "10", "taxRate": "7.5", "subtotal": 900, "tax": 68, "total": 968, "tracked": true},
          {"lineId": "l2", "productId": "r2", "name": "Corte", "qty": 1, "held": 0, "price": 800, "list": 800,
            "discount": null, "taxRate": "0", "subtotal": 800, "tax": 0, "total": 800, "tracked": false},
        ]),
      ],
    };

    final [ticket] = await PosLanSource(master).openInvoices(mine: true, size: 1);

    expect(master.calls.single.$2, {"mine": true, "size": 1});
    expect([ticket.subtotal, ticket.tax, ticket.total], [9.0, 0.68, 9.68]);
    expect(ticket.items.first.price, 3.0);
    expect(ticket.items.first.taxRate, 7.5);
    expect(ticket.items.first.tracked, isTrue);
    expect(ticket.items.last.tracked, isFalse);
  });

  test('the service\'s line bodies travel in the spec\'s keys; a typed charge\'s price in minor units (POS-11, POS-14, POS-17)', () async {
    final source = PosLanSource(master);
    master.answers[Ops.posInvoicesOpen.name] = invoice();
    master.answers[Ops.posInvoicesLine.name] = {"invoice": invoice()};

    await source.open(tax: 16);
    await source.writeLine("i1", {"PRODUCT_ID": "r1", "ADD": 1, "TAX": 7.5});
    await source.writeLine("i1", {"CONCEPT": "Envío", "ADD": 1, "PRICE": 1.5, "TAX": 0.0});
    await source.writeLine("i1", {"LINE_ID": "l1", "QUANTITY": 0});
    await source.close("i1", method: "transfer", reference: " 0099 ");
    await source.cancel("i2");

    expect(master.calls.map((call) => call.$2), [
      {"tax": "16"},
      {"id": "i1", "productId": "r1", "add": 1, "tax": "7.5"},
      {"id": "i1", "concept": "Envío", "add": 1, "price": 150, "tax": "0"},
      {"id": "i1", "lineId": "l1", "quantity": 0},
      {"id": "i1", "method": "transfer", "reference": "0099"},
      {"id": "i2"},
    ]);
  });

  test('a product nobody counts goes on the ticket without being drawn as released (POS-6)', () async {
    master.answers[Ops.posInvoicesOpen.name] = invoice(items: const []);
    master.answers[Ops.posInvoicesLine.name] = {
      "invoice": invoice(items: [
        {"lineId": "l1", "productId": "r2", "name": "Corte", "qty": 1, "held": 0, "price": 800, "taxRate": "0",
          "subtotal": 800, "tax": 0, "total": 800, "tracked": false},
      ]),
    };
    final ticket = PosInvoiceService(source: PosLanSource(master));
    addTearDown(ticket.dispose);

    expect(await ticket.add(const PosProduct(id: "r2", name: "Corte", price: 8)), isTrue);

    expect(ticket.lines.single.held, 0);
    expect(ticket.lines.single.isHeld, isTrue);
    expect(ticket.ticket, "A-000001");
  });

  test('a percent goes as the master writes it', () {
    expect(PosLanSource.percent(16), "16");
    expect(PosLanSource.percent(7.5), "7.5");
    expect(PosLanSource.percent(0.125), "0.125");
    expect(PosLanSource.minor(9.99, 2), 999);
    expect(PosLanSource.major(999, 2), 9.99);
    expect(PosLanSource.major(null, 2), isNull);
  });
}

class _Master extends LanService {
  final Map<String, Object?> answers = {};
  final List<(String, Map<String, Object?>)> calls = [];

  @override
  LanStatus get status => LanStatus.ready;

  @override
  Future<Object?> call(Op op, {Map<String, Object?> args = const {}}) async {
    calls.add((op.name, args));

    return answers[op.name];
  }

  @override
  Future<String> upload(String purpose, Uint8List bytes) async => "uploaded";
}
