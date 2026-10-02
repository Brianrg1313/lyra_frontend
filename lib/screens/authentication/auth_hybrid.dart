import 'package:flutter/widgets.dart';

// SERVICES
import 'package:app/toolkit/settings/initial_builder.dart' show hybridService;
import 'package:app/services/lan/hybrid_service.dart';

// WIDGETS
import 'package:app/screens/modals/server/master_password/_master_password.dart';

/// After an online sign in as [login]: on a device with a master, the person's session there too
/// (plan §9.6, D14), reusing [password] when the sign in was by password, or asking for it once.
/// Nothing on a device without one, or whose master doesn't answer: the app runs online only.
Future<void> joinMaster(BuildContext context, String login, {String? password}) async {
  final joined = await hybridService.join(login, password: password);

  if (joined == HybridJoin.needsPassword && context.mounted) await showMasterPassword(context, login: login);
}
