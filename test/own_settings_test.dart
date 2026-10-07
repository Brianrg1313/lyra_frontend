import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:core/form.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/client/client_service.dart';
import 'package:app/toolkit/deployment.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/_own_settings.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/own_history.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/own_security.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/own_sessions.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/own_notifications.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/own_privacy.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/own_setting.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/own_sign_in_methods.dart';

/// The person's own settings (their card's settings action): an index of subsections, each
/// opening its own panel, and a search through every row of them. Security and the work
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
      home: ChangeNotifierProvider<ClientService>(
        create: (_) => ClientService(),
        child: Builder(builder: (context) {
          AppSize.instance(context);
          return Material(child: SizedBox(width: 480, child: child));
        })
      )
    ));
    await tester.pump();
  }

  testWidgets('the index lists every subsection, the ones with nothing working yet tagged', (tester) async {
    await pump(tester, const OwnSettings());

    expect(tester.takeException(), isNull);

    for (final title in ["Security", "Sign-in methods", "Devices and sessions", "Preferences", "Work history", "Notifications", "Privacy"]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }

    expect(find.text("Coming soon"), findsNWidgets(2));
    expect(find.text("Turn on two-step verification"), findsNothing);
  });

  testWidgets('the search finds a row by its words, in any order, with the subsection holding it', (tester) async {
    await pump(tester, const OwnSettings());

    await tester.enterText(find.descendant(of: find.byType(SearchInput), matching: find.byType(EditableText)), "codes recovery");
    await tester.pump();

    expect(find.text("Recovery codes"), findsOneWidget);
    expect(find.text("Security"), findsOneWidget);
    expect(find.text("Preferences"), findsNothing);

    await tester.enterText(find.descendant(of: find.byType(SearchInput), matching: find.byType(EditableText)), "appearance");
    await tester.pump();

    expect(find.text("Appearance"), findsOneWidget);
    expect(find.text("Preferences"), findsOneWidget);
    expect(find.text("Security"), findsNothing);

    await tester.enterText(find.descendant(of: find.byType(SearchInput), matching: find.byType(EditableText)), "zzz");
    await tester.pump();

    expect(find.textContaining("Nothing in your settings matches"), findsOneWidget);
  });

  test('folding drops case, accents and hyphens', () {
    expect(OwnSetting.fold("Verificación en Dos-Pasos"), "verificacion en dos pasos");
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
