import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:app/toolkit/api.dart';

// SERVICE
import 'package:app/services/database/database_service.dart';

class ClientSingleton {
  // SINGLETON
  static final ClientSingleton _singleton = ClientSingleton._internal();
  factory ClientSingleton() => _singleton;
  ClientSingleton._internal();

  final _database = DatabaseService();

  Future<bool> validate() async {
    final token = await _database.fromSecure<String>(api.current.tokenName);

    // TODO: siempre deberia varificar que el token es correcto

    if (token == null) {
      final newToken = await api.get(path: "/identify_me/", version: "v1").catchError((E) {
        if (kDebugMode) {
          print(E);
        }
        return null;
      });

      if (newToken == null) {
        return false;
      } else {
        api.token = newToken;
        _database.toSecure(api.current.tokenName, newToken);
        return true;
      }
    } else {
      return true;
    }
  }
}
