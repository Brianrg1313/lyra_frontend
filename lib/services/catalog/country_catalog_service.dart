import 'package:flutter/foundation.dart';

import 'package:app/services/catalog/country_model.dart';

/// Los paises en los que la plataforma opera.
///
/// Es uno de los dos catalogos de plataforma que llegan en `/init` (el otro es
/// [CurrencyCatalogService]) y se puebla desde ahi, en [ClientService.resolve],
/// antes de levantar el arbol: para cuando la primera pantalla se pinta ya esta
/// cargado y ningun formulario tiene que esperar a un future.
///
/// Es singleton porque el catalogo es uno solo para toda la app y no es de
/// nadie: no depende de la empresa activa —cambiar de empresa no cambia en que
/// paises opera la plataforma— ni del ciclo de vida de ninguna pantalla. Ademas
/// se registra en `initialBuilder` con `ChangeNotifierProvider.value` para poder
/// observarlo con `context.watch`, y por eso mismo no debe destruirlo el
/// provider.
///
/// El punto de que esto sea un catalogo y no un enumerado: habilitar una region
/// es una fila en `lyra_admin`.`countries`, y la app la ofrece en la proxima
/// lectura de `/init` —sin publicar una version nueva—. Por eso nadie deberia
/// escribir aca una lista de paises, ni dar por sentado que un codigo esta.
///
/// ```dart
/// // Para ofrecerlos en un formulario.
/// final countries = context.watch<CountryCatalogService>().countries;
///
/// // Para leer un codigo guardado.
/// final name = CountryCatalogService().nameOf(profile.country);
/// ```
class CountryCatalogService extends ChangeNotifier {
  //SINGLETON
  static final CountryCatalogService _singleton =
    CountryCatalogService._internal();

  factory CountryCatalogService() => _singleton;

  CountryCatalogService._internal();

  List<CountryModel> _countries = const [];

  /// Por codigo, para no recorrer la lista en cada lectura: la ficha de una
  /// empresa y cada fila de un listado preguntan por el suyo.
  Map<String, CountryModel> _byCode = const {};

  /// El catalogo entero, en el orden que lo manda el backend (alfabetico por el
  /// nombre de cada pais en su propio idioma).
  List<CountryModel> get countries => List.unmodifiable(_countries);

  /// Si el catalogo llego. Es lo que mira un formulario para decidir si puede
  /// ofrecer una lista o tiene que dejar escribir el codigo a mano: sin
  /// catalogo, un desplegable vacio deja el dato sin manera de cargarse.
  bool get isReady => _countries.isNotEmpty;

  int get total => _countries.length;

  /// El pais con ese codigo, o `null` si el catalogo no lo tiene (todavia no
  /// llego, o la region dejo de estar habilitada).
  CountryModel? byCode(String? code) {
    if (code == null || code.isEmpty) return null;
    return _byCode[code.trim().toUpperCase()];
  }

  /// Como se lee un codigo guardado: el nombre del pais, o el codigo crudo si
  /// el catalogo no lo tiene.
  ///
  /// Devolver el codigo y no un texto vacio es a proposito: el dato es de la
  /// empresa, y esconderlo porque esta app no sabe nombrarlo seria mostrar la
  /// ficha incompleta.
  String nameOf(String? code) =>
    byCode(code)?.name ?? code?.trim().toUpperCase() ?? "";

  /// La moneda nacional de un pais, para proponerla cuando se lo elige. Vacio
  /// si no se conoce el pais.
  String currencyOf(String? code) => byCode(code)?.currency ?? "";

  /// El pais al que pertenece un telefono guardado (`+584121234567` es
  /// Venezuela), o `null` si no empieza con `+` o si ningun codigo habilitado
  /// coincide.
  ///
  /// Gana el codigo mas largo que coincida y no el primero: `+1` es Estados
  /// Unidos y Canada, pero `+1868` no es ninguno de los dos. Es la unica forma
  /// de partir un telefono sin preguntarle a nadie de donde es.
  CountryModel? byPhone(String? phone) {
    final digits = phone?.trim() ?? "";
    if (!digits.startsWith("+")) return null;

    final number = digits.substring(1);
    CountryModel? match;

    for (final country in _countries) {
      if (country.phone.isEmpty) continue;
      if (!number.startsWith(country.phone)) continue;
      if (match != null && match.phone.length >= country.phone.length) continue;

      match = country;
    }

    return match;
  }

  /// Un telefono guardado partido en las dos cosas que se cargan por separado:
  /// el codigo del pais y el numero.
  ///
  /// Lo que no se reconoce queda entero en el numero —un telefono cargado sin
  /// codigo, o el de una region que se deshabilito—: se muestra tal como esta
  /// guardado en vez de atribuirselo a un pais que nadie eligio.
  ({String dial, String number}) splitPhone(String? phone) {
    final value = phone?.trim() ?? "";
    final country = byPhone(value);

    if (country == null) return (dial: "", number: value);

    return (
      dial: country.phone,
      number: value.substring(country.phone.length + 1)
    );
  }

  /// Puebla el catalogo con lo que trajo `/init`.
  ///
  /// Notifica igual aunque lo llamen antes de montar el arbol —ahi no hay quien
  /// escuche y no cuesta nada—, porque tambien lo llama la relectura del
  /// catalogo con la app ya andando (ver [ClientService.refreshCatalogs]), y en
  /// ese momento las pantallas abiertas tienen que enterarse.
  void seed(dynamic data) {
    _countries = CountryModel.fromResponse(data);
    _byCode = {for (final country in _countries) country.code: country};

    notifyListeners();
  }

  /// Vacia el catalogo. Para el cierre de sesion, junto al resto de los
  /// servicios: la proxima sesion lo vuelve a traer, y puede traerlo distinto.
  void clear() {
    _countries = const [];
    _byCode = const {};

    notifyListeners();
  }
}
