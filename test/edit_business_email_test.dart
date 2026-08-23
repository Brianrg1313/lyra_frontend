import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_email_model.dart';
import 'package:app/screens/modals/edit_business_email/_edit_business_email.dart';

Widget _app({BusinessEmailModel? email}) => MaterialApp(
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
      child: EditBusinessEmailModal(email: email)
    )));
  })
);

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('el alta abre vacia y en el proposito general', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("General"), findsOneWidget);
    expect(find.text("Save"), findsOneWidget);
  });

  testWidgets('la edicion abre con la direccion, el proposito y el nombre', (tester) async {
    await tester.pumpWidget(_app(email: const BusinessEmailModel(
      id: "11111111-1111-4111-8111-111111111111",
      email: "pagos@acme.test",
      purpose: BusinessEmailPurpose.billing,
      label: "Facturacion Colombia"
    )));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("pagos@acme.test"), findsOneWidget);
    expect(find.text("Facturacion Colombia"), findsOneWidget);

    // Lo que se elige se muestra con su etiqueta y no con el codigo que viaja.
    expect(find.text("Billing"), findsOneWidget);
    expect(find.text("billing"), findsNothing);
  });
}
