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
import 'package:app/services/local_server/local_server_service.dart';
import 'package:app/screens/authentication/_authentication.dart';
import 'package:app/screens/authentication/auth_lan.dart';

/// The sign in follows the network (plan §7.4): the backend's `/presence` socket is connected →
/// the cloud's form as always;
/// it isn't but a master is on the LAN → that master's sign in; neither → "create master
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
    _Presence? presence,
    List<LanFound> masters = const [],
    LocalServerStatus engine = LocalServerStatus.unavailable,
  }) => pump(tester, () => Authentication(resume: () async => "/login", scan: () => NetworkScanService(
    presence: presence ?? _Presence(false),
    discover: () async => masters,
    engine: () async => engine
  )));

  testWidgets('with the backend answering, the sign in as always, even with a master around', (tester) async {
    await pumpGate(tester, presence: _Presence(true), masters: [found], engine: LocalServerStatus.notSetUp);

    expect(tester.takeException(), isNull);
    expect(find.text(S.current.auth_title), findsOneWidget);
    expect(find.text(S.current.auth_lan_title), findsNothing);
  });

  testWidgets('offline with a master on the LAN, its sign in: email, password, sign in', (tester) async {
    await pumpGate(tester, masters: [found], engine: LocalServerStatus.notSetUp);

    expect(tester.takeException(), isNull);
    expect(find.text(S.current.auth_lan_title), findsOneWidget);
    expect(find.text(S.current.login), findsOneWidget);
    expect(find.text(S.current.auth_create_button), findsNothing);
    // One server needs no choosing.
    expect(find.text(S.current.auth_lan_server), findsNothing);
  });

  testWidgets('offline with no master, this computer offers to be it: Create Master Server', (tester) async {
    await pumpGate(tester, engine: LocalServerStatus.notSetUp);

    expect(tester.takeException(), isNull);
    expect(find.text(S.current.auth_create_title), findsOneWidget);
    expect(find.text(S.current.auth_create_button), findsOneWidget);
  });

  testWidgets('the email and password become the owner: the setup asks only for the rest', (tester) async {
    await pumpGate(tester, engine: LocalServerStatus.notSetUp);

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
    await pumpGate(tester, engine: LocalServerStatus.notSetUp);
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
    final presence = _Presence(true);
    await pumpGate(tester, presence: presence, masters: [found], engine: LocalServerStatus.notSetUp);
    expect(find.text(S.current.auth_title), findsOneWidget);

    // At once: no timer to wait for.
    presence.live.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(S.current.auth_title), findsNothing);
    expect(find.text(S.current.auth_lan_title), findsOneWidget);

    presence.live.value = true;
    await tester.pump();
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
      scan: () => NetworkScanService(presence: _Presence(true), discover: () async => const [], engine: () async => LocalServerStatus.unavailable)
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
    final presence = _Presence();
    var looks = 0;
    await pump(tester, () => Authentication(resume: () async => "/login", scan: () => NetworkScanService(
      presence: presence,
      discover: () async {
        looks++;
        return const [];
      },
      engine: () async => LocalServerStatus.unavailable
    )));

    // The socket hasn't answered yet.
    expect(find.text(S.current.auth_title), findsNothing);
    expect(find.text(S.current.auth_offline_title), findsNothing);

    presence.live.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(S.current.auth_offline_title), findsOneWidget);

    await tester.tap(find.text(S.current.auth_offline_retry));
    await tester.pump();
    expect(looks, 2);

    presence.live.value = true;
    await tester.pump();
    // The stored session is tried first (none here), then the form.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(S.current.auth_title), findsOneWidget);
  });

  group('signing in to a master', () {
    Future<void> pumpLan(WidgetTester tester, _Pairing pairing, {List<LanFound> masters = const [found], VoidCallback? enter}) =>
      pump(tester, () => ChangeNotifierProvider(
        create: (_) => NetworkScanService(presence: _Presence(false), discover: () async => masters, engine: () async => LocalServerStatus.unavailable),
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
      for (final (live, masters, reach) in [
        (true, [found], NetworkReach.online),
        (false, [found], NetworkReach.master),
        (false, <LanFound>[], NetworkReach.none),
      ]) {
        final scan = NetworkScanService(presence: _Presence(live), discover: () async => masters, engine: () async => LocalServerStatus.notSetUp);

        expect(scan.reach, NetworkReach.searching);
        await scan.scan();
        expect(scan.reach, reach);
        scan.dispose();
      }
    });

    test('searching until the socket has answered', () async {
      final presence = _Presence();
      final scan = NetworkScanService(presence: presence, discover: () async => const [found], engine: () async => LocalServerStatus.unavailable);

      await scan.watch();
      expect(scan.reach, NetworkReach.searching);

      presence.live.value = false;
      expect(scan.reach, NetworkReach.master);
      scan.dispose();
    });

    test('a discovery or engine check that fails counts as nothing found', () async {
      final scan = NetworkScanService(
        presence: _Presence(false),
        discover: () => Future.error(StateError("no multicast")),
        engine: () => Future.error(StateError("no engine"))
      );

      await scan.scan();

      expect((scan.reach, scan.canHost), (NetworkReach.none, false));
      scan.dispose();
    });

    test('offline it looks at the LAN again, except while held; online it never does', () {
      fakeAsync((async) {
        var looks = 0;
        final presence = _Presence(false);
        final scan = NetworkScanService(
          presence: presence,
          discover: () async {
            looks++;
            return const [];
          },
          engine: () async => LocalServerStatus.unavailable,
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
        presence.live.value = true;
        expect(scan.reach, NetworkReach.online);

        async.elapse(const Duration(minutes: 1));
        expect((looks, scan.reach), (2, NetworkReach.online));
        scan.dispose();
      });
    });

    test("the backend's socket says it at once: connecting is online, a drop is offline and looks at the LAN now", () {
      fakeAsync((async) {
        var looks = 0;
        final presence = _Presence(false);
        final scan = NetworkScanService(
          presence: presence,
          discover: () async {
            looks++;
            return const [found];
          },
          engine: () async => LocalServerStatus.unavailable,
          every: const Duration(minutes: 1)
        );

        scan.watch();
        async.flushMicrotasks();
        expect((presence.started, scan.reach), (true, NetworkReach.master));

        presence.live.value = true;
        expect(scan.reach, NetworkReach.online);

        presence.live.value = false;
        expect(scan.reach, NetworkReach.master);
        async.flushMicrotasks();
        expect(looks, 2);

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

/// The backend's socket, said by the test: [live] null until it answers.
class _Presence extends CloudPresence {
  _Presence([bool? live]) {
    this.live.value = live;
  }

  bool started = false;

  @override
  void start() => started = true;

  @override
  void stop() => started = false;
}
