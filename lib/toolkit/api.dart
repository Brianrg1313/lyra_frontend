import 'package:core/api.dart';

// SERVICES
import 'package:app/services/database/database_service.dart';

// WIDGETS
export 'package:core/float_flag/controller.dart';


final api = _Api();
final assets = _Assets();

class _Api extends RestAPI {
  @override
  ApiModel get dev => ApiModel(
    host: "192.168.1.102",
    name: "lyra",
    port: 80,
    scheme: "http",
    tokenName: "Authorization"
  );

  @override
  ApiModel get prod => dev;

  final _database = DatabaseService();

  @override
  Future<void> preRequest() async {
    if (token == null) {
      final t = await _database.fromSecure<String>(current.tokenName);
      if (t != null) {
        token = t;
        headers[current.tokenName] = token!;
      }
    }
  }
}

class _Assets extends RestAPI {
  @override
  ApiModel get dev => ApiModel(
    host: "192.168.1.102",
    name: "cetus",
    port: 81,
    scheme: "http",
    type: ApiMode.assets,
    tokenName: "Authorization"
  );

  @override
  ApiModel get prod => dev;

  final _database = DatabaseService();

  @override
  Future<void> preRequest() async {
    if (token == null) {
      final t = await _database.fromSecure<String>(current.tokenName);
      if (t != null) {
        token = t;
        headers[current.tokenName] = token!;
      }
    }
  }
}
