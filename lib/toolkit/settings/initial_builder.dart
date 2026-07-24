import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';
import 'package:app/services/client/client_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';

/// Instancia unica del cliente.
///
/// Vive aca y no dentro del provider porque `initialValidator` corre fuera del
/// arbol de widgets, sin BuildContext, y necesita cargar la sesion sobre la
/// misma instancia que despues consumen las pantallas.
final clientService = ClientService();

/// Instancia unica de las empresas.
///
/// Vive junto al cliente y por el mismo motivo: `ClientService.resolve` la puebla
/// desde `/init` antes de levantar el arbol, sobre la misma instancia que
/// consumen el selector del side bar y la seccion de empresas.
final businessService = BusinessService();

// Wraps the whole app before it is handed to MaterialApp.
//
// Only services whose state must outlive navigation belong here. Flow scoped
// services (sign in / sign up) are provided by their own screens so the app
// does not register them while those flows are not in use.
Widget initialBuilder(Widget app) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => HomeService()),
    // `.value` porque el ciclo de vida de la instancia es de este archivo, no
    // del provider: no debe destruirse si el arbol se re-monta.
    ChangeNotifierProvider.value(value: clientService),
    ChangeNotifierProvider.value(value: businessService),
    // El estado (la cache del listado) debe sobrevivir a la navegacion entre el
    // listado de tablas y la pantalla de creacion, asi que vive en el scope de
    // la app y no en la seccion.
    ChangeNotifierProvider(create: (_) => TablesService())
  ],
  child: app
);
