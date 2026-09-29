/// A modal draws the bar of its body's scroll in its own right padding, so the
/// content sits at the same distance from both edges whether it scrolls or not.
/// The bar is the modal's and so is its controller, which only one scroll view
/// can hold at a time: the first to ask. When the body swaps its scroll, the
/// new one takes the controller over once the old one is gone.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';

const _padding = EdgeInsets.all(13);

Widget _modal(Widget body, {ThemeData? theme}) => MaterialApp(
  theme: theme,
  home: Center(child: SizedBox(
    width: 300,
    height: 200,
    child: ModalScroll(padding: _padding, child: body)
  ))
);

Widget _tall(Key key) => SizedBox(key: key, height: 1000);

ScrollController? _controllerOf(WidgetTester tester, Key content) => tester
  .widget<SingleChildScrollView>(find.ancestor(
    of: find.byKey(content),
    matching: find.byType(SingleChildScrollView)
  ))
  .controller;

ScrollController? _modalController(WidgetTester tester) =>
  tester.widget<Scrollbar>(find.byType(Scrollbar)).controller;

void main() {
  testWidgets('the content is inset the same on the left and on the right', (tester) async {
    const content = Key('content');
    await tester.pumpWidget(_modal(ScrollableWidget(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_tall(content)]
    )));

    final modal = tester.getRect(find.byType(ModalScroll));
    final rect = tester.getRect(find.byKey(content));

    expect(rect.left - modal.left, _padding.left);
    expect(modal.right - rect.right, _padding.right);
  });

  testWidgets('the body scroll drives the modal bar', (tester) async {
    const content = Key('content');
    await tester.pumpWidget(_modal(ScrollableWidget(children: [_tall(content)])));

    expect(_controllerOf(tester, content), isNotNull);
    expect(_controllerOf(tester, content), same(_modalController(tester)));
  });

  testWidgets('the thumb in the right padding can be dragged', (tester) async {
    const content = Key('content');
    // Always shown: a desktop bar otherwise waits for a hover or a scroll,
    // which is timing, not what this pins.
    await tester.pumpWidget(_modal(
      ScrollableWidget(children: [_tall(content)]),
      theme: ThemeData(scrollbarTheme: const ScrollbarThemeData(
        thumbVisibility: WidgetStatePropertyAll(true)
      ))
    ));
    await tester.pumpAndSettle();

    final modal = tester.getRect(find.byType(ModalScroll));
    final controller = _modalController(tester)!;
    final thumb = Offset(
      modal.right - _padding.right / 2,
      modal.top + _padding.top + 5
    );

    final mouse = await tester.startGesture(thumb, kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    await mouse.moveBy(const Offset(0, 20));
    await tester.pumpAndSettle();
    await mouse.up();
    await tester.pumpAndSettle();

    expect(controller.offset, greaterThan(0));
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('only the first scroll takes the modal controller', (tester) async {
    const first = Key('first');
    const second = Key('second');
    await tester.pumpWidget(_modal(Column(children: [
      Expanded(child: ScrollableWidget(children: [_tall(first)])),
      Expanded(child: ScrollableWidget(children: [_tall(second)]))
    ])));

    expect(_controllerOf(tester, first), same(_modalController(tester)));
    expect(_controllerOf(tester, second), isNull);
  });

  testWidgets('a scroll that opts out keeps its own bar', (tester) async {
    const content = Key('content');
    await tester.pumpWidget(_modal(ScrollableWidget(
      modalBar: false,
      children: [_tall(content)]
    )));

    expect(_controllerOf(tester, content), isNull);
  });

  testWidgets('a scroll that replaces the body one takes the controller over', (tester) async {
    const before = Key('before');
    const after = Key('after');
    await tester.pumpWidget(_modal(ScrollableWidget(
      key: const ValueKey(1),
      children: [_tall(before)]
    )));

    await tester.pumpWidget(_modal(ScrollableWidget(
      key: const ValueKey(2),
      children: [_tall(after)]
    )));
    // The old one lets go while being disposed; the new one hears it after
    // that frame.
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(_controllerOf(tester, after), same(_modalController(tester)));
  });
}
