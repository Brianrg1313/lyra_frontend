// SERVICES
import 'package:app/services/files/cdn_service.dart';
import 'package:app/services/files/file_model.dart';

import 'catalog_table.dart';

/// Un pais en el que la plataforma opera, tal como lo lista `/init`.
///
/// La lista es del backend (`lyra_admin`.`countries`, solo los habilitados) y
/// no de esta app: habilitar una region es agregar una fila alla, y la app la
/// ofrece en la proxima sesion sin que haya que publicar una version nueva.
/// Por eso nada de esto es un enumerado.
///
/// Cada pais trae lo que hace falta para ofrecerlo y para llenar lo que se
/// deduce de el: como se llama en su propio idioma ([name]), su codigo
/// telefonico ([phone]), en que moneda factura ([currency]) y su bandera
/// ([flag]).
class CountryModel {
  const CountryModel({
    required this.code,
    required this.name,
    this.phone = "",
    this.currency = "",
    this.flag = ""
  });

  /// Codigo ISO 3166-1 alpha-2, en mayusculas. Es el valor que viaja al backend
  /// (`companies`.`country`).
  final String code;

  /// Nombre del pais en su propio idioma. No se traduce: llega escrito.
  final String name;

  /// Codigo telefonico, sin el `+`.
  final String phone;

  /// Codigo ISO 4217 de su moneda nacional. Es una sugerencia para los
  /// formularios —elegir pais propone su moneda—, no la moneda de la empresa:
  /// esa la elige quien la crea.
  final String currency;

  /// Id del icono de la bandera, o `""` si el pais todavia no tiene uno
  /// cargado. Es un archivo de la plataforma y no de una empresa, asi que se
  /// baja de [FileScope.assets]; la direccion se arma con [flagUrl].
  final String flag;

  factory CountryModel.fromJson(Map<String, dynamic> json) => CountryModel(
    code: json["code"]?.toString().trim().toUpperCase() ?? "",
    name: json["name"]?.toString().trim() ?? "",
    phone: json["phone"]?.toString().trim() ?? "",
    currency: json["currency"]?.toString().trim().toUpperCase() ?? "",
    flag: json["flag"]?.toString().trim() ?? ""
  );

  /// Los paises del catalogo, en el orden que los manda el backend (alfabetico
  /// por su nombre). Los que llegan sin codigo se descartan: el codigo es el
  /// dato que viaja, y una opcion que no se puede guardar no es una opcion.
  static List<CountryModel> fromResponse(dynamic data) {
    final countries = <CountryModel>[];

    for (final row in catalogRows(data)) {
      final country = CountryModel.fromJson(row);
      if (country.code.isNotEmpty) countries.add(country);
    }

    return countries;
  }

  /// El codigo telefonico como se escribe: `+58`. Vacio si el pais no lo trae.
  String get dial => phone.isEmpty ? "" : "+$phone";

  /// La direccion de la bandera, o `""` si el pais no tiene una —o si la base
  /// de las imagenes todavia no llego—. Vacia se lee como "sin bandera", que es
  /// una respuesta valida: el pais se ofrece igual, por su nombre.
  ///
  /// [width] pide una version chica. Una bandera se dibuja al lado de un
  /// renglon de texto, asi que casi siempre conviene pedirla.
  String flagUrl([int? width]) =>
    CdnService().url(FileScope.assets, flag, width: width);

  @override
  bool operator ==(Object other) =>
    other is CountryModel &&
    other.code == code &&
    other.name == name &&
    other.phone == phone &&
    other.currency == currency &&
    other.flag == flag;

  @override
  int get hashCode => Object.hash(code, name, phone, currency, flag);

  @override
  String toString() => "CountryModel($code)";
}
