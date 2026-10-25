import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/home/sections/sales/sales_tab.dart';
import 'package:app/services/sales/sale_fulfillment_request.dart';
import 'package:app/services/sales/sale_model.dart';
import 'package:app/services/sales/sale_progress_model.dart';
import 'package:app/services/sales/sale_stage_model.dart';
import 'package:app/services/sales/sales_service.dart';
import 'package:app/services/connection/connection_service.dart' show SocketStatus;
import 'package:app/toolkit/backend/sockets.dart';
import 'package:app/toolkit/settings/routes.dart';

/// What the sales board runs on, pinned where it is invisible from the screen:
/// the two tabs are URLs, a row is a **measurement** that keeps its nulls, the
/// handover write sends the difference and never the whole handover, and a
/// `sale/progress` notice moves a row, drops it or is ignored — which is the
/// difference between a live list and one that quietly shows the wrong shop.
void main() {
  setUpAll(() {
    // `defineRoutes` builds the root page, which needs a live binding.
    TestWidgetsFlutterBinding.ensureInitialized();
    Navis.defineRoutes(routes);
  });

  group('routing', () {
    test('each sales tab is its own url', () {
      // Without a route per tab, both would share the section's URL and the
      // shell —which learns of a screen change from `currentKey`— would keep
      // drawing the list that was already open.
      for (final tab in SalesTab.values) {
        final match = Navis().match(tab.path);

        expect(match, isNotNull, reason: "${tab.path} does not resolve");
        expect(match!.route.key, tab.routeKey);
      }
    });

    test('a sales tab carries no id', () {
      // Every sales endpoint answers for the active company (the `business_id`
      // header), so what is being looked at is never in the URL.
      for (final tab in SalesTab.values) {
        expect(Navis().match(tab.path)?.args?["id"], isNull);
      }
    });

    test('the tabs do not stack on top of the section', () {
      Navis.navigate(HomeSection.sales.path);
      final length = Navis().history.length;

      for (final tab in SalesTab.values) {
        Navis.navigate(tab.path);

        expect(Navis().history.length, length, reason: "${tab.key} stacked");
        expect(Navis.currentKey.value, tab.routeKey);
      }
    });

    test('a tab keeps the sales section marked', () {
      for (final tab in SalesTab.values) {
        final marked = HomeSection.values
          .where((section) => section.isCurrent(tab.routeKey))
          .toList();

        expect(marked, [HomeSection.sales], reason: "${tab.key} does not mark");
      }
    });

    test('the tab key is the section the backend takes', () {
      // The URL segment and the `SECTION` filter are the same word on purpose:
      // translating one into the other is how the two drift apart.
      expect(SalesTab.process.key, SaleSection.process.value);
      expect(SalesTab.done.key, SaleSection.done.value);
    });

    test('the sales section needs a business', () {
      expect(HomeSection.sales.needsBusiness, isTrue);
    });

    test('the sales option leads the operations group', () {
      // The board of what is going on first, then the conversations it starts
      // from, the goods on their way and the services.
      expect(
        HomeSection.operations,
        [
          HomeSection.sales,
          HomeSection.messages,
          HomeSection.deliveries,
          HomeSection.services
        ]
      );
    });
  });

  group('a row of the list', () {
    test('a page is read out of the compressed table', () {
      // Every listing of this API travels as `{keys, values}`, and the columns
      // are read by name so the backend can reorder or add one.
      final page = SalesPage.fromResponse({
        "section": "process",
        "page": 1,
        "size": 50,
        "total": 3,
        "sales": {
          "keys": ["id", "source", "ticket", "stage", "label", "total"],
          "values": [
            ["s1", "ticket", "K7M4-2QX9", "shipping", "Esperando el envio", 42.5]
          ]
        }
      });

      expect(page.isLoaded, isTrue);
      expect(page.section, SaleSection.process);
      expect(page.total, 3);
      expect(page.sales.single.id, "s1");
      expect(page.sales.single.ticket, "K7M4-2QX9");
      expect(page.sales.single.total, 42.5);
    });

    test('what a source does not have stays null and never zero', () {
      // A conversation has not been priced, and a cash ticket owes nothing.
      // Zeroing either would claim the sale is worth nothing and that there is
      // a debt of nothing — two figures somebody would act on.
      final deal = SaleModel.fromJson({
        "id": "c1",
        "source": "chat",
        "total": null,
        "collected": null,
        "outstanding": null,
        "units": 3
      });

      expect(deal.isDeal, isTrue);
      expect(deal.total, isNull);
      expect(deal.outstanding, isNull);
      expect(deal.units, 3);
    });

    test('a row of the list carries no section', () {
      // The whole page belongs to the section that was asked for, so the field
      // does not travel per row — and a null one must not be read as "done".
      final row = SaleModel.fromJson({"id": "s1", "source": "ticket"});

      expect(row.section, isNull);
    });

    test('only a charged sale the customer does not have can be handed over', () {
      SaleModel of(String source, String state) => SaleModel.fromJson({
        "id": "s1",
        "source": source,
        "state": state
      });

      // An open invoice has not been paid for (the backend answers 409) and a
      // conversation has no document at all.
      expect(of("invoice", "").canFulfil, isFalse);
      expect(of("chat", "").canFulfil, isFalse);
      // Delivered already: a ticket that is still owed money is a debt, not a
      // delivery.
      expect(of("ticket", "done").canFulfil, isFalse);
      expect(of("ticket", "pending").canFulfil, isTrue);
      expect(of("ticket", "dispatched").canFulfil, isTrue);
    });
  });

  group('the stages catalog', () {
    test('the stages come compressed and the handover nested', () {
      // They ride in one answer because both are read once when the screen
      // opens and neither changes while somebody works.
      final catalog = SaleStagesCatalog.fromResponse({
        "sections": [
          {"section": "process", "name": "Ventas en proceso"}
        ],
        "stages": {
          "keys": ["stage", "name", "section", "level", "attention"],
          "values": [
            ["shipping", "Esperando el envio", "process", "warning", true],
            ["pickup", "Esperando el retiro", "process", "info", false],
            ["completed", "Venta completada", "done", "success", false]
          ]
        },
        "handover": [
          {
            "mode": "delivery",
            "name": "Envio a domicilio",
            "states": [
              {"state": "pending", "name": "Sin entregar"},
              {"state": "dispatched", "name": "Despachado"},
              {"state": "done", "name": "Entregado"}
            ]
          }
        ]
      });

      expect(catalog.isLoaded, isTrue);
      expect(catalog.stages.length, 3);
      expect(catalog.stages.first.attention, isTrue);
      expect(catalog.stages.first.level, SaleLevel.warning);
      expect(catalog.stages.last.section, SaleSection.done);

      final delivery = catalog.handover.single;

      expect(delivery.mode, "delivery");
      expect(delivery.states.length, 3);
      expect(delivery.find("dispatched")?.name, "Despachado");
      // The narrowing is the backend's: a pickup has no middle.
      expect(delivery.find("nowhere"), isNull);
    });
  });

  group('the handover write', () {
    test('it names the sale and only what was said', () {
      // Neither word is defaulted, here or on the backend: a handover filed as
      // a delivery because nothing was picked is a driver sent to a customer
      // who was coming to collect.
      expect(fulfilSaleRequest(id: "s1"), {"ID": "s1"});
      expect(
        fulfilSaleRequest(id: "s1", mode: "delivery"),
        {"ID": "s1", "MODE": "delivery"}
      );
      expect(
        fulfilSaleRequest(id: "s1", state: "dispatched"),
        {"ID": "s1", "STATE": "dispatched"}
      );
    });

    test('a note nobody wrote does not travel', () {
      // An empty one would overwrite whatever note the sale already carries.
      expect(
        fulfilSaleRequest(id: "s1", state: "done", note: "   "),
        {"ID": "s1", "STATE": "done"}
      );
      expect(
        fulfilSaleRequest(id: "s1", state: "done", note: " TRK-99 "),
        {"ID": "s1", "STATE": "done", "NOTE": "TRK-99"}
      );
    });
  });

  group('what a notice does to the board', () {
    late SalesService service;

    SaleModel row(String id) => SaleModel.fromJson({
      "id": id,
      "source": "ticket",
      "stage": "shipping",
      "label": "Esperando el envio",
      "level": "warning",
      "attention": true,
      "total": 10
    });

    Map<String, dynamic> notice({
      required String id,
      String? stage = "transit",
      String? label = "En camino",
      String? section = "process",
      String level = "info",
      bool attention = false
    }) => {
      "id": id,
      "source": "ticket",
      "ticket": null,
      "chat": null,
      "stage": stage,
      "label": label,
      "section": section,
      "level": level,
      "attention": attention,
      "since": null
    };

    setUp(() => service = SalesService());
    tearDown(() => service.dispose());

    test('a row it holds is relabelled and moved to the top', () {
      // The notice carries the measured stage, so rereading would ask for a
      // number it was just handed — and last movement first is the order the
      // backend answers in, which is where somebody watching is looking.
      service.seed([row("a"), row("b"), row("c")]);
      service.receive(notice(id: "c"));

      expect(service.sales.map((sale) => sale.id), ["c", "a", "b"]);
      expect(service.sales.first.stage, "transit");
      expect(service.sales.first.label, "En camino");
      expect(service.sales.first.level, SaleLevel.info);
      expect(service.sales.first.attention, isFalse);
      // Nothing the notice does not say is touched: it says where a sale
      // stands, not what it is worth.
      expect(service.sales.first.total, 10);
    });

    test('a row that crossed to the other list leaves this one', () {
      service.seed([row("a"), row("b")], total: 2);
      service.receive(notice(id: "a", stage: "completed", section: "done"));

      expect(service.sales.map((sale) => sale.id), ["b"]);
      expect(service.total, 1);
    });

    test('a sale that left both lists is dropped', () {
      // A null section is the row leaving everything — a cancelled invoice, a
      // checkout that failed and put its units back. Every field always
      // travels, so this is a value and not a missing key.
      service.seed([row("a")], total: 1);
      service.receive(notice(id: "a", stage: null, label: null, section: null));

      expect(service.sales, isEmpty);
      expect(service.status, SalesStatus.empty);
    });

    test('a stage the filter does not show takes the row out', () {
      // The filter is the service's and travels to the backend, so a row that
      // stops matching it stops belonging on the page that answered it.
      service.seed([row("a"), row("b")], stage: "shipping", total: 2);
      service.receive(notice(id: "a"));

      expect(service.sales.map((sale) => sale.id), ["b"]);
    });

    test('a movement in the other list is ignored', () {
      // Nothing this board could show. Checked before anything is scheduled,
      // which is what keeps a busy counter from rereading `process` every time
      // a sale lands in `done`.
      service.seed([row("a")], total: 1);
      service.receive(notice(id: "zzz", stage: "completed", section: "done"));

      expect(service.sales.map((sale) => sale.id), ["a"]);
      expect(service.pending, 0);
    });

    test('a sale it does not hold is announced past the first page', () {
      // On the first page the board catches up by itself; past it, rebuilding
      // from the top would take away the row somebody was about to act on, so
      // they are told and they decide.
      service.seed([row("a")], total: 60, page: 2);
      service.receive(notice(id: "new"));

      expect(service.pending, 1);
      expect(service.sales.map((sale) => sale.id), ["a"]);
    });

    test('a connection that comes back is a reread and not a redraw', () {
      // What a notice cannot cover: the drop itself. Events are fire and
      // forget, so whatever moved while this app was not in the room was
      // emitted to nobody and is not queued anywhere — a phone that slept, a
      // wifi that changed, a server that restarted. Past the first page it is
      // announced, exactly as a movement on a sale the board does not hold is:
      // rebuilding from the top would take away the row somebody is reading.
      service.seed([row("a")], total: 60, page: 2);

      // The first connection of the run has missed nothing: every screen reads
      // when it opens, and a reread here would be one per section mounted.
      sockets.status.value = SocketStatus.connected;

      expect(service.pending, 0);

      sockets.status.value = SocketStatus.disconnected;
      sockets.status.value = SocketStatus.connected;

      expect(service.pending, 1);
    });

    test('a notice with no sale on it is discarded', () {
      service.seed([row("a")], total: 1);
      service.receive({"stage": "transit"});
      service.receive("not a frame");

      expect(service.sales.map((sale) => sale.id), ["a"]);
      expect(service.pending, 0);
    });

    test('a notice is shaped like the row it updates', () {
      // Both ends spell it `label`, because a notice is merged into a row: a
      // key the list does not use relabels nothing, and the state stays saying
      // what the sale used to be. It carries the row's own columns too, so a
      // sale the board does not hold yet is not a line with every cell blank.
      final read = SaleProgressModel.fromEvent(
        notice(id: "a", stage: "pickup", label: "Esperando el retiro")
      );

      expect(read.label, "Esperando el retiro");
      expect(read.isGone, isFalse);
      expect(read.isEmpty, isFalse);
    });
  });
}
