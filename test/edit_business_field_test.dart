import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/screens/modals/business/edit_business_field/_edit_business_field.dart';
import 'package:app/screens/modals/business/edit_business_field/business_field.dart';

Widget _app(String label, BusinessField field) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: Builder(builder: (context) {
    AppSize.instance(context);

    return Scaffold(body: Center(child: SingleChildScrollView(
      child: EditBusinessFieldModal(label: label, field: field)
    )));
  })
);

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('un dato que se escribe se abre con lo que hay guardado', (tester) async {
    await tester.pumpWidget(_app(
      "Legal name",
      const BusinessField.text(
        key: "LEGAL_NAME",
        value: "Acme, C.A.",
        min: 3,
        max: 100,
        obligatory: true
      )
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("Acme, C.A."), findsOneWidget);
    expect(find.text("Save"), findsOneWidget);
  });

  // Los datos que se eligen de una lista no pasan por este modal: se cambian
  // en su propia fila de la ficha, sin abrir nada (ver `ProfileSelectField`).
  // Que se lean con su etiqueta y no con el codigo que viaja al backend se
  // comprueba ahi, en `business_profile_view_test.dart`.
}
