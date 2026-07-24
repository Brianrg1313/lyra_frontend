import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

/// Empresa tal como la devuelve `GET /business/list/`.
///
/// A diferencia de [BusinessModel], que llega comprimido en `/init` solo con lo
/// justo para pintar el selector, este modelo trae el detalle que la seccion de
/// empresas necesita: el vinculo del cliente con la empresa ([membership] y
/// [rank]) y en que estado esta operando la empresa ([state]).
class BusinessDetailModel {
  final String id;
  final String name;

  /// Nombre del recurso del logo en el servidor de assets, o `null` si la
  /// empresa todavia no subio uno.
  final String? logo;

  final BusinessMembership membership;
  final BusinessRank rank;
  final BusinessState state;

  const BusinessDetailModel({
    required this.id,
    required this.name,
    this.logo,
    this.membership = BusinessMembership.unknown,
    this.rank = BusinessRank.unknown,
    this.state = BusinessState.unknown,
  });

  factory BusinessDetailModel.fromJson(Map json) => BusinessDetailModel(
    id: json["id"]?.toString() ?? "",
    name: json["name"] ?? "",
    logo: (json["logo"] as String?)?.isEmpty ?? true ? null : json["logo"],
    membership: BusinessMembership.from(json["membership"] ?? json["status"]),
    rank: BusinessRank.from(json["rank"] ?? json["role"]),
    state: BusinessState.from(json["state"] ?? json["business_state"]),
  );

  /// Decodifica la respuesta sin atarse a un unico formato: acepta tanto una
  /// lista de objetos como la tabla columnar (`{"keys": [...], "values": [...]}`)
  /// que ya usa `/init`. Asi el parseo no se rompe si el backend cambia de forma.
  static List<BusinessDetailModel> fromResponse(dynamic data) {
    if (data is List) {
      return [
        for (final row in data)
          if (row is Map) BusinessDetailModel.fromJson(row)
      ];
    }

    if (data is Map) {
      final keys = data["keys"];
      final rows = data["values"];

      if (keys is List && rows is List) {
        return [
          for (final row in rows)
            if (row is List)
              BusinessDetailModel.fromJson({
                for (int i = 0; i < keys.length && i < row.length; i++)
                  keys[i].toString(): row[i]
              })
        ];
      }
    }

    return const [];
  }
}

/// Estado del cliente dentro de la empresa.
enum BusinessMembership {
  active,
  restricted,
  pending,
  unknown;

  static BusinessMembership from(dynamic code) => switch (
    code?.toString().toUpperCase()
  ) {
    "ACTIVE" => active,
    "RESTRICTED" => restricted,
    "PENDING" => pending,
    _ => unknown
  };

  String label(BuildContext context) => switch (this) {
    active => S.of(context).business_status_active,
    restricted => S.of(context).business_status_restricted,
    pending => S.of(context).business_status_pending,
    unknown => S.of(context).business_status_unknown
  };

  /// Color del distintivo. Semantico y fijo (verde/rojo/ambar), no depende del
  /// tema: comunica el mismo significado en claro y en oscuro.
  Color get color => switch (this) {
    active => const Color(0xFF2E9E5B),
    restricted => const Color(0xFFD5493F),
    pending => const Color(0xFFCF9A17),
    unknown => const Color(0xFF9A9A9A)
  };
}

/// Rango del cliente dentro de la empresa.
enum BusinessRank {
  seller,
  manager,
  advertiser,
  administrator,
  unknown;

  static BusinessRank from(dynamic code) => switch (
    code?.toString().toUpperCase()
  ) {
    "SELLER" => seller,
    "MANAGER" => manager,
    "ADVERTISER" => advertiser,
    "ADMINISTRATOR" => administrator,
    _ => unknown
  };

  String label(BuildContext context) => switch (this) {
    seller => S.of(context).business_rank_seller,
    manager => S.of(context).business_rank_manager,
    advertiser => S.of(context).business_rank_advertiser,
    administrator => S.of(context).business_rank_administrator,
    unknown => S.of(context).business_rank_unknown
  };
}

/// Como esta operando la empresa ahora mismo.
enum BusinessState {
  open,
  closed,
  inquiriesOnly,
  ordersOnly,
  unknown;

  static BusinessState from(dynamic code) => switch (
    code?.toString().toUpperCase()
  ) {
    "OPEN" => open,
    "CLOSED" => closed,
    "INQUIRIES" || "INQUIRIES_ONLY" => inquiriesOnly,
    "ORDERS" || "ORDERS_ONLY" => ordersOnly,
    _ => unknown
  };

  String label(BuildContext context) => switch (this) {
    open => S.of(context).business_state_open,
    closed => S.of(context).business_state_closed,
    inquiriesOnly => S.of(context).business_state_inquiries,
    ordersOnly => S.of(context).business_state_orders,
    unknown => S.of(context).business_state_unknown
  };

  /// Color del punto de estado. Verde si opera con normalidad, rojo si esta
  /// cerrada, ambar si acepta solo una parte de la operativa.
  Color get color => switch (this) {
    open => const Color(0xFF2E9E5B),
    closed => const Color(0xFFD5493F),
    inquiriesOnly || ordersOnly => const Color(0xFFCF9A17),
    unknown => const Color(0xFF9A9A9A)
  };
}
