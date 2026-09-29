import 'package:core/navis/navis.dart';

// SERVICES
import 'package:app/toolkit/settings/initial_builder.dart';
import 'package:app/services/preferences/preferences_service.dart';

Future<String?> initialValidator() async {
  final page = await clientService.resolve();
  final deepLink = Navis.consumePendingDeepLink();

  if (page != null) {
    return page;
  }

  if (deepLink != null) {
    return deepLink;
  }

  return PreferencesService().homePath;
}
