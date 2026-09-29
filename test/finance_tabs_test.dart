import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/home/sections/finance/finance_tab.dart';
import 'package:app/services/money/money_method_request.dart';
import 'package:app/services/money/money_payment_request.dart';
import 'package:app/toolkit/settings/routes.dart';

void main() {
  setUpAll(() {
    // `defineRoutes` builds the root page, which needs a live binding.
    TestWidgetsFlutterBinding.ensureInitialized();
    Navis.defineRoutes(routes);
  });

  group('routing', () {
    test('each money tab is its own url', () {
      // It is what makes the browser bar link the one of what is being looked
      // at: without a route per tab, the four would share the section's URL.
      for (final tab in FinanceTab.values) {
        final match = Navis().match(tab.path);

        expect(match, isNotNull, reason: "${tab.path} does not resolve");
        expect(match!.route.key, tab.routeKey);
      }
    });

    test('a money tab carries no id', () {
      // The difference from a business's tabs: every money endpoint answers for
      // the active company, so what is being looked at is never in the URL.
      for (final tab in FinanceTab.values) {
        expect(Navis().match(tab.path)?.args?["id"], isNull);
      }
    });

    test('the tabs do not stack on top of the section', () {
      // They all share the home shell, so switching tabs updates the page
      // instead of pushing a new one; what does change is the active screen,
      // which is where the shell reads the open tab from.
      Navis.navigate(HomeSection.finance.path);
      final length = Navis().history.length;

      for (final tab in FinanceTab.values) {
        Navis.navigate(tab.path);

        expect(Navis().history.length, length, reason: "${tab.key} stacked");
        expect(Navis.currentKey.value, tab.routeKey);
      }
    });

    test('a tab keeps the money section marked', () {
      for (final tab in FinanceTab.values) {
        final marked = HomeSection.values
          .where((section) => section.isCurrent(tab.routeKey))
          .toList();

        expect(marked, [HomeSection.finance], reason: "${tab.key} does not mark");
      }
    });

    test('the money option opens the reports group', () {
      // The money is what gets looked back at, so it leads the reports; the
      // screens used all day moved up to the untitled top group.
      expect(HomeSection.reports.first, HomeSection.finance);
      expect(HomeSection.home.contains(HomeSection.finance), isFalse);
    });

    test('the money section needs a business', () {
      // Everything it shows hangs off one, so the side bar locks it and the
      // shell refuses to mount it without an active company.
      expect(HomeSection.finance.needsBusiness, isTrue);
    });
  });

  group('payment request', () {
    test('a payment never says which way the money went', () {
      // The concept decides the direction, so a body that could name both would
      // be able to contradict itself.
      final request = recordPaymentRequest(concept: "supplier", amount: 250.5);

      expect(request["CONCEPT"], "supplier");
      expect(request["AMOUNT"], 250.5);
      expect(request.containsKey("DIRECTION"), isFalse);
    });

    test('what was not typed does not travel', () {
      // A reference nobody wrote is a payment that carries none: sending `""`
      // would leave the history saying the bank printed an empty number.
      final request = recordPaymentRequest(
        concept: "supplier",
        amount: 10,
        reference: "   ",
        note: "",
        ticket: ""
      );

      expect(request.containsKey("REFERENCE"), isFalse);
      expect(request.containsKey("NOTE"), isFalse);
      expect(request.containsKey("TICKET"), isFalse);
      expect(request.containsKey("COUNTERPART"), isFalse);
    });

    test('the counterpart travels as an object with what it has', () {
      final request = recordPaymentRequest(
        concept: "settlement",
        amount: 10,
        counterpartName: " Ana ",
        counterpartContact: ""
      );

      expect(request["COUNTERPART"], {"NAME": "Ana"});
    });

    test('the date travels in utc', () {
      // Every date on the wire is UTC: the backend stamps and filters by when
      // the money moved, not by the clock of whoever typed it in.
      final date = DateTime.utc(2026, 3, 4, 15, 30);
      final request = recordPaymentRequest(
        concept: "supplier",
        amount: 10,
        date: date
      );

      expect(request["DATE"], date.toIso8601String());
    });

    test('a void carries its reason only when there is one', () {
      expect(voidPaymentRequest(id: "p1"), {"ID": "p1"});
      expect(
        voidPaymentRequest(id: "p1", reason: " wrong amount "),
        {"ID": "p1", "REASON": "wrong amount"}
      );
    });
  });

  group('payment method request', () {
    test('creation drops the blanks and keeps the rail', () {
      // On a creation a key with an empty value is a field that was never
      // configured, and leaving it would make it look like it was.
      final request = createMoneyMethodRequest(
        code: "pago_movil",
        label: "Banesco",
        fields: {"holder": "", "account": "  0414 1234567  "}
      );

      expect(request["CODE"], "pago_movil");
      expect(request["LABEL"], "Banesco");
      expect(request["ACCOUNT"], "0414 1234567");
      expect(request.containsKey("HOLDER"), isFalse);
    });

    test('an edit clears with null and never names the rail', () {
      // The backend writes only the keys it receives, so a cleared field has to
      // travel as `null`; and the rail cannot change, because the payments
      // already recorded would silently say they came in through another one.
      final request = updateMoneyMethodRequest(
        id: "m1",
        label: "Zelle",
        fields: {"holder": "   "}
      );

      expect(request["ID"], "m1");
      expect(request["LABEL"], "Zelle");
      expect(request.containsKey("HOLDER"), isTrue);
      expect(request["HOLDER"], isNull);
      expect(request.containsKey("CODE"), isFalse);
    });

    test('an edit only carries what it was given', () {
      // Only the fields the rail asked for travel: a column this method does
      // not have is left alone rather than blanked by a form that never drew
      // it.
      final request = updateMoneyMethodRequest(id: "m1", fields: {"account": "123"});

      expect(request.keys, ["ID", "ACCOUNT"]);
    });

    test('turning one off names it and nothing else', () {
      expect(removeMoneyMethodRequest("m1"), {"ID": "m1"});
    });
  });
}
