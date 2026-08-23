import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/screens/modals/create_table/_create_table.dart';

void main() {
  testWidgets('CreateTableModal renders without overflow and opens the template dropdown', (tester) async {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFffffff));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));

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
        return Scaffold(
          body: Center(child: SingleChildScrollView(child: CreateTableModal()))
        );
      })
    ));

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Template'), findsOneWidget);

    // Abre el desplegable de plantillas y elige "Clothing".
    await tester.tap(find.text('Blank template'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('Clothing'), findsOneWidget);
    await tester.tap(find.text('Clothing'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
