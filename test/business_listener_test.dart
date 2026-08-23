import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:app/screens/home/sections/business_listener.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/toolkit/api.dart';

/// Tabla columnar como la que manda `/init`.
final _table = {
  "keys": ["id", "name"],
  "values": [
    ["1842", "Bodega"],
    ["77", "Kiosco"]
  ]
};

/// El servicio real, con una puerta para notificar sin cambiar de empresa: es
/// lo que hace al cargar el detalle o al fallar una lectura.
class _Business extends BusinessService {
  void ping() => notifyListeners();
}

/// Pantalla minima que solo anota las empresas de las que se entera.
class _Screen extends StatefulWidget {
  const _Screen({required this.onChanged});

  final void Function(String businessId) onChanged;

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> with BusinessListener<_Screen> {
  @override
  void onBusinessChanged(String businessId) => widget.onChanged(businessId);

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  tearDown(() => useBusiness(null));

  Future<List<String>> pump(WidgetTester tester, _Business service) async {
    final seen = <String>[];

    await tester.pumpWidget(ChangeNotifierProvider<BusinessService>.value(
      value: service,
      child: _Screen(onChanged: seen.add)
    ));

    return seen;
  }

  testWidgets('la pantalla se entera de la empresa que se acaba de elegir',
      (tester) async {
    final service = _Business()..seed(_table);
    final seen = await pump(tester, service);

    service.selectBusiness("77");

    expect(seen, ["77"]);
  });

  testWidgets('una notificacion que no cambia la empresa no avisa',
      (tester) async {
    // El servicio notifica por todo (el alta de una empresa, la carga del
    // detalle): sin comparar contra la ultima empresa vista, cada una de esas
    // volveria a disparar la pantalla.
    final service = _Business()..seed(_table);
    final seen = await pump(tester, service);

    service.ping();
    service.selectBusiness("1842");
    service.selectBusiness("desconocida");

    expect(seen, isEmpty);
  });

  testWidgets('quedarse sin empresa no cuenta como cambio', (tester) async {
    // Es el cierre de sesion, y de esa navegacion se encarga quien lo dispara.
    final service = _Business()..seed(_table);
    final seen = await pump(tester, service);

    service.clear();

    expect(seen, isEmpty);
  });

  testWidgets('una pantalla desmontada deja de escuchar', (tester) async {
    final service = _Business()..seed(_table);
    final seen = await pump(tester, service);

    await tester.pumpWidget(const SizedBox());
    service.selectBusiness("77");

    expect(seen, isEmpty);
  });
}
