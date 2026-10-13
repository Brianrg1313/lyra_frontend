import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/form.dart';
import 'package:core/kit/app_size.dart';
import 'package:core/kit/theme_color.dart';

import 'package:app/toolkit/theme/dark.dart';
import 'package:app/toolkit/theme/light.dart';

/// A shoe store's sizes, smallest first: the order the result has to keep.
final _sizes = [
  for (final size in const ["31", "32", "33", "34", "35", "36"])
    SelectOption(value: size, placeholder: size)
];

/// Opens the check list and returns where its answer lands once it closes.
Future<List<List<String>>> _open(
  WidgetTester tester, {
  List<String> checked = const [],
  Future<SelectOption?> Function(String name)? onCreate
}) async {
  final answers = <List<String>>[];

  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) {
      AppSize.instance(context);

      return Scaffold(body: Align(
        alignment: Alignment.topLeft,
        child: Builder(builder: (context) => GestureDetector(
          onTap: () async => answers.add(await showCheckMenu(
            context: context,
            options: _sizes,
            checked: checked,
            dense: true,
            createText: "Add size",
            onCreate: onCreate
          )),
          child: const Text("open")
        ))
      ));
    })
  ));

  await tester.tap(find.text("open"));
  await tester.pumpAndSettle();

  return answers;
}

/// Closes the check list the way it is closed: tapping outside it.
Future<void> _close(WidgetTester tester) async {
  await tester.tapAt(const Offset(780, 580));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    ThemeColor.light = lightScheme;
    ThemeColor.dark = darkScheme;
  });

  testWidgets('ticking does not close it, and closing answers what is ticked', (tester) async {
    final answers = await _open(tester);

    await tester.tap(find.text("36"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("31"));
    await tester.pumpAndSettle();

    // Still open after two taps.
    expect(find.text("33"), findsOneWidget);
    expect(answers, isEmpty);

    await _close(tester);

    // The list's order, not the taps'.
    expect(answers, [["31", "36"]]);
  });

  testWidgets('a ticked one is unticked', (tester) async {
    final answers = await _open(tester, checked: const ["32", "33"]);

    await tester.tap(find.text("32"));
    await tester.pumpAndSettle();
    await _close(tester);

    expect(answers, [["33"]]);
  });

  testWidgets('closing untouched answers what it had, unknown values included', (tester) async {
    final answers = await _open(tester, checked: const ["34", "XL"]);

    await _close(tester);

    expect(answers, [["34", "XL"]]);
  });

  testWidgets('a created option is added ticked and the list stays open', (tester) async {
    final answers = await _open(
      tester,
      onCreate: (name) async => SelectOption(value: name, placeholder: name)
    );

    await tester.tap(find.text("Add size"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), "37");
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(answers, isEmpty);
    expect(find.text("Add size"), findsOneWidget);

    await _close(tester);

    expect(answers, [["37"]]);
  });
}
