import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/home/home_service.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/toolkit/deployment.dart';
import 'package:app/screens/home/desktop/side_bar/option.dart';
import 'package:app/screens/home/desktop/side_bar/options.dart';
import 'package:app/screens/home/sections/_sections.dart';

/// **A section the person is not granted is locked in the side bar**, per company: its
/// `<section>.view` in `/init`'s `permissions`. With no company at all only
/// `needsBusiness` locks, never a missing grant, or the first company could not be created.
/// A section the deployment mode lacks is not locked but left out: there is nothing to ask.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });
  tearDown(() {
    PermissionsService().clear();
    Deployment.use(DeploymentMode.cloud);
  });

  testWidgets('sections without their view are locked in the active company', (tester) async {
    final business = BusinessService()..seed(_companies);
    PermissionsService().seed({
      "b-1": {"business": {"view": true}, "sales": {"view": true}},
      "b-2": {"business": {"view": true}, "finance": {"view": true}}
    });

    await _pump(tester, business);

    expect(_locked(tester, HomeSection.dashboard), isFalse);
    expect(_locked(tester, HomeSection.business), isFalse);
    expect(_locked(tester, HomeSection.sales), isFalse);
    expect(_locked(tester, HomeSection.finance), isTrue);
    expect(_locked(tester, HomeSection.messages), isTrue);
    // Locked by a permission it still opens: access is asked for on the section.
    expect(_option(tester, HomeSection.finance).opensLocked, isTrue);

    // Grants are per company: a switch relocks the list.
    business.selectBusiness("b-2");
    await tester.pump();

    expect(_locked(tester, HomeSection.sales), isTrue);
    expect(_locked(tester, HomeSection.finance), isFalse);
  });

  testWidgets('with no company only needsBusiness locks', (tester) async {
    final business = BusinessService()..seed(null);
    PermissionsService().seed({});

    await _pump(tester, business);

    expect(_locked(tester, HomeSection.business), isFalse);
    expect(_locked(tester, HomeSection.dashboard), isFalse);
    expect(_locked(tester, HomeSection.sales), isTrue);
    expect(_option(tester, HomeSection.sales).opensLocked, isFalse);
  });

  testWidgets('a section the mode lacks is left out, not locked', (tester) async {
    final business = BusinessService()..seed(_companies);
    PermissionsService().seed({"b-1": {"business": {"view": true}}});
    Deployment.use(DeploymentMode.local, role: DeploymentRole.master);

    await _pump(tester, business);

    expect(find.byKey(ValueKey(HomeSection.messages.key)), findsNothing);
    expect(find.byKey(ValueKey(HomeSection.channels.key)), findsNothing);
    // Local, but its master side arrives in a later release of plan phase 4.
    expect(find.byKey(ValueKey(HomeSection.finance.key)), findsNothing);
    // Built on a master, and this person may not open it.
    expect(_locked(tester, HomeSection.sales), isTrue);
    expect(_locked(tester, HomeSection.business), isFalse);
    expect(_locked(tester, HomeSection.server), isTrue);
  });
}

final _companies = {
  "keys": ["id", "name"],
  "values": [["b-1", "One"], ["b-2", "Two"]]
};

Option _option(WidgetTester tester, HomeSection section) =>
  tester.widget<Option>(find.byKey(ValueKey(section.key)));

bool _locked(WidgetTester tester, HomeSection section) => _option(tester, section).isLocked;

Future<void> _pump(WidgetTester tester, BusinessService business) async {
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
        ChangeNotifierProvider<BusinessService>.value(value: business),
        ChangeNotifierProvider<PermissionsService>.value(value: PermissionsService()),
        ChangeNotifierProvider<CapabilityService>.value(value: CapabilityService()),
        ChangeNotifierProvider<HomeService>.value(value: HomeService())
      ],
      child: Builder(builder: (context) {
        AppSize.instance(context);

        return Scaffold(body: SingleChildScrollView(child: SizedBox(
          width: 260,
          child: Column(children: options(context, HomeSection.dashboard, true))
        )));
      })
    )
  ));

  await tester.pump();
}
