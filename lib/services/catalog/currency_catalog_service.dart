import 'package:flutter/foundation.dart';

import 'package:app/services/catalog/currency_model.dart';

/// Codigo de la moneda con la que se escribe un precio cuando no hay otra cosa
/// que decir: una empresa que todavia no declaro la suya, o una pantalla que
/// pinta antes de que el catalogo haya llegado.
///
/// Es lo unico de moneda que esta app da por sentado, y solo como ultimo
/// recurso: si el catalogo no la trae se escribe igual, con el codigo por
/// simbolo (ver [CurrencyModel.unknown]).
const String _kDefaultCurrency = "USD";

/// Las monedas en las que se puede escribir un precio, y **como se escribe cada
/// una**.
///
/// Es uno de los dos catalogos de plataforma que llegan en `/init` (el otro es
/// [CountryCatalogService]) y se puebla desde ahi, en [ClientService.resolve],
/// antes de levantar el arbol: para cuando la planilla de stock pinta su primera
/// celda de precio el catalogo ya esta cargado.
///
/// Es singleton por lo mismo que el de paises: es uno solo para toda la app, no
/// depende de la empresa activa —cada empresa elige la suya de esta lista, pero
/// la lista es la misma— ni del ciclo de vida de ninguna pantalla. Se registra
/// en `initialBuilder` con `ChangeNotifierProvider.value` para poder observarlo
/// con `context.watch`, y por eso mismo no debe destruirlo el provider.
///
/// Lo que importa: el simbolo, de que lado va, con cuantos decimales y si lleva
/// espacio son **datos del backend**, no un enumerado de esta app. Habilitar una
/// moneda, o corregirle el simbolo, es una fila en `lyra_admin`.`currencies`.
///
/// ```dart
/// // Para ofrecerlas en un formulario.
/// final options = context.watch<CurrencyCatalogService>().currencies;
///
/// // Para escribir un importe guardado. Siempre devuelve una moneda.
/// final price = CurrencyCatalogService().resolve(code).label("22.23");
/// ```
class CurrencyCatalogService extends ChangeNotifier {
  //SINGLETON
  static final CurrencyCatalogService _singleton =
    CurrencyCatalogService._internal();

  factory CurrencyCatalogService() => _singleton;

  CurrencyCatalogService._internal();

  List<CurrencyModel> _currencies = const [];

  /// Por codigo: cada celda de precio de una planilla pregunta por el suyo.
  Map<String, CurrencyModel> _byCode = const {};

  /// El catalogo entero, en el orden que lo manda el backend (las de curso
  /// legal primero, cada grupo alfabetico). Es el orden en que se ofrecen: lo
  /// que casi todos van a elegir no puede quedar debajo de lo que casi nadie.
  List<CurrencyModel> get currencies => List.unmodifiable(_currencies);

  /// Solo las de curso legal, para los formularios que no ofrecen cripto.
  List<CurrencyModel> get fiat => [
    for (final currency in _currencies) if (!currency.isCrypto) currency
  ];

  /// Si el catalogo llego. Lo mira un formulario para decidir si puede ofrecer
  /// una lista o tiene que dejar escribir el codigo a mano.
  bool get isReady => _currencies.isNotEmpty;

  int get total => _currencies.length;

  /// La moneda con ese codigo, o `null` si el catalogo no la tiene.
  ///
  /// Para escribir un importe se usa [resolve], que siempre devuelve una: aca el
  /// `null` significa "esta moneda no se puede elegir", que es otra pregunta.
  CurrencyModel? byCode(String? code) {
    if (code == null || code.isEmpty) return null;
    return _byCode[code.trim().toUpperCase()];
  }

  /// Con que moneda se escribe un importe guardado como [code]. **Siempre**
  /// devuelve una, porque un precio siempre hay que escribirlo:
  ///
  /// - La del catalogo, si esta.
  /// - Una armada con el codigo guardado, si el catalogo no la tiene (ver
  ///   [CurrencyModel.unknown]): se muestra `VES 22,23` y no `$22,23`, porque
  ///   ponerle otro simbolo seria mentir sobre el dato.
  /// - La de la app ([fallback]) cuando no hay codigo, que es el caso de una
  ///   empresa que todavia no declaro en que factura.
  CurrencyModel resolve(String? code) {
    final value = code?.trim().toUpperCase() ?? "";
    if (value.isEmpty) return fallback;

    return _byCode[value] ?? CurrencyModel.unknown(value);
  }

  /// La moneda con la que se escribe cuando no se declaro ninguna: el dolar si
  /// el catalogo lo trae —lo normal—, la primera de curso legal si no, y recien
  /// entonces una armada a mano.
  CurrencyModel get fallback =>
    _byCode[_kDefaultCurrency] ??
    (fiat.isNotEmpty ? fiat.first : CurrencyModel.unknown(_kDefaultCurrency));

  /// Puebla el catalogo con lo que trajo `/init`.
  ///
  /// Notifica igual aunque lo llamen antes de montar el arbol —ahi no hay quien
  /// escuche y no cuesta nada—, porque tambien lo llama la relectura del
  /// catalogo con la app ya andando (ver [ClientService.refreshCatalogs]): si
  /// una moneda cambio de simbolo, las celdas de precio abiertas tienen que
  /// enterarse.
  void seed(dynamic data) {
    _currencies = CurrencyModel.fromResponse(data);
    _byCode = {for (final currency in _currencies) currency.code: currency};

    notifyListeners();
  }

  /// Vacia el catalogo. Para el cierre de sesion, junto al resto de los
  /// servicios: la proxima sesion lo vuelve a traer, y puede traerlo distinto.
  void clear() {
    _currencies = const [];
    _byCode = const {};

    notifyListeners();
  }
}
