import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:core/form.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_email_model.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/screens/modals/business/verify_business_email/_verify_business_email.dart';

const _email = BusinessEmailModel(
  id: "22222222-2222-4222-8222-222222222222",
  email: "ventas@acme.test",
  purpose: BusinessEmailPurpose.sales
);

/// El modal con un servicio **sin empresa activa**: asi `sendEmailCode` corta
/// antes de salir a la red, que es lo unico que una prueba de widget no puede
/// hacer. Lo que se comprueba aca es lo otro: que el formulario se arma solo,
/// sin que nadie tenga que pedir el codigo primero.
Widget _app() => ChangeNotifierProvider<BusinessService>(
  create: (_) => BusinessService(),
  child: MaterialApp(
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
        child: VerifyBusinessEmailModal(email: _email)
      )));
    })
  )
);

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('abre pidiendo el codigo y esperando que lo escriban', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);

    // A donde hay que ir a buscar el codigo. Es lo primero que se lee: sin eso
    // el resto del modal no se puede completar.
    expect(find.text("ventas@acme.test"), findsOneWidget);
    expect(find.byType(CodeInput), findsOneWidget);
    expect(find.text("Verify"), findsOneWidget);

    // Y el reenvio arranca esperando: el backend rechaza otro codigo antes del
    // minuto, asi que el boton no existe hasta que sirva de algo.
    expect(find.text("Resend code in 1:00"), findsOneWidget);
    expect(find.text("Resend code"), findsNothing);

    // Descarga el modal: la cuenta regresiva es un `Timer` periodico y la
    // prueba no termina con uno vivo.
    await tester.pumpWidget(const SizedBox());
  });
}
