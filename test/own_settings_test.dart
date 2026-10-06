import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/client/client_service.dart';
import 'package:app/toolkit/deployment.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/own_history.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/own_security.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/own_sessions.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/own_soon.dart';

/// The person's own settings (their card's settings action). Security and the work history are
/// the cloud account's: on a master without the cloud they are drawn and say they need the
/// internet, and nothing is read. Rows with no backend yet are marked "coming soon", never
/// drawn as switches that do nothing.
///
/// The language and look block is left out: `AppController().theme` exists only once the app's
/// plugins started.
void main() {
  setUpAll(() => ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000)));
  tearDown(() => Deployment.use(DeploymentMode.cloud));

  testWidgets('without the cloud every block is drawn and the account\'s rows wait for it', (tester) async {
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
      home: ChangeNotifierProvider<ClientService>(
        create: (_) => ClientService(),
        child: Builder(builder: (context) {
          AppSize.instance(context);
          return const Material(child: SingleChildScrollView(child: SizedBox(width: 480, child: Column(children: [
            OwnSecurity(),
            OwnSignInMethods(),
            OwnSessions(),
            OwnNotifications(),
            OwnPrivacy(),
            OwnHistory()
          ]))));
        })
      )
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);

    for (final title in ["Security", "Sign-in methods", "Devices and sessions", "Notifications", "Privacy", "Work history"]) {
      expect(find.text(title), findsWidgets, reason: title);
    }

    expect(find.text("Needs the internet: it lives in your online account."), findsNWidgets(3));
    expect(find.text("Coming soon"), findsWidgets);
    expect(find.text("Sign out"), findsOneWidget);
  });
}
