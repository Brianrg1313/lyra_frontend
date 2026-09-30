import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyra_protocol/lyra_protocol.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/screens/home/sections/business/settings/profile_danger.dart';
import 'package:app/screens/home/sections/business/settings/profile_details.dart';
import 'package:app/screens/home/sections/business/settings/profile_emails.dart';
import 'package:app/screens/home/sections/business/settings/profile_logo.dart';
import 'package:app/services/catalog/country_catalog_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';

import 'package:app/services/business/business_language.dart';
import 'package:app/services/business/business_model.dart';
import 'package:app/services/business/business_profile_model.dart';
import 'package:app/services/business/sources/business_lan_source.dart';
import 'package:app/services/client/client_model.dart';
import 'package:app/services/client/client_service.dart';
import 'package:app/services/client/sources/session_lan_source.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/toolkit/deployment.dart';

/// The business release of plan phase 4 on the app's side: what the master answers
/// (`docs/offline/specs/business.md`, `session.md` session.bootstrap, as `lyra_node` sends it)
/// reaches the same models the cloud's answers do, and the screens' writes reach the master in
/// its keys. The engine's side is `lyra_node/test/business_test.dart`.
void main() {
  late _Master master;

  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });
  setUp(() => master = _Master());
  tearDown(() {
    Deployment.use(DeploymentMode.cloud);
    PermissionsService().clear();
  });

  group('session.bootstrap', () {
    test('lands in the /init shape each seed reads', () async {
      master.answers[Ops.sessionBootstrap.name] = _bootstrap;

      final init = await SessionLanSource(master).bootstrap();
      final client = ClientModel.fromJson(init);
      final businesses = BusinessModel.fromTable(init["businesses"]);

      expect(client.username, "ada.owner");
      expect(client.lastName, "Lovelace");
      expect(businesses.single.name, "Lovelace Café");
      expect(businesses.single.currency, "USD");
      expect(businesses.single.caption, "");
      expect(init["countries"], Catalogs.countryRows);
      expect(init["tasks"], isEmpty);
    });

    test('a master\'s listed grants answer like the cloud\'s tree (P-1)', () {
      Deployment.use(DeploymentMode.local, role: DeploymentRole.client);
      final permissions = PermissionsService()..seed({"c1": ["business.view", "business.settings.*"]});

      expect(permissions.canOpen("business", business: "c1"), isTrue);
      expect(permissions.can("business.settings.edit", business: "c1"), isTrue);
      expect(permissions.granted("business.settings", business: "c1"), isNull);
      expect(permissions.granted("business", business: "c1"), {"view"});
      expect(permissions.can("local_server.devices", business: "c1"), isFalse);

      permissions.seed({"c1": ["*"]});
      expect(permissions.can("local_server.devices", business: "c1"), isTrue);
    });

    test('a master\'s sign in is its LAN landing', () async {
      Deployment.use(DeploymentMode.local, role: DeploymentRole.client);
      master.ready = false;

      expect(await ClientService(source: SessionLanSource(master)).resolve(), "/lan");
    });
  });

  group('business.company', () {
    test('the profile reaches the model in its keys', () async {
      master.answers[Ops.businessProfile.name] = _profile;

      final profile = await BusinessLanSource(master).profile();

      expect(profile.name, "Lovelace Café");
      expect(profile.legalName, "Lovelace C.A.");
      expect(profile.activity, BusinessActivity.food);
      expect(profile.taxId, "J-123");
      expect(profile.currency, "USD");
      expect(profile.incorporationDate, DateTime(2020, 2, 29));
      expect(profile.owner, isTrue);
      expect(profile.emails, isEmpty);
    });

    test('a screen\'s key is written as the master\'s field', () async {
      await BusinessLanSource(master).editProfile("LEGAL_NAME", "Lovelace C.A.");
      await BusinessLanSource(master).editProfile("DESCRIPTION", "");

      expect(master.calls.map((call) => call.$1), [Ops.businessEdit.name, Ops.businessEdit.name]);
      expect(master.calls.map((call) => call.$2), [{"legalName": "Lovelace C.A."}, {"caption": ""}]);
      expect(() => BusinessLanSource(master).editProfile("EMAIL", "x"), throwsUnsupportedError);
    });

    test('every screen key is one the master takes', () {
      expect(BusinessFields.editable, containsAll(BusinessLanSource.profileKeys.values));
      expect(BusinessFields.site, containsAll(BusinessLanSource.siteKeys.values));
    });

    test('the app\'s sectors and languages are the ones the master checks', () {
      expect({for (final activity in BusinessActivity.catalog) activity.value}, Catalogs.activities);
      expect({for (final language in BusinessLanguage.values) language.tag}, Catalogs.languages);
    });
  });

  testWidgets('on a master the profile offers no e-mails, no delete and no logo change', (tester) async {
    Deployment.use(DeploymentMode.local, role: DeploymentRole.master);
    CountryCatalogService().seed(Catalogs.countryRows);
    CurrencyCatalogService().seed(Catalogs.currencyRows);
    addTearDown(() {
      CountryCatalogService().clear();
      CurrencyCatalogService().clear();
    });
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: CountryCatalogService()),
        ChangeNotifierProvider.value(value: CurrencyCatalogService())
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(builder: (context) {
          AppSize.instance(context);

          return Material(child: SingleChildScrollView(
            child: BusinessProfileDetails(profile: BusinessProfileModel.fromJson(BusinessLanSource.profileJson(_profile)))
          ));
        })
      )
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("Lovelace C.A."), findsOneWidget);
    expect(find.byType(ProfileEmailAdd), findsNothing);
    expect(find.byType(BusinessProfileDanger), findsNothing);
    expect(find.descendant(of: find.byType(BusinessProfileLogo), matching: find.byIcon(CI.pen)), findsNothing);
  });

  group('business.site', () {
    test('the site is the business location, with a map link from its point', () async {
      master.answers[Ops.businessSiteGet.name] = {
        "id": "s1", "main": true, "name": "Lovelace Café", "address": "Av. Principal", "city": "Caracas",
        "postalCode": "1010", "country": "VE", "latitude": 10.488063, "longitude": -66.879194,
      };

      final location = await BusinessLanSource(master).location();

      expect(location.address, "Av. Principal");
      expect(location.postalCode, "1010");
      expect(location.point, "10.488063, -66.879194");
      expect(location.maps, contains("10.488063,-66.879194"));
    });

    test('only the changed keys travel, in the master\'s names; nothing changed is no call', () async {
      await BusinessLanSource(master).editLocation({"POSTAL_CODE": "1060", "LATITUDE": "10.5", "LONGITUDE": "-66.9"});
      await BusinessLanSource(master).editLocation({});

      expect(master.calls.single.$1, Ops.businessSiteEdit.name);
      expect(master.calls.single.$2, {"postalCode": "1060", "latitude": "10.5", "longitude": "-66.9"});
    });
  });
}

const _bootstrap = {
  "client": {"id": "a1", "name": "Ada", "lastName": "Lovelace", "username": "ada.owner", "email": null},
  "businesses": [
    {"id": "c1", "name": "Lovelace Café", "caption": null, "logo": null, "activity": null, "profile": null, "currency": "USD"}
  ],
  "permissions": {"c1": ["*"]},
  "tasks": [],
  "catalogs": {"version": Catalogs.version, "countries": Catalogs.countryRows, "currencies": Catalogs.currencyRows},
  "deployment": {"mode": "local", "instanceId": "i1", "engine": "0.3.0", "timezone": "America/Caracas"},
};

const _profile = {
  "id": "c1", "name": "Lovelace Café", "legalName": "Lovelace C.A.", "nickname": null, "caption": null,
  "logo": null, "activity": "FOOD", "taxId": "J-123", "country": "VE", "language": "es", "currency": "USD",
  "phone": null, "website": null, "incorporationDate": "2020-02-29", "timezone": null, "verification": "untrusted",
  "emails": [], "created": "2026-09-30T12:00:00.000Z", "owner": true,
};

/// The master as a LAN source sees it: [LanService.call] answering what `lyra_node` would.
class _Master extends LanService {
  final Map<String, Object?> answers = {};
  final List<(String, Map<String, Object?>)> calls = [];
  bool ready = true;

  @override
  LanStatus get status => ready ? LanStatus.ready : LanStatus.signedOut;

  @override
  Future<Object?> call(Op op, {Map<String, Object?> args = const {}}) async {
    calls.add((op.name, args));

    return answers[op.name];
  }
}
