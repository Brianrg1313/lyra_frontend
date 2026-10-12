import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';

/// `ModalSteps` moves only with its buttons: next asks the step's `validate`
/// and stays on `false`, the last step runs `onFinish` instead, and back on
/// the first step closes the modal.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  Future<void> pumpSteps(
    WidgetTester tester, {
    required bool Function() validate,
    required void Function() onFinish,
    int initialStep = 0
  }) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      AppSize.instance(context);

      return Material(child: Center(child: FilledButton(
        // The desktop dialog `showStepModal` opens (it asks the device first,
        // which a test has not got).
        onPressed: () => showDialog(
          context: context,
          builder: (_) => Dialog(child: ModalSteps(
            initialStep: initialStep,
            nextText: "Next",
            backText: "Back",
            cancelText: "Cancel",
            finishText: "Finish",
            stepLabel: (step, count) => "Step $step of $count",
            onFinish: onFinish,
            steps: [
              ModalStep(
                title: "First",
                image: const ColoredBox(color: Color(0xFF336699)),
                validate: validate,
                builder: (_) => const SizedBox(height: 40)
              ),
              ModalStep(title: "Second", builder: (_) => const SizedBox(height: 40))
            ]
          ))
        ),
        child: const SizedBox()
      )));
    })));

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
  }

  testWidgets("next stays on a step whose validate refuses", (tester) async {
    await pumpSteps(tester, validate: () => false, onFinish: () {});

    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("Step 1 of 2"), findsOneWidget);
    expect(find.text("Cancel"), findsOneWidget);
  });

  testWidgets("next moves on, the last step finishes, back returns", (tester) async {
    var finished = 0;
    await pumpSteps(tester, validate: () => true, onFinish: () => finished++);

    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();

    expect(find.text("Finish"), findsOneWidget);
    expect(find.text("Back"), findsOneWidget);

    await tester.tap(find.text("Finish"));
    await tester.pumpAndSettle();
    expect(finished, 1);

    await tester.tap(find.text("Back"));
    await tester.pumpAndSettle();
    expect(find.text("Next"), findsOneWidget);
  });

  testWidgets("cancel on the first step closes the modal", (tester) async {
    await pumpSteps(tester, validate: () => true, onFinish: () {});

    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();

    expect(find.byType(ModalSteps), findsNothing);
  });

  testWidgets("it opens on the initial step, with back to the one before", (tester) async {
    await pumpSteps(tester, validate: () => true, onFinish: () {}, initialStep: 1);

    expect(find.text("Finish"), findsOneWidget);
    expect(find.text("Back"), findsOneWidget);
  });
}
