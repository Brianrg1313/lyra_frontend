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
import 'package:app/services/connection/cloud_presence.dart';
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
  }) => pump(tester, () => Authentication(resume: () async => "/login", scan: () => NetworkScanService(
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

  testWidgets('the setup says what is missing under each field, the ticked passphrase included', (tester) async {
    await pumpGate(tester, canHost: true);
    await tester.enterText(find.byType(TextField).at(0), "ada@lyra.app");
    await tester.enterText(find.byType(TextField).at(1), "correct horse battery");
    await tester.tap(find.text(S.current.auth_create_button));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    Future<void> create() async {
      await tester.ensureVisible(find.text(S.current.lan_master_create));
      await tester.tap(find.text(S.current.lan_master_create));
      await tester.pump();
    }

    await create();
    expect(find.text(S.current.lan_field_empty(S.current.first_name_input)), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), "Ada");
    await tester.enterText(find.byType(TextField).at(1), "Lovelace");
    await tester.tap(find.text(S.current.lan_passphrase_toggle));
    await tester.pump();
    await create();
    expect(find.text(S.current.lan_field_empty(S.current.lan_passphrase_input)), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(2), "short");
    await create();
    expect(find.text(S.current.lan_passphrase_short), findsOneWidget);

    // Unticked, the short passphrase no longer counts: the licence is what's left.
    await tester.tap(find.text(S.current.lan_passphrase_toggle));
    await tester.pump();
    await create();
    expect(find.text(S.current.lan_master_eula_required), findsOneWidget);
  });

  testWidgets('the internet going away swaps the cloud form for the offline one, and back', (tester) async {
    var online = true;
    await pumpGate(tester, cloud: () async => online, masters: [found], canHost: true);
    expect(find.text(S.current.auth_title), findsOneWidget);

    online = false;
    await tester.pump(const Duration(seconds: 15));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(S.current.auth_title), findsNothing);
    expect(find.text(S.current.auth_lan_title), findsOneWidget);

    online = true;
    await tester.pump(const Duration(seconds: 15));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(S.current.auth_title), findsOneWidget);
    expect(find.text(S.current.auth_lan_title), findsNothing);
  });

  testWidgets('a session kept through a network failure is tried before the form, once', (tester) async {
    final answer = Completer<String?>();
    var tries = 0;
    await pump(tester, () => Authentication(
      resume: () {
        tries++;
        return answer.future;
      },
      scan: () => NetworkScanService(cloud: () async => true, discover: () async => const [], canHost: () async => false)
    ));

    expect(tries, 1);
    expect(find.text(S.current.auth_title), findsNothing);

    // No session, or the backend refused it: the sign in as always.
    answer.complete("/login");
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(S.current.auth_title), findsOneWidget);
    expect(tries, 1);
  });

  testWidgets('where no master can run (web, phones), the placeholder; "try again" looks once more', (tester) async {
    final answers = <Completer<bool>>[];
    await pump(tester, () => Authentication(resume: () async => "/login", scan: () => NetworkScanService(
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
    // The stored session is tried first (none here), then the form.
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

    test('it keeps looking, except while held', () {
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
        expect((looks, scan.reach), (7, NetworkReach.online));
        scan.dispose();
      });
    });

    test("the backend's socket says it at once: connecting is online, a drop looks now", () {
      fakeAsync((async) {
        var online = false;
        var clouds = 0;
        final presence = _Presence();
        final scan = NetworkScanService(
          cloud: () async {
            clouds++;
            return online;
          },
          discover: () async => const [found],
          canHost: () async => false,
          presence: presence,
          every: const Duration(minutes: 1)
        );

        scan.watch();
        async.flushMicrotasks();
        expect((presence.started, scan.reach), (true, NetworkReach.master));

        online = true;
        presence.live.value = true;
        expect(scan.reach, NetworkReach.online);

        online = false;
        presence.live.value = false;
        async.flushMicrotasks();
        expect((clouds, scan.reach), (2, NetworkReach.master));

        // A sign in under way keeps its page; released, what the socket said counts.
        scan.hold(true);
        presence.live.value = true;
        expect(scan.reach, NetworkReach.master);
        scan.hold(false);
        expect(scan.reach, NetworkReach.online);

        scan.dispose();
        expect(presence.started, false);
      });
    });

    test('a look under way when the socket connects does not take online back', () {
      fakeAsync((async) {
        final answer = Completer<bool>();
        final presence = _Presence();
        final scan = NetworkScanService(
          cloud: () => answer.future,
          discover: () async => const [],
          canHost: () async => false,
          presence: presence
        );

        scan.watch();
        presence.live.value = true;
        answer.complete(false);
        async.flushMicrotasks();
        expect(scan.reach, NetworkReach.online);
        scan.dispose();
      });
    });

    test('online it asks only the backend; a miss looks at everything before leaving it', () {
      fakeAsync((async) {
        var clouds = 0;
        var discovers = 0;
        var online = true;
        final scan = NetworkScanService(
          cloud: () async {
            clouds++;
            return online;
          },
          discover: () async {
            discovers++;
            return const [found];
          },
          canHost: () async => false,
          every: const Duration(seconds: 15)
        );

        scan.watch();
        async.elapse(const Duration(seconds: 30));
        expect((clouds, discovers, scan.reach), (3, 1, NetworkReach.online));

        online = false;
        async.elapse(const Duration(seconds: 15));
        // The tick's miss, then the full look's own question.
        expect((clouds, discovers, scan.reach), (5, 2, NetworkReach.master));

        online = true;
        async.elapse(const Duration(seconds: 15));
        expect((clouds, discovers, scan.reach), (6, 3, NetworkReach.online));
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

/// The backend's socket, said by the test.
class _Presence extends CloudPresence {
  bool started = false;

  @override
  void start() => started = true;

  @override
  void stop() => started = false;
}
