import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/screens/home/sections/business/business_detail/employees/_employees.dart';

/// El servicio con la lectura ya contestada: la pestana solo mira lo que hay
/// cargado, y pedirlo de verdad seria pegarle al backend.
class _Business extends BusinessService {
  _Business({
    this.employeesStatus = BusinessEmployeesStatus.ready,
    this.count = 0
  });

  @override
  BusinessEmployeesStatus employeesStatus;

  /// Se llama asi y no `total` porque el servicio ya tiene uno: el de las
  /// empresas del cliente.
  final int count;

  /// Cuantas veces se pidio la cuenta.
  int asked = 0;

  @override
  int get employees => count;

  @override
  Future<void> loadEmployees({bool force = false}) async => asked++;
}

Widget _app(BusinessService service) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: ChangeNotifierProvider<BusinessService>.value(
    value: service,
    child: Builder(builder: (context) {
      AppSize.instance(context);

      return const Scaffold(body: BusinessEmployeesTab());
    })
  )
);

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('la pestana pide la cuenta al abrirse', (tester) async {
    final service = _Business(employeesStatus: BusinessEmployeesStatus.idle);

    await tester.pumpWidget(_app(service));
    // Sin `pumpAndSettle`: mientras se pide, la pestana muestra el indicador de
    // carga, que nunca deja de animarse.
    await tester.pump();

    expect(service.asked, 1);
  });

  testWidgets('la cuenta se muestra con el aviso de lo que falta', (tester) async {
    await tester.pumpWidget(_app(_Business(count: 4)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("4"), findsOneWidget);
    expect(find.text("People with access"), findsOneWidget);
    expect(find.text("Coming soon"), findsOneWidget);
  });
}
