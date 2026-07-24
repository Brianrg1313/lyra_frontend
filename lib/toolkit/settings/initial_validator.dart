import 'package:core/navis/navis.dart';

// SERVICES
import 'package:app/toolkit/settings/initial_builder.dart';

Future<String?> initialValidator() async {
  final page = await clientService.resolve();
  final deepLink = Navis.consumePendingDeepLink();

  if (page != null) {
    return page;
  }

  if (deepLink != null) {
    return deepLink;
  }

  // TODO: cuando exista el concepto de negocio, separar el destino del cliente
  // que todavia no tiene uno.
  return "/home";
}
