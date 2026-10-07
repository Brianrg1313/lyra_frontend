import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/knowledge/knowledge_entry_model.dart';
import 'package:app/toolkit/api.dart';

/// Status of the product search of the question form.
enum KnowledgeProductSearchStatus { idle, loading, ready, error }

/// The products a frequent question can be about, searched by name or code
/// (`POST /knowledge/products/`).
///
/// It is the register's catalog read behind the `knowledge` permission:
/// whoever writes the company's answers names a product without being allowed
/// to sell one. Created by the question form, which is a modal above the
/// section's providers, and dropped with it.
///
/// Only the latest search counts: one typed while another is in flight
/// discards the earlier answer when it lands.
class KnowledgeProductSearch extends ChangeNotifier {
  KnowledgeProductSearchStatus _status = KnowledgeProductSearchStatus.idle;
  List<KnowledgeProduct> _results = const [];
  String _query = "";
  int _ticket = 0;
  bool _disposed = false;

  KnowledgeProductSearchStatus get status => _status;
  List<KnowledgeProduct> get results => _results;
  String get query => _query;

  /// Products whose name or code holds [text]. An empty one clears the list:
  /// a picker is not a catalog to scroll.
  Future<void> search(String text) async {
    final query = text.trim();
    final ticket = ++_ticket;

    _query = query;

    if (query.isEmpty) {
      _results = const [];
      _status = KnowledgeProductSearchStatus.idle;
      _notify();
      return;
    }

    _status = KnowledgeProductSearchStatus.loading;
    _notify();

    try {
      final data = await api.post(
        path: "/knowledge/products/",
        version: "v1",
        data: {"SEARCH": query, "SIZE": 8}
      );

      if (ticket != _ticket) return;

      _results = _read(data);
      _status = KnowledgeProductSearchStatus.ready;
    } catch (error) {
      if (kDebugMode) print("searchKnowledgeProducts failed: $error");

      if (ticket != _ticket) return;

      _results = const [];
      _status = KnowledgeProductSearchStatus.error;
    }

    _notify();
  }

  /// `{ table, data: [{ id, name, sku }] }`: the table is the page's, and
  /// every product carries it from here on.
  static List<KnowledgeProduct> _read(dynamic data) {
    if (data is! Map) return const [];

    final table = data["table"]?.toString() ?? "";
    final rows = data["data"];

    if (table.isEmpty || rows is! List) return const [];

    return [
      for (final row in rows)
        if (row is Map && (row["id"]?.toString() ?? "").isNotEmpty)
          KnowledgeProduct(
            id: row["id"].toString(),
            table: table,
            name: [
              row["name"]?.toString() ?? "",
              row["sku"]?.toString() ?? ""
            ].firstWhere((text) => text.isNotEmpty, orElse: () => "")
          )
    ];
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
