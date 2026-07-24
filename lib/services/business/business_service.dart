import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:provider/provider.dart';

import 'package:app/services/business/business_model.dart';
import 'package:app/services/business/business_detail_model.dart';
import 'package:app/services/client/client_service.dart';
import 'package:app/toolkit/api.dart';

/// Estado de la carga del detalle de empresas (`/business/list/`).
enum BusinessListStatus { idle, loading, ready, empty, error }

/// Estado y comportamiento de las empresas del cliente.
///
/// Concentra toda la logica de empresas que antes vivia en [ClientService]: la
/// coleccion basica que llega en `/init` (para el selector del side bar), la
/// empresa activa, el alta de empresas y la carga del detalle que consume la
/// seccion de empresas.
///
/// Se registra en el scope mas alto de la app (`initialBuilder`) con
/// `ChangeNotifierProvider.value` porque su estado debe sobrevivir a la
/// navegacion entre secciones.
class BusinessService extends ChangeNotifier {
  // ─── Coleccion basica (viene de /init) ──────────────────────────────────────

  List<BusinessModel> _businesses = const [];

  /// Empresa activa. Cada vez que cambia hay que pasarla por [useBusiness]:
  /// viaja como cabecera en todas las peticiones, asi que este es el unico
  /// lugar que sabe a que empresa le esta hablando la app.
  BusinessModel? _active;

  List<BusinessModel> get businesses => List.unmodifiable(_businesses);

  /// Empresa activa: la que eligio el cliente o, por defecto, la primera que
  /// devolvio la sesion.
  BusinessModel get active {
    assert(_active != null, "BusinessService leido sin una empresa creada");
    return _active!;
  }

  int get total => _businesses.length;
  bool get hasBusiness => _businesses.isNotEmpty;

  /// Puebla la coleccion basica desde la tabla columnar de `/init`. Lo llama
  /// [ClientService.resolve] al levantar la sesion, antes de montar el arbol,
  /// por eso no notifica: todavia no hay quien escuche.
  void seed(dynamic table) {
    _businesses = BusinessModel.fromTable(table);
    _active = _businesses.isEmpty ? null : _businesses.first;
    useBusiness(_active?.id);
  }

  /// Cambia la empresa activa. Ignora identificadores desconocidos.
  void selectBusiness(String id) {
    final index = _businesses.indexWhere((business) => business.id == id);
    if (index == -1 || _active?.id == id) return;

    _active = _businesses[index];
    useBusiness(_active!.id);

    notifyListeners();
  }

  /// Crea la empresa y la deja como la activa del cliente.
  ///
  /// El endpoint solo devuelve el identificador, asi que el resto del modelo se
  /// arma con lo que se envio en [data] y con el perfil de la sesion actual.
  Future<void> createBusiness(BuildContext context, Map<String, dynamic> data) async {
    final profile = context.read<ClientService>().username;

    final id = await api.post(path: "/business/create/", version: "v1", data: data)
      .catchError((E) {
        if (E is Map) {
          if (!context.mounted) return;

          if (E["action"] != null) throw E["action"];

          FloatFlag.of(context).fromError(E);
        }
      });

    if (id == null) throw "";

    _active = BusinessModel(
      id: id.toString(),
      name: data["LEGAL_NAME"] ?? "",
      activity: data["ACTIVITY_TYPE"] ?? "",
      profile: profile
    );

    _businesses = [..._businesses, _active!];
    useBusiness(_active!.id);

    // El detalle en cache ya no refleja la coleccion real: se recarga la proxima
    // vez que se abra la seccion.
    _status = BusinessListStatus.idle;

    notifyListeners();
  }

  // ─── Detalle (viene de /business/list/) ─────────────────────────────────────

  BusinessListStatus _status = BusinessListStatus.idle;
  List<BusinessDetailModel> _details = const [];

  BusinessListStatus get status => _status;
  List<BusinessDetailModel> get details => List.unmodifiable(_details);

  /// Carga el detalle de las empresas del cliente.
  ///
  /// Se cachea: una vez cargado, las siguientes visitas a la seccion no vuelven
  /// a pegarle al backend salvo que se pida [force] (o que un alta invalide la
  /// cache dejando el estado en `idle`).
  Future<void> loadDetails({bool force = false}) async {
    if (_status == BusinessListStatus.loading) return;
    if (!force && _status == BusinessListStatus.ready) return;

    _status = BusinessListStatus.loading;
    notifyListeners();

    final data = await api.get(path: "/business/list/", version: "v1").catchError((E) {
      if (kDebugMode) {
        print(E);
      }
      return null;
    });

    if (data == null) {
      _status = BusinessListStatus.error;
      notifyListeners();
      return;
    }

    _details = BusinessDetailModel.fromResponse(data);
    _status = _details.isEmpty
      ? BusinessListStatus.empty
      : BusinessListStatus.ready;

    notifyListeners();
  }

  void clear() {
    _businesses = const [];
    _active = null;
    useBusiness(null);
    _details = const [];
    _status = BusinessListStatus.idle;
    notifyListeners();
  }
}
