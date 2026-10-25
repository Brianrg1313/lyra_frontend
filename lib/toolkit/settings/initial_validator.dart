import 'dart:async';
import 'package:core/navis/navis.dart';

// SERVICES
import 'package:app/toolkit/backend/deployment.dart';
import 'package:app/toolkit/lan/_lan.dart';
import 'package:app/toolkit/settings/initial_builder.dart';
import 'package:app/services/preferences/preferences_service.dart';

/// The first route (plan §7.4). Nothing is asked up front: a device paired with a master (or
/// that is one) and without a cloud session goes to its LAN landing, which starts or finds the
/// master (signing in is `/login`); a browser on a master's page that isn't paired yet can only
/// pair; a paired device signed in online enters `hybrid` when its master takes the session
/// (`HybridService.resume`); everything else is today's cloud path, whose sign in waits for the
/// backend's `/presence` socket (`CloudPresence`) and offers the master's when it doesn't connect.
Future<String?> initialValidator() async {
  if (Deployment.mode != DeploymentMode.cloud) return "/lan";

  if (lanServingMaster != null) return "/deployment/pair";

  // A device with a master signed in online: its master's session too when the master answers
  // (`hybrid`, plan §9.6), the cloud alone when it doesn't. Opening it starts the engine on the
  // master, which serves its LAN whichever session runs here: its other devices count on it.
  if (Deployment.paired != null && !await hybridService.resume() && Deployment.paired == DeploymentRole.master) {
    unawaited(lanService.server.start());
  }

  final page = await clientService.resolve();
  final deepLink = Navis.consumePendingDeepLink();

  if (page != null) {
    return page;
  }

  // A link to a route that no longer exists would leave the app on its loading screen (Navis
  // ignores a path it cannot match), like a recorded page does (`PreferencesService.homePath`).
  if (deepLink != null && Navis().match(deepLink) != null) {
    return deepLink;
  }

  return PreferencesService().homePath;
}
