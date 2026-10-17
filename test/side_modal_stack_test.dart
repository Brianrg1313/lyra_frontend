/// A side panel opened from another one slides left to let the one below peek.
/// It stays touchable all over where it is drawn: its left part, moved out of
/// where layout placed it, is the panel and not the transparent barrier behind,
/// which would close it and go back to the one below.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:device_info_plus/device_info_plus.dart';

const _first = Key('first');
const _second = Key('second');

void main() {
  // `showSideModal` asks whether this is a phone, which needs the device info
  // (read from Windows itself, as the app does); the app version read before
  // it has no plugin in tests.
  setUpAll(() {
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
    DeviceInfoPlusWindowsPlugin.registerWith();
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (_) async => {'appName': '', 'packageName': '', 'version': '0', 'buildNumber': '0'}
    );
    return AppController().instance(false);
  });

  testWidgets('a tap on the left edge of the panel on top keeps it open', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late BuildContext page;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      AppSize.instance(context);
      page = context;
      return const SizedBox.expand();
    })));

    showSideModal(context: page, builder: (context) => SizedBox(
      key: _first,
      width: 600,
      height: 100,
      child: GestureDetector(onTap: () => showSideModal(
        context: context,
        builder: (_) => const SizedBox(key: _second, width: 600, height: 100)
      ))
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_first));
    await tester.pumpAndSettle();

    // Inside the quarter it slid left, off the box layout gave it.
    final second = tester.getRect(find.byKey(_second));
    await tester.tapAt(second.centerLeft + const Offset(4, 0));
    await tester.pumpAndSettle();

    expect(find.byKey(_second), findsOneWidget);
  });
}
