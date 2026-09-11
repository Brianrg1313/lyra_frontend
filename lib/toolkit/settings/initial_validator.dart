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

  // TODO: once the business concept exists, split off the destination for a
  // client that does not have one yet.
  return "/home";
}
