import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/files/file_model.dart';
import 'package:app/services/business/business_profile_model.dart';
import 'package:app/screens/home/sections/business/business_avatar.dart';
import 'package:app/screens/home/sections/business/settings/profile_logo.dart';

BusinessProfileModel _profile({FileModel? logo}) => BusinessProfileModel(
  id: "550e8400-e29b-41d4-a716-446655440000",
  name: "Acme",
  logo: logo
);

Widget _app(BusinessProfileModel profile) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: Builder(builder: (context) {
    AppSize.instance(context);

    return Scaffold(body: Center(child: SizedBox(
      width: 240,
      child: BusinessProfileLogo(profile: profile)
    )));
  })
);

/// Que dice el boton de la foto que va a pasar si se lo toca. Es lo unico que
/// nombra la accion: la tarjeta es la imagen y nada mas.
String? _action(WidgetTester tester) =>
  tester.widget<FeedbackButton>(find.byType(FeedbackButton)).message;

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('sin logo la accion es cargar el primero', (tester) async {
    await tester.pumpWidget(_app(_profile()));
    await tester.pump();

    expect(tester.takeException(), isNull);

    // La empresa sin logo se dibuja con su avatar, que es lo mismo que se ve
    // en el listado: no hay un hueco esperando una foto.
    expect(find.byType(BusinessAvatar), findsOneWidget);

    // La foto no lleva texto encima: lo que se puede hacer con ella lo dice su
    // boton, que es lo que leen el tooltip y el lector de pantalla.
    expect(_action(tester), "Add logo");
  });

  testWidgets('con logo la accion es cambiarlo', (tester) async {
    await tester.pumpWidget(_app(_profile(logo: const FileModel(
      id: "11111111-1111-4111-8111-111111111111",
      variants: [128]
    ))));
    await tester.pump();

    expect(_action(tester), "Change logo");
  });
}
