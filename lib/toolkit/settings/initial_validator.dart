import 'package:app/services/client/client_service.dart';
import 'package:core/navis/navis.dart';

Future<String?> initialValidator() async {
  final client = ClientSingleton();

  final status = await client.validate();

  final deepLink = Navis.consumePendingDeepLink();

  if (status) {
    if (deepLink != null) {
      return deepLink;
    } else {
      return "/home";
    }
  } else {
    return "/login";
  }
}