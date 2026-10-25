import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/business/business_service.dart';
import 'package:app/toolkit/backend/api.dart';

/// Tabla columnar como la que manda `/init`.
final _table = {
  "keys": ["id", "name"],
  "values": [
    ["1842", "Bodega"],
    ["77", "Kiosco"]
  ]
};

void main() {
  tearDown(() => useBusiness(null));

  test('la empresa activa viaja en las dos apis', () {
    // La cabecera la ponen las apis solas: ninguna pantalla tiene que
    // acordarse de mandar la empresa en cada peticion.
    BusinessService().seed(_table);

    expect(api.business, "1842");
    expect(assets.business, "1842");
  });

  test('cambiar de empresa cambia la cabecera', () {
    final service = BusinessService()..seed(_table);

    service.selectBusiness("77");

    expect(api.business, "77");
    expect(assets.business, "77");
  });

  test('la empresa va en la cabecera business_id', () {
    // El backend la espera con ese nombre exacto: si cambia, deja de
    // reconocer a que empresa apunta la peticion.
    BusinessService().seed(_table);

    expect(api.extraHeaders, {"business_id": "1842"});
    expect(assets.extraHeaders, {"business_id": "1842"});
  });

  test('sin empresa la cabecera no aparece', () {
    useBusiness(null);

    expect(api.extraHeaders.containsKey("business_id"), isFalse);
  });

  test('sin empresas no viaja la cabecera', () {
    // Cliente recien registrado: todavia no creo ninguna empresa.
    BusinessService().seed({"keys": ["id", "name"], "values": []});

    expect(api.business, isNull);
    expect(assets.business, isNull);
  });

  test('cerrar sesion suelta la empresa', () {
    // Si quedara puesta, la sesion siguiente arrancaria pidiendo datos de la
    // empresa del cliente anterior.
    final service = BusinessService()..seed(_table);
    service.clear();

    expect(api.business, isNull);
    expect(assets.business, isNull);
  });
}
