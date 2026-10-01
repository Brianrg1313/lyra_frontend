import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lyra_protocol/lyra_protocol.dart';

import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/money/money_concept_model.dart';
import 'package:app/services/money/money_currency_model.dart';
import 'package:app/services/money/money_currency_request.dart';
import 'package:app/services/money/money_payment_model.dart';
import 'package:app/services/money/money_payment_request.dart';
import 'package:app/services/money/sources/money_lan_source.dart';

/// The finance release of plan phase 4 on the app's side: the summary, the payments, the
/// receivables and the currencies reach the master in its keys, and its answers (as `lyra_node`
/// sends them, `lyra_node/test/finance_test.dart`) reach the models with money as amounts.
void main() {
  late _Master master;

  setUp(() => master = _Master());

  test('the summary: every figure in minor units reads as the amount (M-20 to M-28)', () async {
    master.answers[Ops.moneySummary.name] = {
      "from": "2026-09-30T04:00:00.000Z", "to": "2026-09-30T15:00:00.000Z", "currency": "USD",
      "income": {"sales": {"count": 1, "total": 580}, "payments": {"count": 1, "total": 1000}, "total": 1580},
      "expenses": {"count": 1, "total": 300},
      "credit": {"count": 0, "total": 0},
      "net": 1280,
      "methods": [{"method": "transfer", "name": "Transferencia", "in": 580, "out": 300, "net": 280, "count": 2}],
      "concepts": [{"concept": "supplier", "name": "Pago a proveedor", "direction": "out", "count": 1, "total": 300}],
    };

    final summary = await MoneyLanSource(master).summary(from: DateTime.utc(2026, 9, 23));

    expect(master.calls.single.$2, {"from": "2026-09-23T00:00:00.000Z"});
    expect([summary.sales.total, summary.payments.total, summary.income], [5.8, 10.0, 15.8]);
    expect([summary.expenses.total, summary.net, summary.credit.total], [3.0, 12.8, 0.0]);
    expect(summary.methods.single.income, 5.8);
    expect(summary.methods.single.net, 2.8);
    expect(summary.concepts.single.direction, MoneyDirection.outgoing);
    expect(summary.concepts.single.total, 3.0);
  });

  test('a page of payments: the filter travels in the master\'s keys, totals as amounts (M-10)', () async {
    master.answers[Ops.moneyPaymentsSearch.name] = {
      "total": 1, "page": 1, "size": 30,
      "totals": {"in": {"count": 0, "total": 0}, "out": {"count": 1, "total": 25050}},
      "data": [
        {"id": "p1", "direction": "out", "concept": "supplier", "conceptName": "Pago a proveedor", "amount": 25050,
          "currency": "USD", "method": "transfer", "account": null, "counterpart": "Distribuidora Lara",
          "status": "voided", "registeredBy": "Ada Owner", "date": "2026-09-27T12:00:00.000Z"},
      ],
    };

    final page = await MoneyLanSource(master).payments(
      page: 1, size: 30, direction: MoneyDirection.outgoing, state: MoneyPaymentStatus.voided);

    expect(master.calls.single.$2, {"page": 1, "size": 30, "direction": "out", "status": "voided"});
    expect(page.isLoaded, isTrue);
    expect(page.totals.expense.total, 250.5);
    expect(page.payments.single.amount, 250.5);
    expect(page.payments.single.counterpart, "Distribuidora Lara");
    expect(page.payments.single.isVoided, isTrue);
  });

  test('recording: the cloud\'s body in the master\'s keys, the amount in minor units (M-1 to M-9)', () async {
    final date = DateTime.utc(2026, 9, 26, 12);

    await MoneyLanSource(master).recordPayment(recordPaymentRequest(
      concept: "supplier", amount: 250.5, method: "transfer", reference: " 004512 ",
      counterpartName: "Distribuidora Lara", note: "Pedido", ticket: "A-000001", date: date));
    await MoneyLanSource(master).recordPayment(recordPaymentRequest(concept: "rent", amount: 1.234, method: "cash"));

    expect(master.calls.first.$2, {
      "concept": "supplier", "amount": 25050, "method": "transfer", "reference": "004512",
      "counterpart": {"name": "Distribuidora Lara"}, "note": "Pedido", "ticket": "A-000001",
      "date": "2026-09-26T12:00:00.000Z",
    });
    // More decimals than the currency has: sent as typed, for the master to refuse (M-2).
    expect(master.calls.last.$2, {"concept": "rent", "amount": 1.234, "method": "cash"});

    await MoneyLanSource(master).voidPayment(id: "p1", reason: " ");
    expect(master.calls.last.$1, Ops.moneyPaymentsVoid.name);
    expect(master.calls.last.$2, {"id": "p1"});
  });

  test('receivables: the open filter travels, figures as amounts (M-31, M-32)', () async {
    master.answers[Ops.moneyReceivables.name] = {
      "total": 0, "page": 1, "size": 30, "currency": "USD",
      "totals": {"count": 0, "sold": 0, "collected": 0, "outstanding": 0},
      "data": <Object?>[],
    };

    final page = await MoneyLanSource(master).receivables(page: 1, size: 30, openOnly: true);

    expect(master.calls.single.$2, {"page": 1, "size": 30, "open": true});
    expect(page.sales, isEmpty);
  });

  test('currencies: rates travel as they are; the catalogue splits the concepts (M-51, money.catalog)', () async {
    master.answers[Ops.moneyCurrenciesGet.name] = {
      "currency": "USD",
      "currencies": [{"currency": "VES", "mode": "custom", "rate": 36.5, "official": null, "custom": 36.5}],
    };
    master.answers[Ops.moneyCatalog.name] = {
      "concepts": {
        "in": [{"concept": "advance", "name": "Anticipo de un pedido", "direction": "in"}],
        "out": [{"concept": "customer_refund", "name": "Devolución a un cliente", "direction": "out", "ticket": true}],
      },
      "methods": [{"method": "cash", "name": "Efectivo", "reference": false, "change": true, "default": true}],
    };
    final source = MoneyLanSource(master);

    final currencies = await source.currencies();
    await source.saveCurrency(saveMoneyExchangeRequest(currency: "ves", mode: MoneyRateMode.custom, rate: 40));
    await source.removeCurrency("eur");
    final catalog = await source.catalog();

    expect(currencies.exchange("VES")!.rate, 36.5);
    expect(master.calls[1].$2, {"currency": "VES", "mode": "custom", "rate": 40});
    expect(master.calls[2].$2, {"currency": "EUR"});
    expect(catalog.incoming.single.direction, MoneyDirection.incoming);
    expect(catalog.outgoing.single.ticket, isTrue);
    expect(catalog.settlements.single.method, "cash");
    expect(() => source.methods(), throwsUnsupportedError);
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
