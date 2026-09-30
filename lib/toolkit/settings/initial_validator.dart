import 'package:core/navis/navis.dart';

// SERVICES
import 'package:app/toolkit/deployment.dart';
import 'package:app/toolkit/settings/initial_builder.dart';
import 'package:app/services/preferences/preferences_service.dart';

/// The first route (plan §7.4). A LAN build asks a fresh install how it will be used; an
/// install in `local` mode goes to its LAN landing, which starts or finds the master and signs
/// in there. Everything else is today's cloud path, unchanged.
Future<String?> initialValidator() async {
  if (Deployment.lanEnabled && !Deployment.chosen) return "/deployment";
  if (Deployment.mode != DeploymentMode.cloud) return "/lan";

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
