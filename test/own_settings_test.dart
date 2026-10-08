import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/account/account_security_service.dart';
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/business_employees_service.dart';
import 'package:app/services/client/client_service.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/toolkit/deployment.dart';
import 'package:app/screens/home/sections/employees/employee_detail/_employee_detail.dart';
import 'package:app/screens/home/sections/employees/own_settings/own_history.dart';
import 'package:app/screens/home/sections/employees/own_settings/own_security.dart';
import 'package:app/screens/home/sections/employees/own_settings/own_sessions.dart';
import 'package:app/screens/home/sections/employees/own_settings/own_notifications.dart';
import 'package:app/screens/home/sections/employees/own_settings/own_privacy.dart';
import 'package:app/screens/home/sections/employees/own_settings/own_sign_in_methods.dart';

/// The person's own account, on their own card's page: one row per subsection after the parts of
/// their job, each opening a page of its own. Security and the work
/// history are the cloud account's: on a master without the cloud they are drawn and say they
/// need the internet, and nothing is read. Rows with no backend yet are marked "coming soon",
/// never drawn as switches that do nothing.
///
/// The language and look subsection is left out: `AppController().theme` exists only once the
/// app's plugins started.
void main() {
  setUpAll(() => ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000)));
  tearDown(() => Deployment.use(DeploymentMode.cloud));

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(600, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Deployment.use(DeploymentMode.local);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<ClientService>(create: (_) => ClientService()),
          ChangeNotifierProvider<BusinessEmployeesService>(create: (_) => BusinessEmployeesService()),
          ChangeNotifierProvider<AccountSecurityService>(create: (_) => AccountSecurityService()),
          ChangeNotifierProvider<PermissionsService>.value(value: PermissionsService())
        ],
        child: Builder(builder: (context) {
          AppSize.instance(context);
          return Material(child: SizedBox(width: 480, height: 4000, child: child));
        })
      )
    ));
    await tester.pump();
  }

  testWidgets('the own card lists every subsection, the ones with nothing working yet tagged', (tester) async {
    // Unfiled: the account is all there is, and nothing is read for it.
    const me = BusinessEmployeeModel(me: true, username: "ana", name: "Ana", lastName: "Ruiz");
    final opened = <String>[];

    await pump(tester, EmployeeDetailPage(employee: me, onOpen: opened.add));

    expect(tester.takeException(), isNull);

    for (final title in ["Security", "Sign-in methods", "Devices and sessions", "Preferences", "Work history", "Notifications", "Privacy"]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }

    expect(find.text("Coming soon"), findsNWidgets(2));
    expect(find.text("Turn on two-step verification"), findsNothing);

    await tester.tap(find.text("Security"));
    expect(opened, ["/home/employees/me/security"]);
  });

  testWidgets('without the cloud the subsections draw and the account\'s rows wait for it', (tester) async {
    await pump(tester, const SingleChildScrollView(child: Column(children: [
      OwnSecurity(),
      OwnSignInMethods(),
      OwnSessions(),
      OwnNotifications(),
      OwnPrivacy(),
      OwnHistory()
    ])));

    expect(tester.takeException(), isNull);
    expect(find.text("Needs the internet: it lives in your online account."), findsNWidgets(3));
    expect(find.text("Coming soon"), findsWidgets);
    expect(find.text("Sign out"), findsOneWidget);
  });
}
