import 'dart:async';
import 'package:core/navis/navis.dart';

// SERVICES
import 'package:app/toolkit/deployment.dart';
import 'package:app/toolkit/lan.dart';
import 'package:app/toolkit/settings/initial_builder.dart';
import 'package:app/services/preferences/preferences_service.dart';

/// The first route (plan §7.4). Nothing is asked up front: a device paired with a master (or
/// that is one) and without a cloud session goes to its LAN landing, which starts or finds the
/// master (signing in is `/login`); a browser on a master's page that isn't paired yet can only
/// pair; everything else is today's cloud path, whose sign in waits for the backend to answer
/// (`cloudReachable`) and offers the master's when it doesn't.
Future<String?> initialValidator() async {
  if (Deployment.mode != DeploymentMode.cloud) return "/lan";

  // The master signed in to the cloud still serves its LAN: its other devices count on it.
  if (Deployment.paired == DeploymentRole.master) unawaited(lanService.server.start());

  if (lanServingMaster != null) return "/deployment/pair";

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
