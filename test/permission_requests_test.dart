import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/permissions/permission_request.dart';
import 'package:app/services/permissions/permission_request_model.dart';
import 'package:app/services/permissions/permission_requests_service.dart';
import 'package:app/screens/home/sections/no_permission.dart';
import 'package:app/screens/modals/permissions/request_permission/_request_permission.dart';

/// **Asking for a missing permission** (`/permissions/requests/`): the body sends the area id
/// and the note only when there is one, the list reads the compressed table, and the locked
/// section offers to ask only when nothing is pending — the backend refuses a second request.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  group('request body', () {
    test('a blank note does not travel', () {
      expect(requestPermissionRequest(permission: "finance.view", reason: "  "), {"PERMISSION": "finance.view"});
      expect(requestPermissionRequest(permission: "finance.view"), {"PERMISSION": "finance.view"});
    });

    test('a note travels trimmed', () {
      expect(
        requestPermissionRequest(permission: "sales.view", reason: " Night shift "),
        {"PERMISSION": "sales.view", "REASON": "Night shift"}
      );
    });
  });

  test('the list reads the compressed table', () {
    final rows = PermissionRequestModel.listFromTable({
      "keys": ["id", "permission", "reason", "state", "created_at"],
      "values": [
        ["r-1", "finance.view", null, "pending", "2026-09-29T10:00:00Z"],
        ["r-2", "sales.view", "Cashier", "granted", "2026-09-28T10:00:00Z"],
        ["r-3", "", null, "pending", null]
      ]
    });

    expect(rows.map((row) => row.id), ["r-1", "r-2"]);
    expect(rows.first.isPending, isTrue);
    expect(rows.first.reason, isNull);
    expect(rows.last.state, PermissionRequestState.granted);
  });

  group('the locked section', () {
    testWidgets('says who lacks what and offers to ask', (tester) async {
      final requests = PermissionRequestsService()..seed(const []);

      await _pump(tester, requests);

      expect(find.text("You don't have access to Finance"), findsOneWidget);
      expect(find.textContaining("Your role in One"), findsOneWidget);
      expect(find.text("Request access"), findsOneWidget);
    });

    testWidgets('does not offer to ask again while a request is pending', (tester) async {
      final requests = PermissionRequestsService()..seed(const [
        PermissionRequestModel(id: "r-1", permission: "finance.view", state: PermissionRequestState.pending)
      ]);

      await _pump(tester, requests);

      expect(find.textContaining("You already requested access"), findsOneWidget);
      expect(find.text("Request access"), findsNothing);
    });

    testWidgets('a granted request for it is not a pending one', (tester) async {
      final requests = PermissionRequestsService()..seed(const [
        PermissionRequestModel(id: "r-1", permission: "finance.view", state: PermissionRequestState.granted),
        PermissionRequestModel(id: "r-2", permission: "sales.view", state: PermissionRequestState.pending)
      ]);

      await _pump(tester, requests);

      expect(find.text("Request access"), findsOneWidget);
    });

    testWidgets('the request names what is asked and takes an optional note', (tester) async {
      // Drawn on its own: `showModal` needs the device info `starter()` sets up.
      await _pump(tester, PermissionRequestsService()..seed(const []), child: RequestPermissionModal(
        requests: PermissionRequestsService(),
        permission: "finance.view",
        section: "Finance",
        business: "One"
      ));

      expect(find.textContaining("You're asking for access to Finance in One"), findsOneWidget);
      expect(find.text("Note (optional)"), findsOneWidget);
      expect(find.text("Send request"), findsOneWidget);
    });
  });
}

Future<void> _pump(WidgetTester tester, PermissionRequestsService requests, {Widget? child}) async {
  // A desktop window: `AppSize` scales with it, and the test font is wider than the app's.
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final business = BusinessService()..seed({
    "keys": ["id", "name"],
    "values": [["b-1", "One"]]
  });

  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: ChangeNotifierProvider<BusinessService>.value(
      value: business,
      child: Builder(builder: (context) {
        AppSize.instance(context);

        // The test font draws every glyph a full em wide: at the app's scale the button's
        // label would not fit its fixed width, which the app's font does.
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(0.6)),
          child: Scaffold(body: SizedBox(
            width: 1200,
            height: 800,
            child: child ?? NoPermissionSection(
              permission: "finance.view",
              title: "Finance",
              requests: requests
            )
          ))
        );
      })
    )
  ));

  await tester.pump();
}
