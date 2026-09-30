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
import 'package:app/screens/pre_start/deployment/desktop/_body.dart' as chooser;
import 'package:app/screens/pre_start/deployment/master/desktop/_body.dart' as master;
import 'package:app/screens/pre_start/deployment/pair/desktop/_body.dart' as pair;
import 'package:app/screens/pre_start/lan/desktop/_body.dart' as landing;

import 'lan_client_test.dart' show FakeMaster, device;

/// The deployment and LAN pages draw every state without overflowing, at a desktop window and
/// at the narrowest one (400 px), and say what the state means.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });
  tearDown(() => Deployment.use(DeploymentMode.cloud));

  Future<void> pump(WidgetTester tester, Widget body, {required LanService lan, Size size = const Size(1024, 720)}) async {
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
    await tester.pumpAndSettle();
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
      testWidgets('the chooser offers the server only where the engine ships', (tester) async {
        final lan = LanService(server: LocalServerService(commands: _NoNode(), supported: false, store: MemoryLanIdentityStore()));

        await pump(tester, const chooser.DesktopBody(), lan: lan, size: size);

        expect(tester.takeException(), isNull);
        expect(find.text("Use Lyra online"), findsOneWidget);
        expect(find.text("This computer is the server"), findsNothing);
        expect(find.text("Connect to a server"), findsOneWidget);
      });

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

      testWidgets('connected, it lists the devices', (tester) async {
        final lan = client(FakeMaster(), refresh: "refresh-1");
        expect(await lan.open(), LanStatus.ready);

        await pump(tester, const landing.DesktopBody(), lan: lan, size: size);

        expect(tester.takeException(), isNull);
        expect(find.text("Connected to the server"), findsOneWidget);
        expect(find.text("This device: B"), findsOneWidget);
        await leave(tester);
      });

      testWidgets('locked, a client is told to ask on the server', (tester) async {
        final lan = client(FakeMaster()..locked = true);
        expect(await lan.open(), LanStatus.locked);

        await pump(tester, const landing.DesktopBody(), lan: lan, size: size);

        expect(tester.takeException(), isNull);
        expect(find.text("Ask someone to unlock it on the server computer."), findsOneWidget);
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
