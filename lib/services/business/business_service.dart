import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:provider/provider.dart';

import 'package:app/services/business/business_model.dart';
import 'package:app/services/business/business_profile_model.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/client/client_service.dart';
import 'package:app/toolkit/api.dart';

/// Estado de la carga del perfil de la empresa activa (`/business/profile/`).
enum BusinessProfileStatus { idle, loading, ready, error }

/// Estado de la carga de la gente de la empresa activa
/// (`/business/employees/`).
enum BusinessEmployeesStatus { idle, loading, ready, error }

/// Nombre del campo del formulario con el que viaja el logo. Lo decide el
/// backend: es el que lee su multipart, y con cualquier otro la peticion llega
/// sin archivo.
const String _kLogoField = "FILE";

/// Estado y comportamiento de las empresas del cliente.
///
/// Concentra toda la logica de empresas que antes vivia en [ClientService]: la
/// coleccion basica que llega en `/init` (para el selector del header), la
/// empresa activa, el alta de empresas y el perfil de la que este activa, que
/// es lo que muestra la seccion de empresas.
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

  /// Identificador de la empresa activa, o `null` si no hay ninguna (cliente sin
  /// empresas, o sesion cerrada).
  ///
  /// Es lo que miran los que quieren enterarse de un **cambio de empresa** y no
  /// del resto de las notificaciones del servicio (ver `BusinessListener` y el
  /// shell del home): a diferencia de [active], no asume que haya empresa, asi
  /// que se puede leer en cualquier momento.
  String? get activeId => _active?.id;

  /// Moneda en la que factura la empresa activa, ya resuelta contra el catalogo
  /// de plataforma: con simbolo, lado y decimales, que es lo que hace falta para
  /// escribir un precio.
  ///
  /// Sale de aca y no de cada pantalla porque es una sola para toda la app: es
  /// con la que se escriben los precios del catalogo, y cambiar de empresa
  /// cambia la moneda de todos ellos a la vez. A diferencia de [active], no
  /// asume que haya empresa: se lee al pintar, y sin empresa —o sin moneda
  /// declarada— contesta la de la app (ver [CurrencyCatalogService.resolve]).
  ///
  /// Se resuelve en cada lectura y no se guarda resuelta: el catalogo se puede
  /// releer con la app andando, y una moneda guardada aca seguiria escribiendo
  /// con el simbolo viejo.
  CurrencyModel get currency =>
    CurrencyCatalogService().resolve(currencyCode);

  /// El codigo de esa moneda, tal como lo guarda el backend (`""` si la empresa
  /// no declaro ninguna).
  ///
  /// Es lo que mira quien se suscribe a la moneda de la empresa y la resuelve
  /// contra el catalogo por su cuenta (ver `PriceCell`): asi se entera tanto de
  /// un cambio de empresa como de una relectura del catalogo, que son dos avisos
  /// de dos servicios distintos.
  String get currencyCode => _active?.currency ?? "";

  int get total => _businesses.length;
  bool get hasBusiness => _businesses.isNotEmpty;

  /// La empresa con ese identificador, o `null` si el cliente no tiene ninguna.
  ///
  /// La coleccion de `/init` son **todas** las empresas a las que el cliente
  /// tiene acceso, asi que esto tambien contesta lo otro que se le pregunta:
  /// si un id que llego por URL es de una empresa suya.
  BusinessModel? byId(String id) {
    for (final business in _businesses) {
      if (business.id == id) return business;
    }
    return null;
  }

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

    // Lo cargado es de la empresa que se acaba de dejar: los endpoints
    // contestan por la activa, asi que ahora no describe a nadie.
    _forgetLoaded();

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
      profile: profile,
      currency: data["CURRENCY"]?.toString().toUpperCase() ?? ""
    );

    _businesses = [..._businesses, _active!];
    useBusiness(_active!.id);

    // La empresa activa es otra, asi que el perfil cargado tampoco sirve.
    _forgetLoaded();

    notifyListeners();
  }

  // ─── Perfil (viene de /business/profile/) ───────────────────────────────────

  BusinessProfileStatus _profileStatus = BusinessProfileStatus.idle;
  BusinessProfileModel? _profile;

  /// Empresa a la que pertenece lo que hay cargado en [_profile]. El endpoint
  /// contesta por la activa, asi que un perfil sin saber de quien es no se
  /// puede validar contra la que se esta mirando.
  String? _profileOwner;

  BusinessProfileStatus get profileStatus => _profileStatus;

  /// Perfil de la empresa activa, o `null` si todavia no se cargo.
  BusinessProfileModel? get profile => _profile;

  /// Carga el perfil completo de la empresa activa.
  ///
  /// El endpoint no recibe un id: contesta por la empresa de la cabecera
  /// `business_id`, que es la activa. Ver el perfil de otra empresa es
  /// **elegirla** ([selectBusiness]) y volver a pedirlo; por eso lo cargado se
  /// tira cada vez que cambia la activa y no se cachea una empresa por otra.
  ///
  /// Se cachea igual que el detalle: mientras no cambie la empresa activa, las
  /// siguientes visitas al perfil no vuelven a pegarle al backend salvo que se
  /// pida [force].
  Future<void> loadProfile({bool force = false}) async {
    final id = activeId;

    // Sin empresa activa no hay perfil que pedir: el backend contestaria por
    // ninguna. La pantalla que lo muestra ya sabe que hacer sin empresa.
    if (id == null) return;

    if (_profileStatus == BusinessProfileStatus.loading) return;
    if (!force && _profileStatus == BusinessProfileStatus.ready) return;

    _profileOwner = id;
    _profileStatus = BusinessProfileStatus.loading;
    notifyListeners();

    final data = await api.get(path: "/business/profile/", version: "v1").catchError((E) {
      if (kDebugMode) {
        print(E);
      }
      return null;
    });

    // La activa pudo cambiar mientras se pedia: lo que llego describe a la
    // empresa anterior y guardarlo mostraria una en el lugar de la otra. La
    // carga de la nueva ya esta en curso o va a pedirse, asi que aca no queda
    // nada por hacer.
    if (_profileOwner != id) return;

    if (data is! Map) {
      _profileStatus = BusinessProfileStatus.error;
      notifyListeners();
      return;
    }

    _profile = BusinessProfileModel.fromJson(data);
    _profileStatus = BusinessProfileStatus.ready;

    notifyListeners();
  }

  // ─── Gente (viene de /business/employees/) ──────────────────────────────────

  BusinessEmployeesStatus _employeesStatus = BusinessEmployeesStatus.idle;
  int _employees = 0;

  /// Empresa a la que pertenece lo cargado en [_employees], por lo mismo que
  /// [_profileOwner]: el endpoint contesta por la activa.
  String? _employeesOwner;

  BusinessEmployeesStatus get employeesStatus => _employeesStatus;

  /// Cuanta gente entra a la empresa activa.
  int get employees => _employees;

  /// Carga la gente de la empresa activa.
  ///
  /// Hoy solo trae el numero: quienes son, con que rango y que puede hacer cada
  /// uno todavia no esta modelado del otro lado, asi que la lista llega vacia y
  /// aca no se guarda. Cuando existan, se leen de la misma respuesta.
  ///
  /// Este numero vivia en el perfil y se mudo: es de la gente de la empresa, no
  /// de su cedula de identidad, y quien abre la ficha para corregir el telefono
  /// no tiene por que pagar una cuenta que nadie esta mirando.
  ///
  /// Se cachea como el resto: mientras no cambie la empresa activa no se vuelve
  /// a pedir salvo que se pida [force].
  Future<void> loadEmployees({bool force = false}) async {
    final id = activeId;

    if (id == null) return;

    if (_employeesStatus == BusinessEmployeesStatus.loading) return;
    if (!force && _employeesStatus == BusinessEmployeesStatus.ready) return;

    _employeesOwner = id;
    _employeesStatus = BusinessEmployeesStatus.loading;
    notifyListeners();

    final data = await api.get(
      path: "/business/employees/",
      version: "v1"
    ).catchError((E) {
      if (kDebugMode) {
        print(E);
      }
      return null;
    });

    // La activa pudo cambiar mientras se pedia: lo que llego es de la anterior.
    if (activeId != id || _employeesOwner != id) return;

    if (data is! Map) {
      _employeesStatus = BusinessEmployeesStatus.error;
      notifyListeners();
      return;
    }

    _employees = int.tryParse("${data["total"]}") ?? 0;
    _employeesStatus = BusinessEmployeesStatus.ready;

    notifyListeners();
  }

  /// Cambia un dato del perfil de la empresa activa contra
  /// `PUT /business/profile/`.
  ///
  /// Se manda **un campo por vez**, y solo el que se toco: el perfil se corrige
  /// renglon por renglon desde su ficha, y reenviarlo entero seria reescribir
  /// con lo que tiene cargado esta pantalla —que puede ser de hace rato— todo
  /// lo que nadie cambio.
  ///
  /// El id de la empresa no viaja en el cuerpo: como en la lectura, el endpoint
  /// contesta por la de la cabecera `business_id`, o sea la activa.
  ///
  /// Un valor vacio **borra** el dato en vez de dejarlo como estaba: casi todo
  /// el perfil es opcional, asi que vaciar un campo es una edicion valida y no
  /// un olvido.
  ///
  /// Devuelve `true` si el cambio entro. Ante un error muestra la bandera
  /// flotante y devuelve `false`, con el perfil como estaba.
  Future<bool> editProfile(
    BuildContext context,
    String key,
    String value
  ) async {
    if (activeId == null) return false;

    try {
      await api.put(
        path: "/business/profile/",
        version: "v1",
        data: {key: value.trim()}
      );
    } catch (error) {
      if (kDebugMode) print("editProfile failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    await _reloadProfile();

    return true;
  }

  /// Cambia el logo de la empresa activa contra `POST /business/logo/`.
  ///
  /// [file] es el recorte que se hizo en pantalla, no la foto que eligio el
  /// cliente: que parte de la imagen queda dentro del cuadrado lo decide quien
  /// la sube (ver `CropImageModal`), porque es lo unico que el backend no puede
  /// adivinar. Del otro lado igual se la vuelve a codificar —a WebP, sin
  /// metadatos y con su version chica— asi que lo que se sirve nunca son los
  /// bytes que salieron de aca.
  ///
  /// No hay que borrar el logo anterior: lo hace el backend cuando el nuevo ya
  /// esta en su lugar. Como el resto de las escrituras, devuelve `true` si
  /// entro y ante un error muestra la bandera flotante y deja el logo como
  /// estaba.
  Future<bool> setLogo(BuildContext context, File file) async {
    if (activeId == null) return false;

    try {
      await api.file(
        path: "/business/logo/",
        version: "v1",
        file: file,
        field: _kLogoField
      );
    } catch (error) {
      if (kDebugMode) print("setLogo failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    await _reloadProfile();

    return true;
  }

  /// Agrega una direccion de correo a la empresa contra
  /// `POST /business/emails/`.
  ///
  /// La primera direccion de una empresa queda como la principal, la pida o no
  /// quien la agrega: una empresa cuyo unico correo no es el que publica no
  /// tiene sentido. Eso lo decide el backend.
  ///
  /// Devuelve `true` si entro. Ante un error muestra la bandera flotante y
  /// devuelve `false`, con la lista como estaba.
  Future<bool> addEmail(BuildContext context, Map<String, dynamic> data) =>
    _writeEmail(context, "addEmail", () => api.post(
      path: "/business/emails/",
      version: "v1",
      data: data
    ));

  /// Cambia una direccion de la empresa contra `PUT /business/emails/`.
  ///
  /// Solo cambia lo que se manda, asi que corregir un tipeo no obliga a
  /// reenviar el proposito y el nombre. `MAIN: true` la vuelve la principal y
  /// baja a la que lo era; bajar la principal sin promover otra lo rechaza el
  /// backend, porque una empresa con direcciones y sin principal no es un
  /// estado al que valga la pena poder llegar.
  Future<bool> editEmail(
    BuildContext context,
    String id,
    Map<String, dynamic> data
  ) => _writeEmail(context, "editEmail", () => api.put(
    path: "/business/emails/",
    version: "v1",
    data: {"ID": id, ...data}
  ));

  /// Borra una direccion de la empresa contra `DELETE /business/emails/`.
  ///
  /// Quien la llama tiene que haberlo preguntado antes: el servicio no
  /// pregunta. Borrar la principal esta permitido y asciende a la mas vieja de
  /// las que quedan.
  Future<bool> removeEmail(BuildContext context, String id) =>
    _writeEmail(context, "removeEmail", () => api.delete(
      path: "/business/emails/",
      version: "v1",
      data: {"ID": id}
    ));

  /// Pide el codigo con el que se verifica una direccion, contra
  /// `POST /business/emails/verify/`.
  ///
  /// Devuelve la direccion a la que se mando —la guardada, no la que se
  /// escribio en pantalla— para que la pantalla pueda decir a donde mirar; un
  /// `null` es que no se mando nada y el error ya se mostro.
  ///
  /// El backend rechaza pedir otro codigo antes del minuto: es la unica
  /// escritura de la ficha que le escribe a un correo que tipeo alguien, asi
  /// que "reenviar" sin freno seria un boton que manda correo tan rapido como
  /// se lo toque. Ese rechazo llega como cualquier otro error.
  ///
  /// No relee el perfil: pedir un codigo no cambia ningun dato de la empresa.
  Future<String?> sendEmailCode(BuildContext context, String id) async {
    if (activeId == null) return null;

    try {
      final sent = await api.post(
        path: "/business/emails/verify/",
        version: "v1",
        data: {"ID": id}
      );

      return sent?.toString();
    } catch (error) {
      if (kDebugMode) print("sendEmailCode failed: $error");

      if (context.mounted) _report(context, error);

      return null;
    }
  }

  /// Termina de verificar una direccion contra `PUT /business/emails/verify/`.
  ///
  /// El codigo lo leyo alguien en la casilla, que es justamente la prueba: lo
  /// que queda verificado es que la empresa lee esa direccion, no que la
  /// empresa sea quien dice ser (eso es su situacion legal, y no se toca desde
  /// aca).
  ///
  /// Relee el perfil como el resto de las escrituras de correos: el mismo
  /// codigo puede verificar mas de una fila —la misma casilla cargada con dos
  /// propositos es una sola casilla— asi que como queda la lista lo decide el
  /// backend.
  Future<bool> verifyEmail(
    BuildContext context,
    String id,
    String code
  ) => _writeEmail(context, "verifyEmail", () => api.put(
    path: "/business/emails/verify/",
    version: "v1",
    data: {"ID": id, "CODE": code}
  ));

  /// El cuerpo comun de las escrituras de correos: mandar, y si entro, releer
  /// el perfil.
  ///
  /// Se relee entero y no se parchea la lista en memoria porque una sola
  /// escritura toca mas de una fila: promover una direccion baja a la otra, y
  /// borrar la principal asciende a la siguiente. Quien decide como queda la
  /// lista es el backend, asi que se la vuelve a pedir.
  Future<bool> _writeEmail(
    BuildContext context,
    String name,
    Future<dynamic> Function() write
  ) async {
    if (activeId == null) return false;

    try {
      await write();
    } catch (error) {
      if (kDebugMode) print("$name failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    await _reloadProfile();

    return true;
  }

  /// Vuelve a leer el perfil sin pasar por `loading`.
  ///
  /// Es lo que corre despues de guardar: ahi el estado ya es `ready` y la ficha
  /// esta entera en pantalla, asi que mandarla a `loading` —como hace
  /// [loadProfile]— cambiaria toda la ficha por un spinner para reescribir un
  /// renglon.
  ///
  /// Se relee en vez de parchear lo que hay en memoria porque como queda
  /// guardado lo decide el backend: recorta, normaliza el idioma, pone el pais
  /// en mayusculas. Lo que se muestra es lo que quedo, no lo que se mando.
  ///
  /// Un error aca no se reporta: el cambio ya entro y la bandera diria lo
  /// contrario. La ficha se queda con el valor viejo hasta la proxima lectura.
  Future<void> _reloadProfile() async {
    final id = activeId;
    if (id == null) return;

    final data = await api.get(path: "/business/profile/", version: "v1").catchError((E) {
      if (kDebugMode) {
        print(E);
      }
      return null;
    });

    // Igual que en [loadProfile]: la activa pudo cambiar mientras se leia, y lo
    // que llego describe a la anterior.
    if (activeId != id || _profileOwner != id) return;
    if (data is! Map) return;

    _profile = BusinessProfileModel.fromJson(data);
    _syncActive(_profile!);

    notifyListeners();
  }

  /// Baja a la coleccion basica lo que del perfil tambien vive ahi.
  ///
  /// La de `/init` es la que alimenta el selector de empresas y la moneda con
  /// la que se escriben todos los precios de la app, y comparte tres datos con
  /// el perfil: el nombre, el logo y la moneda. Cambiarlos en la ficha y no aca
  /// dejaria a la misma empresa nombrada de dos maneras, con dos caras y
  /// cobrando en dos monedas —el logo recien subido en su ficha y la inicial en
  /// el selector, hasta el proximo arranque—.
  void _syncActive(BusinessProfileModel profile) {
    final index = _businesses.indexWhere(
      (business) => business.id == profile.id
    );

    if (index == -1) return;

    final current = _businesses[index];

    if (current.name == profile.name &&
      current.currency == profile.currency &&
      current.logo == profile.logo) {
      return;
    }

    final updated = current.copyWith(
      name: profile.name,
      currency: profile.currency,
      logo: profile.logo
    );

    _businesses = List<BusinessModel>.from(_businesses)..[index] = updated;

    if (_active?.id == updated.id) _active = updated;
  }

  /// Muestra el error de una escritura como lo muestra el resto de la app.
  ///
  /// Un error con `action` no es un aviso sino un desvio (verificar el correo,
  /// volver a entrar): se relanza para que lo atienda quien sabe navegar.
  void _report(BuildContext context, Object error) {
    if (error is Map && error["action"] != null) throw error["action"];

    FloatFlag.of(context).fromError(
      error is Map && error.isNotEmpty ? error : {"message": error.toString()}
    );
  }

  /// Tira lo que hay cargado de una empresa: su perfil y su gente. No notifica:
  /// lo llaman los que ya van a notificar por su cuenta (un cambio de empresa,
  /// un alta, el cierre de sesion).
  void _forgetLoaded() {
    _profile = null;
    _profileOwner = null;
    _profileStatus = BusinessProfileStatus.idle;

    _employees = 0;
    _employeesOwner = null;
    _employeesStatus = BusinessEmployeesStatus.idle;
  }

  void clear() {
    _businesses = const [];
    _active = null;
    useBusiness(null);
    _forgetLoaded();
    notifyListeners();
  }
}
