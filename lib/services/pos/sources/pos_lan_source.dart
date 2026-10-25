// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/pos/pos_invoice_model.dart';
import 'package:app/services/pos/pos_payment_method.dart';
import 'package:app/services/pos/pos_product_model.dart';
import 'package:app/services/pos/sources/pos_source.dart';
import 'package:app/toolkit/backend/deployment.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;

/// [PosSource] over the master (`docs/offline/specs/pos.md`).
///
/// The master counts money in minor units of the company's currency and writes percents as
/// decimal strings (README, money); this source turns both into the numbers the models already
/// hold, both ways, so no model or screen changes (plan principle 8). Every answer that carries
/// money names its `currency`, which is what the minor digits are read from.
class PosLanSource implements PosSource {
  const PosLanSource(this._lan);

  final LanService _lan;

  @override
  Future<({int mineSales, List<String> categories})> summary() async {
    final answer = await _lan.call(Ops.posSummary);
    if (answer is! Map) throw const UnreadableAnswer("pos.summary");

    final mine = answer["mine"];
    final categories = answer["categories"];

    return (
      mineSales: mine is Map ? ((mine["sales"] as num?)?.toInt() ?? 0) : 0,
      categories: categories is List ? categories.whereType<String>().toList(growable: false) : const <String>[]
    );
  }

  @override
  Future<List<PosPaymentMethod>> methods() async {
    final answer = await _lan.call(Ops.posMethods);
    final methods = answer is Map ? answer["methods"] : null;
    if (methods is! List) throw const UnreadableAnswer("pos.methods");

    return [
      for (final entry in methods)
        if (entry is Map) PosPaymentMethod.fromJson(Map<String, dynamic>.from(entry))
    ];
  }

  @override
  Future<PosCatalogPage> catalog({
    required int size,
    String cursor = "",
    String search = "",
    String category = ""
  }) async {
    final answer = await _lan.call(Ops.posCatalog, args: {
      "size": size,
      if (cursor.isNotEmpty) "cursor": cursor,
      if (search.isNotEmpty) "search": search,
      if (category.isNotEmpty) "category": category
    });
    if (answer is! Map) throw const UnreadableAnswer("pos.catalog");

    final data = answer["data"];
    final keys = data is Map ? data["keys"] : null;
    final values = data is Map ? data["values"] : null;
    if (keys is! List || values is! List) throw const UnreadableAnswer("pos.catalog");

    final price = keys.indexOf("price");
    final digits = decimalsOf(answer["currency"]);

    return PosCatalogPage.fromResponse({
      ...answer,
      "data": {
        "keys": keys,
        "values": [
          for (final row in values)
            if (row is List)
              [for (var i = 0; i < row.length; i++) i == price ? major(row[i], digits) : row[i]]
        ]
      }
    });
  }

  /// `mine` is this device on a master (`pos.md` POS-45), which is what a till asks for.
  @override
  Future<List<PosInvoice>> openInvoices({bool mine = false, required int size}) async {
    final answer = await _lan.call(Ops.posInvoicesList, args: {if (mine) "mine": true, "size": size});
    final invoices = answer is Map ? answer["invoices"] : null;
    if (invoices is! List) throw const UnreadableAnswer("pos.invoices.list");

    return [for (final entry in invoices) PosInvoice.fromJson(invoice(entry))];
  }

  @override
  Future<PosInvoice> open({required double tax}) async =>
    PosInvoice.fromJson(invoice(await _lan.call(Ops.posInvoicesOpen, args: {"tax": percent(tax)})));

  /// The service's body is the cloud's (`PRODUCT_ID`, `ADD`, `PRICE`, `TAX`). A typed-in
  /// charge's price goes in minor units of the ticket's currency, which is the company's
  /// (`pos.md`, invoice data).
  @override
  Future<PosInvoice> writeLine(String id, Map<String, dynamic> body) async {
    final args = <String, Object?>{"id": id};

    for (final MapEntry(:key, :value) in body.entries) {
      switch (key) {
        case "PRODUCT_ID": args["productId"] = value;
        case "LINE_ID": args["lineId"] = value;
        case "CONCEPT": args["concept"] = value;
        case "ADD": args["add"] = value;
        case "QUANTITY": args["quantity"] = value;
        case "PRICE": args["price"] = minor(value, decimalsOf(businessService.currencyCode));
        case "TAX": args["tax"] = value is num ? percent(value.toDouble()) : value;
      }
    }

    final answer = await _lan.call(Ops.posInvoicesLine, args: args);

    return PosInvoice.fromJson(invoice(answer is Map ? answer["invoice"] : null));
  }

  @override
  Future<PosInvoice> close(
    String id, {
    required String method,
    String reference = "",
    String note = ""
  }) async => PosInvoice.fromJson(invoice(await _lan.call(Ops.posInvoicesClose, args: {
    "id": id,
    "method": method,
    if (reference.trim().isNotEmpty) "reference": reference.trim(),
    if (note.trim().isNotEmpty) "note": note.trim()
  })));

  @override
  Future<void> cancel(String id) => _lan.call(Ops.posInvoicesCancel, args: {"id": id});

  /// An invoice of the master with its money as the model reads it.
  static Object? invoice(Object? raw) {
    if (raw is! Map) return raw;

    final digits = decimalsOf(raw["currency"]);
    final items = raw["items"];
    final taxes = raw["taxes"];

    return {
      ...raw,
      for (final key in const ["subtotal", "tax", "total"]) key: major(raw[key], digits),
      if (items is List)
        "items": [
          for (final line in items)
            if (line is Map)
              {
                ...line,
                for (final key in const ["price", "list", "subtotal", "tax", "total"]) key: major(line[key], digits)
              }
        ],
      if (taxes is List)
        "taxes": [
          for (final entry in taxes)
            if (entry is Map) {...entry, "base": major(entry["base"], digits), "amount": major(entry["amount"], digits)}
        ]
    };
  }

  /// How many minor digits [currency] has (`Catalogs`), 2 for one this release doesn't know.
  static int decimalsOf(Object? currency) =>
    Catalogs.currencyRows.where((row) => row["code"] == currency).firstOrNull?["decimals"] as int? ?? 2;

  /// Minor units as the amount the models hold; null stays null (a price nobody wrote).
  static double? major(Object? minor, int decimals) => minor is num ? minor / _scale(decimals) : null;

  /// An amount in minor units, rounded half away from zero.
  static int? minor(Object? amount, int decimals) => amount is num ? (amount * _scale(decimals)).round() : null;

  /// A percent as the master writes it: `16`, `7.5`, never `16.0` or `0.16`.
  static String percent(double value) {
    final fixed = value.toStringAsFixed(4);

    return fixed.contains(".") ? fixed.replaceFirst(RegExp(r"\.?0+$"), "") : fixed;
  }

  static num _scale(int decimals) {
    var scale = 1;
    for (var i = 0; i < decimals; i++) {
      scale *= 10;
    }

    return scale;
  }
}
