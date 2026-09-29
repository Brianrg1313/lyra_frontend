import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/money/money_currency_model.dart';
import 'package:app/services/money/money_currency_request.dart';
import 'package:app/services/money/money_method_model.dart';
import 'package:app/services/money/money_method_request.dart';

/// The currency setup and the two things every account now carries: the
/// currency money comes in as, and the commission it adds to the charge.
///
/// What is pinned is the contract in `lib/services/money/currencies_contract.md`
/// and the readings that keep a bad row from becoming a price: a rate of zero
/// is no rate, the main currency is never its own exchange, and a commission
/// of nothing is no commission.
void main() {
  group('MoneyCurrencies', () {
    test('reads the main currency and its exchanges', () {
      final setup = MoneyCurrencies.fromJson(const {
        "currency": "usd",
        "currencies": [
          {
            "currency": "ves",
            "mode": "custom",
            "rate": 40.5,
            "official": "36.52",
            "custom": 40.5,
            "updated": "2026-09-23T10:00:00Z"
          },
          {"currency": "EUR", "mode": "official", "rate": 0.92, "official": 0.92}
        ]
      });

      expect(setup.main, "USD");
      expect(setup.codes, ["USD", "VES", "EUR"]);

      final ves = setup.exchange("ves")!;
      expect(ves.mode, MoneyRateMode.custom);
      expect(ves.rate, 40.5);
      expect(ves.official, 36.52);
      expect(ves.updated, DateTime.utc(2026, 9, 23, 10));

      expect(setup.exchange("EUR")!.mode, MoneyRateMode.official);
    });

    test('the main currency is never its own exchange', () {
      final setup = MoneyCurrencies.fromJson(const {
        "currency": "USD",
        "currencies": [{"currency": "USD", "rate": 1}, {"currency": "VES"}]
      });

      // `1 USD = 1 USD` is a card that says nothing.
      expect(setup.codes, ["USD", "VES"]);
    });

    test('a rate that is not positive is no rate', () {
      final setup = MoneyCurrencies.fromJson(const {
        "currency": "USD",
        "currencies": [
          {"currency": "VES", "rate": 0, "official": -3},
          {"currency": "COP", "rate": "abc"}
        ]
      });

      // Drawn as "no rate" and never as `1 USD = Bs. 0,00`, which is a price
      // somebody would charge.
      expect(setup.exchange("VES")!.rate, isNull);
      expect(setup.exchange("VES")!.official, isNull);
      expect(setup.exchange("COP")!.hasRate, isFalse);
    });

    test('an unknown mode reads as the official one', () {
      final row = MoneyExchange.fromJson(const {"currency": "VES", "mode": "x"});

      expect(row.mode, MoneyRateMode.official);
    });
  });

  group('exchange requests', () {
    test('a custom rate travels with its figure', () {
      expect(
        saveMoneyExchangeRequest(
          currency: "ves",
          mode: MoneyRateMode.custom,
          rate: 40.5
        ),
        {"CURRENCY": "VES", "MODE": "custom", "RATE": 40.5}
      );
    });

    test('an official rate never carries one', () {
      // A client that could send a figure as "official" could write any rate.
      expect(
        saveMoneyExchangeRequest(
          currency: "VES",
          mode: MoneyRateMode.official,
          rate: 40.5
        ),
        {"CURRENCY": "VES", "MODE": "official"}
      );
    });

    test('removal names the currency', () {
      expect(removeMoneyExchangeRequest("ves"), {"CURRENCY": "VES"});
    });
  });

  group('MoneyFee', () {
    test('reads its type and value', () {
      final fee = MoneyFee.fromJson(const {"type": "percent", "value": "3.5"});

      expect(fee.type, MoneyFeeType.percent);
      expect(fee.value, 3.5);
    });

    test('a commission of nothing is no commission', () {
      expect(MoneyFee.fromJson(const {"type": "fixed", "value": 0}).isNone, isTrue);
      expect(MoneyFee.fromJson(null).isNone, isTrue);
      expect(MoneyFee.fromJson(const {"type": "odd", "value": 3}).isNone, isTrue);
    });

    test('an account reads its currency and commission', () {
      final method = MoneyMethod.fromJson(const {
        "id": "m1",
        "code": "pago_movil",
        "currency": "ves",
        "fee": {"type": "fixed", "value": 5}
      });

      expect(method.currency, "VES");
      expect(method.fee.type, MoneyFeeType.fixed);
      expect(method.fee.value, 5);
    });

    test('a rail reads the one currency it moves', () {
      final rail = MoneyRail.fromJson(const {
        "code": "pago_movil",
        "name": "Pago movil",
        "currency": "ves"
      });

      expect(rail.currency, "VES");
    });
  });

  group('method requests', () {
    test('a creation sends the currency and only a commission that exists', () {
      final withFee = createMoneyMethodRequest(
        code: "zelle",
        currency: "usd",
        fee: const MoneyFee(type: MoneyFeeType.percent, value: 3)
      );

      expect(withFee["CURRENCY"], "USD");
      expect(withFee["FEE_TYPE"], "percent");
      expect(withFee["FEE"], 3);

      final without = createMoneyMethodRequest(code: "cash");

      expect(without.containsKey("CURRENCY"), isFalse);
      expect(without.containsKey("FEE_TYPE"), isFalse);
      expect(without.containsKey("FEE"), isFalse);
    });

    test('an edit takes a commission off with none and a null value', () {
      final request = updateMoneyMethodRequest(
        id: "m1",
        currency: "VES",
        fee: const MoneyFee()
      );

      expect(request["CURRENCY"], "VES");
      expect(request["FEE_TYPE"], "none");
      expect(request.containsKey("FEE"), isTrue);
      expect(request["FEE"], isNull);
    });

    test('an edit that was not given them does not touch them', () {
      final request = updateMoneyMethodRequest(id: "m1");

      expect(request.containsKey("CURRENCY"), isFalse);
      expect(request.containsKey("FEE_TYPE"), isFalse);
    });
  });
}
