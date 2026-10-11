import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyra_protocol/lyra_protocol.dart' show Grant, PermissionCatalog;

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/permissions/sources/permissions_source.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/services/stock/transfers/stock_transfer_model.dart';
import 'package:app/services/stock/transfers/stock_transfers_service.dart';
import 'package:app/screens/home/sections/inventory/transfers/_transfers.dart';

/// The transfers page draws what is on its way here and what was sent from here, and offers
/// each branch only its own step: the receiver receives, the sender sends, drops or calls back.
StockTransfer _transfer(String id, {required String from, required String to, required StockTransferStatus status}) =>
  StockTransfer(
    id: id,
    from: from,
    to: to,
    status: status,
    units: 3,
    lines: const [StockTransferLine(productId: "p1", sku: "SKU-1", quantity: 3)]
  );

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  setUp(() => BranchService().seed("b-1", [
    BusinessBranchModel.from({"id": "centro", "name": "Centro", "main": true})!,
    BusinessBranchModel.from({"id": "chacao", "name": "Chacao"})!
  ], active: "chacao"));
  tearDown(() => BranchService().clear());

  testWidgets("a shipment on its way here offers to receive it, with the right to receive", (tester) async {
    final service = StockTransfersService(source: _Source(), permissions: _Permissions())
      ..seed(
        [_transfer("t1", from: "centro", to: "chacao", status: StockTransferStatus.sent)],
        filter: StockTransferStatus.sent,
        grant: Grant(sections: PermissionCatalog.fromKeys(["inventory", "inventory.receive"]))
      );

    await _pump(tester, service);

    expect(find.text(S.current.inventory_transfers_from("Centro")), findsOneWidget);
    expect(find.text(S.current.inventory_transfers_receive), findsOneWidget);
    expect(find.text(S.current.inventory_transfers_call_back), findsNothing);
    // Nobody to send to without `inventory.transfer`.
    expect(find.text(S.current.inventory_transfers_new), findsNothing);
    expect(find.textContaining("SKU-1"), findsOneWidget);

    service.dispose();
  });

  testWidgets("a draft sent from here is the sender's to send or drop; nothing without the right", (tester) async {
    final drafts = [_transfer("t2", from: "chacao", to: "centro", status: StockTransferStatus.draft)];
    final service = StockTransfersService(source: _Source(), permissions: _Permissions())
      ..seed(drafts, side: StockTransferSide.outgoing, grant: Grant.everything());

    await _pump(tester, service);

    expect(find.text(S.current.inventory_transfers_to("Centro")), findsOneWidget);
    expect(find.text(S.current.inventory_transfers_send), findsOneWidget);
    expect(find.text(S.current.inventory_transfers_drop), findsOneWidget);
    expect(find.text(S.current.inventory_transfers_new), findsOneWidget);

    service.seed(drafts, side: StockTransferSide.outgoing, grant: Grant.none());
    await tester.pump();

    expect(find.text(S.current.inventory_transfers_send), findsNothing);

    service.dispose();
  });
}

Future<void> _pump(WidgetTester tester, StockTransfersService service) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Builder(builder: (context) {
      AppSize.instance(context);

      return Scaffold(body: StockTransfersSection(service: service));
    })
  ));
  await tester.pump();
}

class _Source implements StockSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Permissions implements PermissionsSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
