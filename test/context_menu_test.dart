import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:app/toolkit/theme/dark.dart';
import 'package:app/toolkit/theme/light.dart';

/// `ContextMenuRegion` (core): a cell inside a row inside a table, each declaring its own
/// entries. A right click (or a long press) on the cell offers the three groups, innermost
/// first; the menu stays inside the window; an action runs only after the menu has closed.
Future<void> _pump(WidgetTester tester, {
  required List<ContextEntry> Function() cell,
  List<ContextEntry> Function()? row,
  Alignment alignment = Alignment.topLeft
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) {
      AppSize.instance(context);

      return Scaffold(body: ContextMenuRegion(
        entries: (_) => [ContextItem(label: "Table action", onSelected: () {})],
        child: Align(
          alignment: alignment,
          child: ContextMenuRegion(
            entries: (_) => row?.call() ?? const [],
            child: ContextMenuRegion(
              entries: (_) => cell(),
              child: const SizedBox(width: 60, height: 30, child: Text("cell"))
            )
          )
        )
      ));
    })
  ));
}

Future<void> _rightClick(WidgetTester tester, Finder finder) async {
  await tester.tap(finder, buttons: kSecondaryButton, kind: PointerDeviceKind.mouse);
  await tester.pumpAndSettle();
}

/// The panel that holds [label]: the box decorated around the rows.
Rect _panelOf(WidgetTester tester, String label) => tester.getRect(find.ancestor(
  of: find.text(label),
  matching: find.byType(IntrinsicWidth)
).first);

void main() {
  // `showModal` asks whether this is a phone, which needs the device info.
  setUpAll(() {
    ThemeColor.light = lightScheme;
    ThemeColor.dark = darkScheme;
    DeviceInfoPlusWindowsPlugin.registerWith();
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (_) async => {'appName': '', 'packageName': '', 'version': '0', 'buildNumber': '0'}
    );
    return AppController().instance(false);
  });

  testWidgets('a right click offers the cell, then the row, then the table, tidied', (tester) async {
    await _pump(tester,
      cell: () => [
        const ContextSeparator(),
        ContextItem(label: "Copy", onSelected: () {}),
        const ContextSeparator(),
        const ContextSeparator(),
        const ContextHeader("Nothing under it")
      ],
      row: () => [ContextItem(label: "Delete row", danger: true, onSelected: () {})]
    );

    await _rightClick(tester, find.text("cell"));

    final copy = tester.getTopLeft(find.text("Copy")).dy;
    final row = tester.getTopLeft(find.text("Delete row")).dy;
    final table = tester.getTopLeft(find.text("Table action")).dy;

    expect(copy < row && row < table, isTrue);
    expect(find.text("Nothing under it"), findsNothing);
  });

  testWidgets('the action runs once the menu is closed', (tester) async {
    bool? openWhenRun;

    await _pump(tester, cell: () => [
      ContextItem(label: "Copy", onSelected: () {
        openWhenRun = Navigator.of(tester.element(find.text("cell"))).canPop();
      })
    ]);

    await _rightClick(tester, find.text("cell"));
    await tester.tap(find.text("Copy"));
    await tester.pumpAndSettle();

    expect(openWhenRun, isFalse);
    expect(find.text("Copy"), findsNothing);
  });

  testWidgets('a disabled action is drawn and cannot be picked', (tester) async {
    int runs = 0;
    await _pump(tester, cell: () => [
      ContextItem(label: "Paste", enabled: false, onSelected: () => runs++)
    ]);

    await _rightClick(tester, find.text("cell"));
    await tester.tap(find.text("Paste"));
    await tester.pumpAndSettle();

    expect(runs, 0);
    expect(find.text("Paste"), findsOneWidget);
  });

  testWidgets('with nothing to offer in the whole chain, nothing opens', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      AppSize.instance(context);
      return ContextMenuRegion(
        entries: (_) => const [ContextHeader("Alone"), ContextItem(label: "Off", enabled: false)],
        child: const Text("cell")
      );
    })));

    await _rightClick(tester, find.text("cell"));
    expect(find.text("Alone"), findsNothing);
  });

  testWidgets('opened at the window corner, it flips inside the window', (tester) async {
    await _pump(tester,
      alignment: Alignment.bottomRight,
      cell: () => [for (int i = 0; i < 6; i++) ContextItem(label: "Action $i", onSelected: () {})]
    );

    await _rightClick(tester, find.text("cell"));

    final window = Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
    final panel = _panelOf(tester, "Action 0");

    expect(window.contains(panel.topLeft), isTrue);
    expect(window.contains(panel.bottomRight - const Offset(1, 1)), isTrue);
  });

  testWidgets('a long press opens it for a finger: rows an action tall, no shortcuts', (tester) async {
    await _pump(tester, cell: () => [
      ContextItem(
        label: "Undo",
        shortcut: const SingleActivator(LogicalKeyboardKey.keyZ, control: true),
        onSelected: () {}
      )
    ]);

    await tester.longPress(find.text("cell"));
    await tester.pumpAndSettle();

    expect(find.text("Undo"), findsOneWidget);
    expect(find.text("Ctrl+Z"), findsNothing);

    final row = find.ancestor(of: find.text("Undo"), matching: find.byType(Container)).first;
    expect(tester.getSize(row).height, AppSize.action);
  });

  testWidgets('the mouse writes the shortcut and opens a submenu to the side', (tester) async {
    String? picked;
    await _pump(tester, cell: () => [
      ContextItem(
        label: "Undo",
        shortcut: const SingleActivator(LogicalKeyboardKey.keyZ, control: true),
        onSelected: () {}
      ),
      ContextItem(label: "Sort", children: [
        ContextItem(label: "Ascending", onSelected: () => picked = "asc")
      ]),
      // A submenu with nothing to pick is not offered.
      const ContextItem(label: "Empty", children: [ContextItem(label: "Off", enabled: false)])
    ]);

    // One mouse clicks and then hovers: a second one would be the same device added twice.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse, buttons: kSecondaryButton);
    await mouse.addPointer(location: tester.getCenter(find.text("cell")));
    await mouse.down(tester.getCenter(find.text("cell")));
    await mouse.up();
    await tester.pumpAndSettle();

    expect(find.text("Ctrl+Z"), findsOneWidget);
    expect(find.text("Empty"), findsNothing);

    await mouse.moveTo(tester.getCenter(find.text("Sort")));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(_panelOf(tester, "Ascending").left, greaterThanOrEqualTo(_panelOf(tester, "Sort").right));

    await tester.tap(find.text("Ascending"));
    await tester.pumpAndSettle();
    expect(picked, "asc");
    await mouse.removePointer();
  });

  testWidgets('the keyboard goes through it: arrows, right into a submenu, Enter picks', (tester) async {
    String? picked;
    await _pump(tester, cell: () => [
      ContextItem(label: "Copy", onSelected: () => picked = "copy"),
      const ContextItem(label: "Off", enabled: false),
      ContextItem(label: "Sort", children: [
        ContextItem(label: "Ascending", onSelected: () => picked = "asc"),
        ContextItem(label: "Descending", onSelected: () => picked = "desc")
      ])
    ]);

    await _rightClick(tester, find.text("cell"));

    // Down twice skips the disabled row and lands on the submenu.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(picked, "desc");
  });

  testWidgets('Escape closes a submenu first, then the menu', (tester) async {
    await _pump(tester, cell: () => [
      ContextItem(label: "Sort", children: [ContextItem(label: "Ascending", onSelected: () {})])
    ]);

    await _rightClick(tester, find.text("cell"));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text("Ascending"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text("Ascending"), findsNothing);
    expect(find.text("Sort"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text("Sort"), findsNothing);
  });

  testWidgets('it is drawn over a modal opened above the region', (tester) async {
    late BuildContext root;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      AppSize.instance(context);
      root = context;
      return const SizedBox.shrink();
    })));

    showModal(context: root, builder: (context) => ContextMenuRegion(
      entries: (_) => [ContextItem(label: "Inside the modal", onSelected: () {})],
      child: const SizedBox(width: 80, height: 30, child: Text("modal cell"))
    ));
    await tester.pumpAndSettle();

    await _rightClick(tester, find.text("modal cell"));

    // The hit at the row's center reaches the row: nothing is drawn over the menu.
    await tester.tap(find.text("Inside the modal"));
    await tester.pumpAndSettle();
    expect(find.text("Inside the modal"), findsNothing);
    expect(find.text("modal cell"), findsOneWidget);
  });
}
