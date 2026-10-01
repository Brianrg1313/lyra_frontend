import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/screens/authentication/_authentication.dart';

/// The sign in is drawn only while our backend answers: without it nothing on the form can work,
/// so a placeholder takes its place, and "try again" asks once more. Pumped wide: the test font's
/// square glyphs overflow the auth footer's links at a narrower window.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  Future<void> pump(WidgetTester tester, Future<bool> Function() reachable, ) async {
    tester.view.physicalSize = const Size(1600, 900);
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

        return Authentication(reachable: reachable);
      })
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('with the backend answering, the sign in as always', (tester) async {
    await pump(tester, () async => true);

    expect(tester.takeException(), isNull);
    expect(find.text(S.current.auth_title), findsOneWidget);
    expect(find.text(S.current.auth_offline_title), findsNothing);
  });

  testWidgets('without it, the placeholder instead of the form', (tester) async {
    await pump(tester, () async => false);

    expect(tester.takeException(), isNull);
    expect(find.text(S.current.auth_offline_title), findsOneWidget);
    expect(find.text(S.current.auth_title), findsNothing);
  });

  testWidgets('while asking it shows neither, and "try again" asks once more', (tester) async {
    final answers = <Completer<bool>>[];
    await pump(tester, () {
      answers.add(Completer());
      return answers.last.future;
    });

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
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(S.current.auth_title), findsOneWidget);
  });
}
