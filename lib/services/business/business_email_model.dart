import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

/// Una de las direcciones a las que se le puede escribir a la empresa.
///
/// Una empresa no tiene "un correo": tiene soporte@, ventas@, rrhh@,
/// facturacion@, y cada uno significa algo distinto para quien escribe. Por eso
/// llegan como una lista dentro del perfil y no como un campo mas.
///
/// El [purpose] es una lista cerrada y no texto libre: es lo que hace legible
/// la lista —"a donde va un reclamo" tiene una sola respuesta— mientras que
/// [label] es la mitad libre, para cuando el proposito no alcanza
/// ("Facturacion Colombia") o es `other`, donde el nombre lo dice todo.
class BusinessEmailModel {
  const BusinessEmailModel({
    required this.id,
    required this.email,
    this.purpose = BusinessEmailPurpose.general,
    this.label = "",
    this.main = false,
    this.verified = false,
    this.verifiedDate,
    this.date
  });

  /// Identificador publico (uuid). Es lo que se manda de vuelta para cambiarla
  /// o borrarla.
  final String id;

  final String email;

  /// Para que es la direccion.
  final BusinessEmailPurpose purpose;

  /// Nombre que le puso la empresa, o vacio si no le puso ninguno.
  final String label;

  /// Si es la direccion principal: la que el perfil devuelve ademas suelta como
  /// `email` y la que ve quien solo quiere una. Mientras la empresa tenga
  /// direcciones hay exactamente una principal.
  final bool main;

  /// Si la empresa probo que lee la direccion: se le mando un codigo y alguien
  /// lo devolvio (`POST` / `PUT /business/emails/verify/`).
  ///
  /// No dice nada de la empresa —eso es [BusinessVerification], que es otra
  /// cosa—: dice que la casilla existe y funciona. Una direccion sin verificar
  /// se muestra igual, porque sigue siendo un dato de contacto cargado; lo que
  /// se muestra al lado es que nadie comprobo que llegue.
  final bool verified;

  /// Cuando se verifico, o `null` si todavia no.
  final DateTime? verifiedDate;

  final DateTime? date;

  factory BusinessEmailModel.fromJson(Map json) => BusinessEmailModel(
    id: _text(json["id"]),
    email: _text(json["email"]),
    purpose: BusinessEmailPurpose.from(json["purpose"]),
    label: _text(json["label"]),
    main: json["main"] == true || json["main"] == 1,
    verified: json["verified"] == true || json["verified"] == 1,
    verifiedDate: DateTime.tryParse(_text(json["verified_date"])),
    date: DateTime.tryParse(_text(json["date"]))
  );

  /// Las direcciones que vienen dentro del perfil. Una fila sin direccion no se
  /// arma: no hay nada que mostrar ni a donde escribir.
  static List<BusinessEmailModel> fromList(dynamic value) {
    if (value is! List) return const [];

    return [
      for (final row in value)
        if (row is Map && _text(row["email"]).isNotEmpty)
          BusinessEmailModel.fromJson(row)
    ];
  }

  /// Como se nombra la direccion en la ficha: el nombre que le puso la empresa
  /// y, si no le puso ninguno, para que es.
  String title(BuildContext context) =>
    label.isNotEmpty ? label : purpose.label(context);

  /// Como se lee el estado de la direccion. Se nombra en positivo y en negativo
  /// —"Verificada" / "Sin verificar"— y no con un solo texto que aparece y
  /// desaparece: quien mira la lista tiene que poder distinguir la direccion
  /// que se comprobo de la que nadie comprobo todavia, y una fila sin etiqueta
  /// se lee como una fila a la que le falta algo.
  String verificationLabel(BuildContext context) => verified
    ? S.of(context).business_email_verified
    : S.of(context).business_email_unverified;

  /// Color de la etiqueta del estado. Fijo y semantico, como el de la situacion
  /// legal de la empresa: el verde es que llega, el ambar es que nadie lo
  /// comprobo. Sin verificar no es un error —la direccion puede estar
  /// perfecta— asi que no es rojo.
  Color get verificationColor =>
    verified ? const Color(0xFF2E9E5B) : const Color(0xFFCF9A17);

  /// Icono de la etiqueta. El tilde es solo de lo verificado, por lo mismo que
  /// en la situacion legal de la empresa: en el otro estado se leeria como
  /// aprobado.
  IconData get verificationIcon => verified ? CI.chack_circle : CI.info;

  static String _text(dynamic value) => value?.toString().trim() ?? "";
}

/// Para que sirve una direccion de la empresa.
///
/// Son los valores de `company_emails`.`purpose` y viajan en minuscula, tal
/// como se llaman aca.
enum BusinessEmailPurpose {
  general,
  support,
  sales,
  billing,
  hr,
  legal,
  press,
  other;

  /// Lo que no se reconoce cae en [other], que es justamente el proposito para
  /// lo que una lista cerrada no sabe nombrar: asi una direccion de una version
  /// mas nueva se sigue viendo, con su nombre propio si lo tiene.
  static BusinessEmailPurpose from(dynamic code) => switch (
    code?.toString().trim().toLowerCase()
  ) {
    "general" => general,
    "support" => support,
    "sales" => sales,
    "billing" => billing,
    "hr" => hr,
    "legal" => legal,
    "press" => press,
    _ => other
  };

  /// Codigo que viaja al backend. No se traduce.
  String get value => name;

  String label(BuildContext context) => switch (this) {
    general => S.of(context).business_email_purpose_general,
    support => S.of(context).business_email_purpose_support,
    sales => S.of(context).business_email_purpose_sales,
    billing => S.of(context).business_email_purpose_billing,
    hr => S.of(context).business_email_purpose_hr,
    legal => S.of(context).business_email_purpose_legal,
    press => S.of(context).business_email_purpose_press,
    other => S.of(context).business_email_purpose_other
  };

  /// Que llega a una direccion de este proposito, escrito desde el lado de
  /// quien escribe: "cuando un cliente necesita ayuda" y no "correo de
  /// soporte". Nombrar el proposito de nuevo no aclara a cual de las
  /// direcciones de la empresa va cada cosa, que es lo unico que hay que
  /// decidir al cargarlas.
  ///
  /// [other] no tiene: es justamente el proposito de lo que la lista no sabe
  /// nombrar, asi que lo unico que se puede decir de esa direccion es el nombre
  /// que le puso la empresa.
  String? description(BuildContext context) => switch (this) {
    general => S.of(context).business_email_purpose_general_note,
    support => S.of(context).business_email_purpose_support_note,
    sales => S.of(context).business_email_purpose_sales_note,
    billing => S.of(context).business_email_purpose_billing_note,
    hr => S.of(context).business_email_purpose_hr_note,
    legal => S.of(context).business_email_purpose_legal_note,
    press => S.of(context).business_email_purpose_press_note,
    other => null
  };

  /// Con que se reconoce el proposito en la ficha sin leer su nombre. Todas son
  /// direcciones de correo, asi que el sobre no distinguiria ninguna: el icono
  /// es de lo que se hace con ella.
  IconData get icon => switch (this) {
    general => CI.mail,
    support => CI.support,
    sales => CI.cart_shopping,
    billing => CI.wallet,
    hr => CI.employee,
    legal => CI.documents,
    press => CI.notification,
    other => CI.mail
  };
}
