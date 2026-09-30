// SERVICES
import 'package:app/services/pos/pos_invoice_model.dart';
import 'package:app/services/pos/pos_payment_method.dart';
import 'package:app/services/pos/pos_product_model.dart';
import 'package:app/services/pos/sources/pos_source.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/deployment.dart';

/// [PosSource] over the backend's REST api.
class PosCloudSource implements PosSource {
  const PosCloudSource();

  /// `GET /pos/` answers for the session, never for a chosen seller.
  @override
  Future<({int mineSales, List<String> categories})> summary() async {
    final data = await api.get(path: "/pos/", version: "v1");
    if (data is! Map) throw const UnreadableAnswer("pos");

    final mine = data["mine"];
    final categories = data["categories"];

    return (
      mineSales: mine is Map ? ((mine["sales"] as num?)?.toInt() ?? 0) : 0,
      categories: categories is List
        ? categories.whereType<String>().where((label) => label.isNotEmpty).toList(growable: false)
        : const <String>[]
    );
  }

  /// The endpoint also answers the channels a sale can come from; the counter's
  /// is always `pos`, so they are not read.
  @override
  Future<List<PosPaymentMethod>> methods() async {
    final data = await api.get(path: "/pos/methods/", version: "v1");
    final methods = data is Map ? data["methods"] : null;

    if (methods is! List) throw const UnreadableAnswer("pos/methods");

    return [
      for (final entry in methods)
        if (entry is Map)
          PosPaymentMethod.fromJson(Map<String, dynamic>.from(entry))
    ];
  }

  @override
  Future<PosCatalogPage> catalog({
    required int size,
    String cursor = "",
    String search = "",
    String category = ""
  }) async {
    final data = await api.post(
      path: "/pos/catalog/",
      version: "v1",
      data: {
        "SIZE": size,
        if (cursor.isNotEmpty) "CURSOR": cursor,
        if (search.isNotEmpty) "SEARCH": search,
        if (category.isNotEmpty) "CATEGORY": category
      }
    );

    if (data is! Map) throw const UnreadableAnswer("pos/catalog");

    return PosCatalogPage.fromResponse(data);
  }

  /// The filters travel in the query string and not in the path: `Uri` escapes
  /// a `?` written into a path, which would ask for every open tab in the
  /// company without saying so.
  @override
  Future<List<PosInvoice>> openInvoices({bool mine = false, required int size}) async {
    final data = await api.get(
      path: "/pos/invoices/",
      version: "v1",
      query: {if (mine) "MINE": 1, "SIZE": size}
    );

    final invoices = data is Map ? data["invoices"] : null;
    if (invoices is! List) throw const UnreadableAnswer("pos/invoices");

    return [for (final entry in invoices) PosInvoice.fromJson(entry)];
  }

  /// `TAX` is the rate every line inherits unless it carries its own.
  @override
  Future<PosInvoice> open({required double tax}) async => PosInvoice.fromJson(
    await api.post(path: "/pos/invoices/", version: "v1", data: {"TAX": tax})
  );

  @override
  Future<PosInvoice> writeLine(String id, Map<String, dynamic> body) async {
    final data = await api.put(
      path: "/pos/invoices/items/",
      version: "v1",
      data: {"ID": id, ...body}
    );

    return PosInvoice.fromJson(data is Map ? data["invoice"] : null);
  }

  @override
  Future<PosInvoice> close(
    String id, {
    required String method,
    String reference = "",
    String note = ""
  }) async => PosInvoice.fromJson(await api.post(
    path: "/pos/invoices/close/",
    version: "v1",
    data: {
      "ID": id,
      "METHOD": method,
      if (reference.trim().isNotEmpty) "REFERENCE": reference.trim(),
      if (note.trim().isNotEmpty) "NOTE": note.trim()
    }
  ));

  @override
  Future<void> cancel(String id) =>
    api.post(path: "/pos/invoices/cancel/", version: "v1", data: {"ID": id});
}
