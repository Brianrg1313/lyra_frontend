import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:core/core.dart';
import 'package:core/navis/screen_route.dart';

import 'package:app/services/database/database_service.dart';
import 'package:app/services/preferences/preferences_service.dart';

/// Filler screen: never built, the tests look at what `Navis` records.
class _Screen extends PageBuilder {
  const _Screen();

  @override
  Widget build(BuildContext context) => const SizedBox();
}

ScreenRoute _route(String key, String url, [List<String> parents = const []]) =>
  ScreenRoute(key: key, url: url, parents: parents, shell: "home", page: (_) => const _Screen());

final _routes = [
  ScreenRoute(key: "root", url: "/", page: (_) => const _Screen()),
  ScreenRoute(key: "login", url: "/login", page: (_) => const _Screen()),
  _route("dashboard", "/home"),
  _route("finance", "/home/finance"),
  _route("finance_payments", "/home/finance/payments", ["finance"]),
  _route("sales", "/home/sales"),
  _route("inventory", "/home/inventory"),
  _route("table", "/home/inventory/:id", ["inventory"])
];

/// Navigates and lets the box take the write (`DatabaseService.put` awaits the box first).
Future<void> _go(String path) async {
  Navis.navigate(path);
  await pumpEventQueue();
}

void main() {
  late Directory temp;
  final preferences = PreferencesService();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Navis.defineRoutes(_routes);
    // `preload` applies the stored theme to `AppController`, whose notifier is
    // made first thing by `instance`; the platform info it asks for next has no
    // plugin in tests and throws, which leaves the notifier already in place.
    try {
      await AppController().instance(false);
    } catch (_) {}
    temp = await Directory.systemTemp.createTemp('lyra_preferences_test');
    Hive.init(temp.path);
    await PreferencesService.preload();
  });

  tearDownAll(() async {
    await DatabaseService().dispose();
    await temp.delete(recursive: true);
  });

  setUp(() {
    preferences.bindUser("ana");
    preferences.useBusiness("b1");
    Navis.navigate("/");
  });

  test('the last page is the one being shown, not the one left', () async {
    await _go("/home/finance/payments");
    expect(preferences.lastPath, "/home/finance/payments");

    await _go("/home/sales");
    expect(preferences.lastPath, "/home/sales");
  });

  test('a page of the same route with another id is recorded too', () async {
    await _go("/home/inventory/t1");
    await _go("/home/inventory/t2");

    expect(preferences.lastPath, "/home/inventory/t2");
  });

  test('pages outside the home are not recorded', () async {
    await _go("/home/sales");
    await _go("/login");

    expect(preferences.homePath, "/home/sales");
  });

  test('each section remembers its last tab, per business', () async {
    await _go("/home/finance/payments");
    await _go("/home/sales");

    expect(preferences.lastPathIn("finance"), "/home/finance/payments");
    expect(preferences.lastPathIn("sales"), "/home/sales");

    preferences.useBusiness("b2");
    expect(preferences.lastPathIn("finance"), isNull);

    preferences.useBusiness("b1");
    expect(preferences.lastPathIn("finance"), "/home/finance/payments");
  });

  test('another account does not land where the first one left', () async {
    await _go("/home/finance/payments");

    preferences.bindUser("bob");
    preferences.useBusiness("b1");

    expect(preferences.lastPath, isNull);
    expect(preferences.lastPathIn("finance"), isNull);
  });
}
