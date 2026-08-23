import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_email_model.dart';
import 'package:app/services/files/file_model.dart';

/// Empresa completa, tal como la devuelve `GET /business/profile/`.
///
/// Es la cedula de identidad de la empresa: como se llama (comercial y
/// legalmente), su handle publico y su logo, a que se dedica, en que situacion
/// legal esta, donde opera, en que factura y como se la contacta.
///
/// Lo que la empresa **es**, y nada mas: su gente, sus sucursales, sus clientes
/// y sus numeros son cada uno su propia seccion y su propia lectura
/// (`/business/employees/`, `/branches/`, `/clients/`, `/statistics/`), porque
/// cambian por su cuenta y no son lo que edita esta ficha.
///
/// A diferencia de `BusinessModel`, que llega comprimido en `/init` con lo
/// justo para pintar el selector, este es el detalle entero de **una sola**
/// empresa: la activa. El endpoint no recibe un id, resuelve la empresa de la
/// cabecera `business_id`, asi que pedir el perfil de otra es elegirla primero
/// (ver `BusinessService.loadProfile`).
class BusinessProfileModel {
  /// Identificador publico (uuid). Es el que viaja en `business_id`.
  final String id;

  /// Nombre comercial: el que se muestra en toda la app.
  final String name;

  /// Razon social. Puede diferir del comercial y puede no estar cargada.
  final String legalName;

  /// Handle publico, sin arroba, para enlaces y busqueda.
  final String nickname;

  /// Lema o descripcion corta.
  final String caption;

  /// Logo de la empresa, o `null` si no subio ninguno. Es un archivo del
  /// backend: trae su id y con que tamanos existe, y la direccion se arma con
  /// la base que entrego `/init` (ver [FileModel]).
  final FileModel? logo;

  final BusinessActivity activity;

  /// Situacion legal de la empresa. No se edita desde la app: la otorga el
  /// proceso de verificacion.
  final BusinessVerification verification;
  final DateTime? verifiedDate;

  /// Identificador fiscal (RIF/NIF/EIN...).
  final String taxId;

  /// Codigo ISO 3166-1 alpha-2 del pais donde opera.
  final String country;

  /// Domicilio de la oficina principal, en una linea.
  final String address;

  /// Tag de idioma en el que opera la empresa (`es`, `en`, `es-VE`).
  final String language;

  /// Codigo (ISO 4217) de la moneda en la que escribe sus precios.
  ///
  /// Como todos los codigos del perfil, se guarda crudo: quien lo tenga que
  /// **escribir** le pide al catalogo de `/init` con que hacerlo
  /// ([CurrencyCatalogService]), que es quien sabe el simbolo, el lado y los
  /// decimales de cada una.
  final String currency;

  /// Monedas secundarias en las que ademas cotiza, en codigo ISO 4217.
  final List<String> currencies;

  final String phone;

  /// Direccion principal de la empresa: la de [emails] marcada como tal. Llega
  /// suelta ademas de en la lista para quien quiere una sola y no tiene por que
  /// saber elegirla.
  final String email;

  /// Todas las direcciones de la empresa, la principal primero.
  final List<BusinessEmailModel> emails;

  final String website;

  /// Fecha de constitucion legal de la empresa.
  final DateTime? incorporationDate;

  /// `true` si la empresa la creo quien esta preguntando. El id de su creador
  /// no llega: esto es lo unico que el cliente necesita saber de el.
  final bool owner;

  /// Cuando se registro la empresa en la plataforma.
  final DateTime? date;

  const BusinessProfileModel({
    required this.id,
    required this.name,
    this.legalName = "",
    this.nickname = "",
    this.caption = "",
    this.logo,
    this.activity = BusinessActivity.unknown,
    this.verification = BusinessVerification.untrusted,
    this.verifiedDate,
    this.taxId = "",
    this.country = "",
    this.address = "",
    this.language = "",
    this.currency = "",
    this.currencies = const [],
    this.phone = "",
    this.email = "",
    this.emails = const [],
    this.website = "",
    this.incorporationDate,
    this.owner = false,
    this.date
  });

  factory BusinessProfileModel.fromJson(Map json) => BusinessProfileModel(
    id: _text(json["id"]),
    name: _text(json["name"]),
    legalName: _text(json["legal_name"]),
    nickname: _text(json["nickname"]),
    caption: _text(json["caption"]),
    logo: FileModel.from(json["logo"]),
    activity: BusinessActivity.from(json["activity_type"]),
    verification: BusinessVerification.from(json["verification"]),
    verifiedDate: _date(json["verified_date"]),
    taxId: _text(json["tax_id"]),
    country: _text(json["country"]).toUpperCase(),
    address: _text(json["address"]),
    language: _text(json["language"]),
    currency: _text(json["currency"]).toUpperCase(),
    currencies: _codes(json["currencies"]),
    phone: _text(json["phone"]),
    email: _text(json["email"]),
    emails: BusinessEmailModel.fromList(json["emails"]),
    website: _text(json["website"]),
    incorporationDate: _date(json["incorporation_date"]),
    owner: json["owner"] == true,
    date: _date(json["date"])
  );

  /// Lo opcional del perfil llega como `null` desde el backend y aca queda como
  /// texto vacio: el perfil pregunta una sola cosa —si hay algo que mostrar— y
  /// con una sola forma de decir "no hay" no se puede olvidar la otra.
  static String _text(dynamic value) => value?.toString().trim() ?? "";

  /// Las fechas viajan como texto ISO. Una que no se pueda leer vale lo mismo
  /// que una que no vino: la fila no se muestra.
  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static List<String> _codes(dynamic value) {
    if (value is! List) return const [];

    return [
      for (final code in value)
        if (_text(code).isNotEmpty) _text(code).toUpperCase()
    ];
  }
}

/// Sector al que se dedica una empresa.
///
/// Los codigos son los de `companies`.`activity_type` y son los mismos que se
/// eligen al crearla: el alta ofrece [catalog] y el perfil traduce lo que
/// devuelve el backend, asi que las dos pantallas no pueden nombrar distinto al
/// mismo sector.
///
/// La lista es **la del backend** y no una seleccion de ella: el sector se
/// valida contra un enumerado cerrado (`ACTIVITY_TYPE` en `lib/extras/
/// rules.json`), asi que uno de mas se rechaza al guardar y uno de menos deja a
/// las empresas que lo tienen leyendose como "Otro". Si alla se agrega un
/// sector, se agrega aca.
enum BusinessActivity {
  retail,
  wholesale,
  food,
  hospitality,
  services,
  technology,
  health,
  beauty,
  education,
  manufacturing,
  construction,
  agriculture,
  transport,
  automotive,
  entertainment,
  finance,
  realEstate,
  legal,
  nonprofit,
  other,
  unknown;

  static BusinessActivity from(dynamic code) => switch (
    code?.toString().toUpperCase()
  ) {
    "RETAIL" => retail,
    "WHOLESALE" => wholesale,
    "FOOD" => food,
    "HOSPITALITY" => hospitality,
    "SERVICES" => services,
    "TECHNOLOGY" => technology,
    "HEALTH" => health,
    "BEAUTY" => beauty,
    "EDUCATION" => education,
    "MANUFACTURING" => manufacturing,
    "CONSTRUCTION" => construction,
    "AGRICULTURE" => agriculture,
    "TRANSPORT" => transport,
    "AUTOMOTIVE" => automotive,
    "ENTERTAINMENT" => entertainment,
    "FINANCE" => finance,
    "REAL_ESTATE" => realEstate,
    "LEGAL" => legal,
    "NONPROFIT" => nonprofit,
    "OTHER" => other,
    _ => unknown
  };

  /// Los sectores que se pueden elegir. [unknown] no esta: no es un sector, es
  /// no haber reconocido el que mando el backend.
  ///
  /// El orden no es el del backend ni el alfabetico: son veinte y se eligen
  /// leyendo, asi que van los parecidos juntos —lo que se vende, lo que se
  /// atiende, lo que se produce, lo que se mueve— y "Otro" al final, que es
  /// donde se busca cuando ninguno de los anteriores servia.
  static const List<BusinessActivity> catalog = [
    retail,
    wholesale,
    food,
    hospitality,
    services,
    technology,
    health,
    beauty,
    education,
    manufacturing,
    construction,
    agriculture,
    transport,
    automotive,
    entertainment,
    finance,
    realEstate,
    legal,
    nonprofit,
    other
  ];

  /// Codigo que viaja al backend. No se traduce.
  String get value => switch (this) {
    retail => "RETAIL",
    wholesale => "WHOLESALE",
    food => "FOOD",
    hospitality => "HOSPITALITY",
    services => "SERVICES",
    technology => "TECHNOLOGY",
    health => "HEALTH",
    beauty => "BEAUTY",
    education => "EDUCATION",
    manufacturing => "MANUFACTURING",
    construction => "CONSTRUCTION",
    agriculture => "AGRICULTURE",
    transport => "TRANSPORT",
    automotive => "AUTOMOTIVE",
    entertainment => "ENTERTAINMENT",
    finance => "FINANCE",
    realEstate => "REAL_ESTATE",
    legal => "LEGAL",
    nonprofit => "NONPROFIT",
    other => "OTHER",
    unknown => ""
  };

  String label(BuildContext context) => switch (this) {
    retail => S.of(context).business_type_retail,
    wholesale => S.of(context).business_type_wholesale,
    food => S.of(context).business_type_food,
    hospitality => S.of(context).business_type_hospitality,
    services => S.of(context).business_type_services,
    technology => S.of(context).business_type_technology,
    health => S.of(context).business_type_health,
    beauty => S.of(context).business_type_beauty,
    education => S.of(context).business_type_education,
    manufacturing => S.of(context).business_type_manufacturing,
    construction => S.of(context).business_type_construction,
    agriculture => S.of(context).business_type_agriculture,
    transport => S.of(context).business_type_transport,
    automotive => S.of(context).business_type_automotive,
    entertainment => S.of(context).business_type_entertainment,
    finance => S.of(context).business_type_finance,
    realEstate => S.of(context).business_type_real_estate,
    legal => S.of(context).business_type_legal,
    nonprofit => S.of(context).business_type_nonprofit,
    other || unknown => S.of(context).business_type_other
  };
}

/// Situacion legal de una empresa dentro de la plataforma.
///
/// La otorga el proceso de verificacion y nunca el cliente: se muestra, no se
/// edita. Manda sobre lo que la empresa puede hacer —una sin verificar opera
/// con limites—, asi que el perfil la pone junto al nombre y no en una fila
/// mas.
enum BusinessVerification {
  untrusted,
  trusted,
  pending,
  verified,
  rejected;

  /// Lo que no se reconoce cae en [untrusted], que es donde arranca toda
  /// empresa: ante la duda se muestra la situacion mas conservadora, no una
  /// confianza que nadie otorgo.
  static BusinessVerification from(dynamic code) => switch (
    code?.toString().toLowerCase()
  ) {
    "trusted" => trusted,
    "pending" => pending,
    "verified" => verified,
    "rejected" => rejected,
    _ => untrusted
  };

  String label(BuildContext context) => switch (this) {
    untrusted => S.of(context).business_verification_untrusted,
    trusted => S.of(context).business_verification_trusted,
    pending => S.of(context).business_verification_pending,
    verified => S.of(context).business_verification_verified,
    rejected => S.of(context).business_verification_rejected
  };

  /// Color de la etiqueta. Semantico y fijo, como el resto de los estados de
  /// empresa: comunica lo mismo en tema claro y en oscuro.
  Color get color => switch (this) {
    verified => const Color(0xFF2E9E5B),
    trusted => const Color(0xFF3D7EC4),
    pending => const Color(0xFFCF9A17),
    rejected => const Color(0xFFD5493F),
    untrusted => const Color(0xFF9A9A9A)
  };

  /// Icono de la etiqueta. El tilde es solo de lo verificado: en cualquier otra
  /// situacion se leeria como aprobado.
  IconData get icon => this == verified ? CI.check : CI.info;
}
