import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/toolkit/deployment.dart';
import 'package:app/services/lan/lan_identity_store.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/lan/network_scan_service.dart';
import 'package:app/screens/authentication/_authentication.dart';

/// A device paired with a master signs in on the one sign in page: with the backend answering,
/// the cloud's form (sign in or sign up, a cloud session); without it, its master's, in the
/// cloud's steps: the e-mail alone, then what `auth.identify` answers: the password under it,
/// or (someone invited) the activation code and a new password.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  setUp(() => Deployment.use(DeploymentMode.local, role: DeploymentRole.client));
  tearDown(() => Deployment.use(DeploymentMode.cloud));

  Future<_Master> pump(WidgetTester tester, {bool activation = false, bool online = false, bool Function()? cloud}) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final master = _Master(activation: activation);
    await tester.pumpWidget(ChangeNotifierProvider<LanService>.value(
      value: master,
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

          return Authentication(resume: () async => "/login", scan: () => NetworkScanService(
            cloud: () async => cloud?.call() ?? online,
            discover: () async => const [],
            canHost: () async => false
          ));
        })
      )
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    return master;
  }

  Future<void> next(WidgetTester tester, String button) async {
    await tester.tap(find.text(button));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets("with the backend answering, a paired device gets the cloud's sign in and sign up", (tester) async {
    await pump(tester, online: true);

    expect(tester.takeException(), isNull);
    expect(find.text(S.current.auth_title), findsOneWidget);
    expect(find.text(S.current.auth_master_title), findsNothing);
    expect(Deployment.mode, DeploymentMode.cloud);
    expect(Deployment.paired, DeploymentRole.client);
  });

  testWidgets("without the backend, its master's: the e-mail alone and 'continue', as in the cloud", (tester) async {
    Deployment.online();
    await pump(tester);

    expect(tester.takeException(), isNull);
    expect(Deployment.mode, DeploymentMode.local);
    expect(find.text(S.current.auth_master_title), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(S.current.auth_continue), findsOneWidget);
    expect(find.text(S.current.auth_lan_title), findsNothing);
  });

  testWidgets("the internet going away swaps the cloud's form for its master's, and back", (tester) async {
    var online = true;
    await pump(tester, cloud: () => online);
    expect(find.text(S.current.auth_title), findsOneWidget);

    online = false;
    await tester.pump(const Duration(seconds: 15));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(S.current.auth_master_title), findsOneWidget);
    expect(Deployment.mode, DeploymentMode.local);

    online = true;
    await tester.pump(const Duration(seconds: 15));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(S.current.auth_title), findsOneWidget);
    expect(Deployment.mode, DeploymentMode.cloud);
  });

  testWidgets('an account with a password is asked for it under the e-mail, and a refusal says so', (tester) async {
    final master = await pump(tester);

    await tester.enterText(find.byType(TextField), " ada@lyra.app ");
    await next(tester, S.current.auth_continue);
    expect(master.identified, ["ada@lyra.app"]);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).at(1), "correct horse battery");
    await next(tester, S.current.login);
    expect(master.signIns, [("ada@lyra.app", "correct horse battery")]);
    expect(find.text(_Master.refusal), findsOneWidget);
  });

  testWidgets('an invited account activates: code and a new password of 10 characters or more', (tester) async {
    final master = await pump(tester, activation: true);

    await tester.enterText(find.byType(TextField), "grace@lyra.app");
    await next(tester, S.current.auth_continue);
    expect(find.text(S.current.lan_activate_title), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));

    await tester.enterText(find.byType(TextField).at(1), "12345678");
    await tester.enterText(find.byType(TextField).at(2), "ninechars");
    await next(tester, S.current.lan_activate_button);
    expect(find.text(S.current.lan_master_weak_password), findsOneWidget);
    expect(master.activations, isEmpty);

    await tester.enterText(find.byType(TextField).at(2), "correct horse battery");
    await next(tester, S.current.lan_activate_button);
    expect(master.activations, [("grace@lyra.app", "12345678", "correct horse battery")]);
  });
}

/// A connected master nobody is signed in to, which refuses every password.
class _Master extends LanService {
  _Master({required this.activation}) : super(store: MemoryLanIdentityStore());

  static const refusal = "Wrong email or password.";

  final bool activation;
  final identified = <String>[];
  final signIns = <(String, String)>[];
  final activations = <(String, String, String)>[];

  @override
  LanStatus get status => LanStatus.signedOut;

  @override
  String? get error => refusal;

  @override
  Future<bool?> needsActivation(String login) async {
    identified.add(login);
    return activation;
  }

  @override
  Future<LanStatus> signIn(String login, String password) async {
    signIns.add((login, password));
    return LanStatus.signedOut;
  }

  @override
  Future<LanStatus> activate(String login, String code, String password) async {
    activations.add((login, code, password));
    return LanStatus.signedOut;
  }
}
