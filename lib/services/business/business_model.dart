// SERVICES
import 'package:app/services/files/file_model.dart';

class BusinessModel {
  final String id;
  final String name;
  final String caption;

  /// Logo de la empresa, o `null` si todavia no subio ninguno. Es el mismo
  /// archivo que devuelve el perfil ([FileModel]): trae su id y con que tamanos
  /// existe, y la direccion se arma con la base que entrego `/init`.
  ///
  /// Viene en `/init` con el nombre y la leyenda porque es con lo que se dibuja
  /// una empresa: el selector del header la muestra apenas se levanta la app, y
  /// sin el logo aca habria que pedir el perfil de cada empresa para pintar una
  /// lista de cinco.
  final FileModel? logo;

  /// Solo llegan al crear la empresa desde la app; `/init` no los devuelve y
  /// quedan vacios para las empresas que vienen de la sesion.
  final String activity;
  final String profile;

  /// Codigo de la moneda en la que factura la empresa (ISO 4217), tal como lo
  /// guarda el backend. Con ella se escriben los precios de su catalogo.
  ///
  /// Se guarda el codigo crudo y no la moneda ya resuelta a proposito: como se
  /// escribe un importe lo dice el catalogo de `/init`
  /// ([CurrencyCatalogService]), que se puede releer con la app andando. Guardar
  /// aca la moneda resuelta dejaria a la empresa escribiendo sus precios con un
  /// simbolo viejo hasta el proximo arranque. Vacio si la empresa todavia no
  /// declaro ninguna: la resuelve [BusinessService.currency].
  final String currency;

  const BusinessModel({
    required this.id,
    required this.name,
    this.caption = "",
    this.logo,
    this.activity = "",
    this.profile = "",
    this.currency = "",
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json["id"]?.toString() ?? "",
      name: json["name"] ?? "",
      caption: json["caption"] ?? "",
      logo: FileModel.from(json["logo"]),
      activity: json["activity"] ?? "",
      profile: json["profile"] ?? "",
      currency: json["currency"]?.toString().trim().toUpperCase() ?? "",
    );
  }

  /// Decodifica la tabla columnar de `/init`:
  /// `{"keys": ["id", "name", "caption"], "values": [[...], ...]}`.
  ///
  /// Las columnas se leen por nombre y no por posicion, asi que el backend
  /// puede reordenarlas o agregar campos sin romper el parseo.
  static List<BusinessModel> fromTable(dynamic table) {
    if (table is! Map) return const [];

    final keys = table["keys"];
    final rows = table["values"];

    if (keys is! List || rows is! List) return const [];

    return [
      for (final row in rows)
        if (row is List)
          BusinessModel.fromJson({
            for (int i = 0; i < keys.length && i < row.length; i++)
              keys[i].toString(): row[i]
          })
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "caption": caption,
      "activity": activity,
      "profile": profile,
      "currency": currency,
    };
  }

  /// Centinela de [copyWith] para el logo. El resto de los campos son texto y
  /// "no lo toques" se dice con `null`, pero el logo puede **ser** `null`: una
  /// empresa que borra el suyo se quedaria con el viejo en el selector si las
  /// dos cosas se dijeran igual.
  static const Object _keep = Object();

  BusinessModel copyWith({
    String? id,
    String? name,
    String? caption,
    Object? logo = _keep,
    String? activity,
    String? profile,
    String? currency,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      name: name ?? this.name,
      caption: caption ?? this.caption,
      logo: identical(logo, _keep) ? this.logo : logo as FileModel?,
      activity: activity ?? this.activity,
      profile: profile ?? this.profile,
      currency: currency ?? this.currency,
    );
  }
}
