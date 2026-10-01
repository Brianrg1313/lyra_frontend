import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/toolkit/lan.dart';
import 'package:app/services/lan/lan_identity_store.dart';
import 'package:app/services/lan/lan_pairing_service.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/lan/network_scan_service.dart';
import 'package:app/screens/authentication/_authentication.dart';
import 'package:app/screens/authentication/auth_lan.dart';

/// The sign in follows the network (plan §7.4): the backend answers → the cloud's form as always;
/// it doesn't but a master is on the LAN → that master's sign in; neither → "create master
/// server" where this computer can be one, a placeholder where it can't. Pumped wide: the test
/// font's square glyphs overflow the auth footer's links at a narrower window.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  const found = LanFound(name: "lyra-abc", host: "192.168.1.5", port: 4780);

  Future<void> pump(WidgetTester tester, Widget Function() page) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => LanService(store: MemoryLanIdentityStore()),
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

          return page();
        })
      )
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> pumpGate(
    WidgetTester tester, {
    Future<bool> Function()? cloud,
    List<LanFound> masters = const [],
    bool canHost = false,
  }) => pump(tester, () => Authentication(scan: () => NetworkScanService(
    cloud: cloud ?? () async => false,
    discover: () async => masters,
    canHost: () async => canHost
  )));

  testWidgets('with the backend answering, the sign in as always, even with a master around', (tester) async {
    await pumpGate(tester, cloud: () async => true, masters: [found], canHost: true);

    expect(tester.takeException(), isNull);
    expect(find.text(S.current.auth_title), findsOneWidget);
    expect(find.text(S.current.auth_lan_title), findsNothing);
  });

  testWidgets('offline with a master on the LAN, its sign in: email, password, sign in', (tester) async {
    await pumpGate(tester, masters: [found], canHost: true);

    expect(tester.takeException(), isNull);
    expect(find.text(S.current.auth_lan_title), findsOneWidget);
    expect(find.text(S.current.login), findsOneWidget);
    expect(find.text(S.current.auth_create_button), findsNothing);
    // One server needs no choosing.
    expect(find.text(S.current.auth_lan_server), findsNothing);
  });

  testWidgets('offline with no master, this computer offers to be it: Create Master Server', (tester) async {
    await pumpGate(tester, canHost: true);

    expect(tester.takeException(), isNull);
    expect(find.text(S.current.auth_create_title), findsOneWidget);
    expect(find.text(S.current.auth_create_button), findsOneWidget);
  });

  testWidgets('the email and password become the owner: the setup asks only for the rest', (tester) async {
    await pumpGate(tester, canHost: true);

    await tester.enterText(find.byType(TextField).at(0), "ada@lyra.app");
    await tester.enterText(find.byType(TextField).at(1), "ninechars");
    await tester.tap(find.text(S.current.auth_create_button));
    await tester.pump();
    expect(find.text(S.current.lan_master_weak_password), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), "correct horse battery");
    await tester.tap(find.text(S.current.auth_create_button));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(S.current.lan_master_title), findsOneWidget);
    expect(find.text(S.current.lan_master_owner_email("ada@lyra.app")), findsOneWidget);
    expect(find.text(S.current.lan_username_input), findsNothing);
    expect(find.text(S.current.password_input), findsNothing);

    await tester.tap(find.text(S.current.back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(S.current.auth_create_button), findsOneWidget);
  });

  testWidgets('where no master can run (web, phones), the placeholder; "try again" looks once more', (tester) async {
    final answers = <Completer<bool>>[];
    await pump(tester, () => Authentication(scan: () => NetworkScanService(
      cloud: () {
        answers.add(Completer());
        return answers.last.future;
      },
      discover: () async => const [],
      canHost: () async => false
    )));

    expect(find.text(S.current.auth_title), findsNothing);
    expect(find.text(S.current.auth_offline_title), findsNothing);

    answers.last.complete(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(S.current.auth_offline_title), findsOneWidget);

    await tester.tap(find.text(S.current.auth_offline_retry));
    await tester.pump();
    expect(answers, hasLength(2));

    answers.last.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(S.current.auth_title), findsOneWidget);
  });

  group('signing in to a master', () {
    Future<void> pumpLan(WidgetTester tester, _Pairing pairing, {List<LanFound> masters = const [found], VoidCallback? enter}) =>
      pump(tester, () => ChangeNotifierProvider(
        create: (_) => NetworkScanService(cloud: () async => false, discover: () async => masters, canHost: () async => false),
        child: Material(child: AuthLan(masters: masters, onCreate: (_, _) {}, pairing: pairing, enter: enter))
      ));

    Future<void> signIn(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField).at(0), "ada@lyra.app");
      await tester.enterText(find.byType(TextField).at(1), "correct horse battery");
      await tester.tap(find.text(S.current.login));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('pairs with the login and password, then enters', (tester) async {
      final pairing = _Pairing(null);
      var entered = false;
      await pumpLan(tester, pairing, enter: () => entered = true);

      await signIn(tester);

      expect(pairing.asked, ("192.168.1.5", 4780, "ada@lyra.app", "correct horse battery"));
      expect(entered, isTrue);
    });

    testWidgets('a wrong password says so and stays', (tester) async {
      var entered = false;
      await pumpLan(tester, _Pairing(LanPairingError.wrongCode), enter: () => entered = true);

      await signIn(tester);

      expect(find.text(S.current.auth_lan_wrong), findsOneWidget);
      expect(entered, isFalse);
    });

    testWidgets('two servers on the network: the person picks one', (tester) async {
      await pumpLan(tester, _Pairing(null), masters: const [found, LanFound(name: "lyra-def", host: "192.168.1.9", port: 4780)]);

      expect(find.text(S.current.auth_lan_server), findsOneWidget);
    });
  });

  group('the scan', () {
    test('the backend wins over a master; a master over nothing', () async {
      for (final (cloud, masters, reach) in [
        (true, [found], NetworkReach.online),
        (false, [found], NetworkReach.master),
        (false, <LanFound>[], NetworkReach.none),
      ]) {
        final scan = NetworkScanService(cloud: () async => cloud, discover: () async => masters, canHost: () async => true);

        expect(scan.reach, NetworkReach.searching);
        await scan.scan();
        expect(scan.reach, reach);
        scan.dispose();
      }
    });

    test('a discovery or engine check that fails counts as nothing found', () async {
      final scan = NetworkScanService(
        cloud: () async => false,
        discover: () => Future.error(StateError("no multicast")),
        canHost: () => Future.error(StateError("no engine"))
      );

      await scan.scan();

      expect((scan.reach, scan.canHost), (NetworkReach.none, false));
      scan.dispose();
    });

    test('it looks again until the backend answers, except while held', () {
      fakeAsync((async) {
        var looks = 0;
        var online = false;
        final scan = NetworkScanService(
          cloud: () async {
            looks++;
            return online;
          },
          discover: () async => const [],
          canHost: () async => false,
          every: const Duration(seconds: 15)
        );

        scan.watch();
        async.flushMicrotasks();
        expect(looks, 1);

        async.elapse(const Duration(seconds: 15));
        expect((looks, scan.reach), (2, NetworkReach.none));

        scan.hold(true);
        async.elapse(const Duration(seconds: 30));
        expect(looks, 2);

        scan.hold(false);
        online = true;
        async.elapse(const Duration(seconds: 15));
        expect((looks, scan.reach), (3, NetworkReach.online));

        async.elapse(const Duration(minutes: 1));
        expect(looks, 3);
        scan.dispose();
      });
    });
  });
}

/// Answers [failure] to the password way and records what it was asked.
class _Pairing extends LanPairingService {
  _Pairing(this.failure) : super(store: MemoryLanIdentityStore());

  final LanPairingError? failure;
  (String, int, String, String)? asked;

  @override
  Future<LanPairingError?> pairWithPassword({
    required String host,
    required int port,
    required String login,
    required String password,
    String? name,
  }) async {
    asked = (host, port, login, password);
    return failure;
  }
}
