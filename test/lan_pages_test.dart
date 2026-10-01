import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/toolkit/deployment.dart';
import 'package:app/services/lan/lan_identity_store.dart';
import 'package:app/services/lan/lan_pairing_service.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/local_server/local_server_service.dart';
import 'package:app/services/local_server/node_commands.dart';
import 'package:app/screens/pre_start/deployment/master/desktop/_body.dart' as master;
import 'package:app/screens/pre_start/deployment/pair/desktop/_body.dart' as pair;
import 'package:app/screens/pre_start/lan/desktop/_body.dart' as landing;
import 'package:app/screens/home/sections/local_server/_local_server.dart';
import 'package:app/screens/home/sections/local_server/widgets/pairing_qr.dart';
import 'package:lyra_protocol/lyra_protocol.dart' show PairingOffer, Pairing;

import 'lan_client_test.dart' show FakeMaster, device;

/// The deployment and LAN pages draw every state without overflowing, at a desktop window and
/// at the narrowest one (400 px), and say what the state means.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });
  tearDown(() => Deployment.use(DeploymentMode.cloud));

  Future<void> pump(WidgetTester tester, Widget body, {required LanService lan, Size size = const Size(1024, 720), bool settle = true}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Builder(builder: (context) {
        AppSize.instance(context);

        return MultiProvider(providers: [
          ChangeNotifierProvider.value(value: lan),
          ChangeNotifierProvider(create: (_) => LanPairingService(
            store: MemoryLanIdentityStore(),
            discover: () async => const [],
          ))
        // `PageBuilder` puts the page on a `Material`; the bodies are pumped without it.
        ], child: Material(child: body));
      })
    ));
    // A page that keeps loading never settles.
    settle ? await tester.pumpAndSettle() : await tester.pump(const Duration(milliseconds: 100));
  }

  /// Leaves the tree, so the connected page's refresh timer stops.
  Future<void> leave(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  LanService client(FakeMaster fake, {bool paired = true, String? refresh}) {
    Deployment.use(DeploymentMode.local, role: DeploymentRole.client);

    return LanService(
      store: MemoryLanIdentityStore()
        ..stored = paired ? device() : null
        ..refresh = refresh,
      connect: (_, _) async => fake.connect()
    );
  }

  for (final size in const [Size(1024, 720), Size(400, 700)]) {
    group('at ${size.width.toInt()} px', () {
      testWidgets('the master setup asks for the licence before anything', (tester) async {
        final lan = LanService(server: LocalServerService(commands: _NoNode(), supported: true, store: MemoryLanIdentityStore()));

        await pump(tester, const master.DesktopBody(), lan: lan, size: size);
        expect(tester.takeException(), isNull);
        expect(find.text("I accept the Lyra licence agreement"), findsOneWidget);
      });

      testWidgets('the pairing page draws with no server found', (tester) async {
        await pump(tester, const pair.DesktopBody(), lan: LanService(), size: size);

        expect(tester.takeException(), isNull);
        expect(find.text("No server found. Type its address instead."), findsOneWidget);
      });

      testWidgets('signed out, it asks for the account', (tester) async {
        final lan = client(FakeMaster());
        await lan.open();

        await pump(tester, const landing.DesktopBody(), lan: lan, size: size);

        expect(tester.takeException(), isNull);
        expect(find.text("Use the username and password of your account on this server."), findsOneWidget);
      });

      testWidgets('signed in, it opens the app', (tester) async {
        final lan = client(FakeMaster(), refresh: "refresh-1");
        expect(await lan.open(), LanStatus.ready);
        final entered = Completer<String?>();

        await pump(tester, landing.DesktopBody(enter: () => entered.future), lan: lan, size: size, settle: false);

        expect(tester.takeException(), isNull);
        expect(find.text("Opening Lyra…"), findsOneWidget);
      });

      testWidgets('a session the master cannot load stops with a message instead of trying forever', (tester) async {
        final lan = client(FakeMaster(), refresh: "refresh-1");
        expect(await lan.open(), LanStatus.ready);

        await pump(tester, landing.DesktopBody(enter: () async => "/lan"), lan: lan, size: size);

        expect(tester.takeException(), isNull);
        expect(find.textContaining("the business couldn't be opened"), findsOneWidget);
        expect(find.text("Try again"), findsOneWidget);
      });

      testWidgets('the server section lists the devices', (tester) async {
        final lan = client(FakeMaster(), refresh: "refresh-1");
        expect(await lan.open(), LanStatus.ready);

        await pump(tester, const LocalServerSection(), lan: lan, size: size);

        expect(tester.takeException(), isNull);
        expect(find.text("Connected to the server"), findsOneWidget);
        expect(find.text("This device: B"), findsOneWidget);
        // A native device hands out the browsers' root, with what the OS will show to compare.
        expect(find.text("Web browsers"), findsOneWidget);
        expect(find.text("CDCD CDCD CDCD CDCD CDCD CDCD CDCD CDCD CDCD CDCD"), findsOneWidget);
        // By the master's name first; its address in case the name doesn't resolve there.
        expect(find.text("Then open https://lovelace-cafe.local:4780 in the browser."), findsOneWidget);
        expect(find.text("If that name doesn't open, use https://192.168.1.5:4780."), findsOneWidget);
        await leave(tester);
      });

      testWidgets('locked, a client is told to ask on the server', (tester) async {
        final lan = client(FakeMaster()..locked = true);
        expect(await lan.open(), LanStatus.locked);

        await pump(tester, const landing.DesktopBody(), lan: lan, size: size);

        expect(tester.takeException(), isNull);
        expect(find.text("Ask someone to unlock it on the server computer."), findsOneWidget);
      });

      testWidgets('the pairing QR draws the offer', (tester) async {
        final offer = PairingOffer(
          instanceId: "i1",
          addresses: const ["192.168.1.5"],
          port: 4780,
          caFingerprint: "ab" * 32,
          token: Pairing.newToken(),
        );

        await pump(tester, Center(child: PairingQr(data: offer.encode())), lan: LanService(), size: size);

        expect(tester.takeException(), isNull);
        expect(find.byType(PairingQr), findsOneWidget);
      });

      testWidgets('unpaired, it offers to pair', (tester) async {
        final lan = client(FakeMaster(), paired: false);
        expect(await lan.open(), LanStatus.unpaired);

        await pump(tester, const landing.DesktopBody(), lan: lan, size: size);

        expect(tester.takeException(), isNull);
        expect(find.text("Pair again"), findsOneWidget);
      });
    });
  }
}

class _NoNode implements NodeCommands {
  @override
  Future<NodeAnswer> run(List<String> command, {String? input}) async => (exitCode: 0, json: const <String, Object?>{});

  @override
  Future<void> spawn({String? passphrase}) async {}
}
