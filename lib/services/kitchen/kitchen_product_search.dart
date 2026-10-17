import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/toolkit/deployment.dart';

enum KitchenProductSearchStatus { idle, loading, ready, error }

/// Products of any table, searched by what their row says: what a recipe line, a modifier's
/// line or the products that offer a group pick from.
///
/// It looks in every table at once (the stock summary's `MATCH`, a few rows each): an
/// ingredient is usually a supply, sometimes another made product (the burger in a combo) or a
/// catalog's bought ready (the can in it), and the person shouldn't have to say which.
/// [supplies] narrows to supplies tables, [catalog] to the others (catalog and made). Only the
/// latest search counts. Created by the picker that uses it.
class KitchenProductSearch extends ChangeNotifier {
  KitchenProductSearch({this.supplies = true, this.catalog = true, InventorySource? inventory, StockSource? stock})
    : _inventory = inventory,
      _stock = stock;

  final bool supplies;
  final bool catalog;
  final InventorySource? _inventory;
  final StockSource? _stock;

  static const int _perTable = 6;

  KitchenProductSearchStatus _status = KitchenProductSearchStatus.idle;
  List<KitchenProduct> _results = const [];
  List<TableLiteModel>? _tables;
  int _ticket = 0;
  bool _disposed = false;

  KitchenProductSearchStatus get status => _status;
  List<KitchenProduct> get results => _results;

  /// The table [product] is a row of, when read.
  TableLiteModel? tableOf(KitchenProduct product) =>
    _tables?.where((table) => table.id == product.tableId).firstOrNull;

  /// The names of the products of [tables] (product id → name): the first rows of each one's
  /// summary, enough to name what a saved group or option points at. What fails names nothing.
  Future<Map<String, String>> namesIn(Set<String> tables) async {
    final names = <String, String>{};

    await Future.wait([
      for (final table in tables)
        (_stock ?? Sources.stock).summary(page: 1, size: 200, tableId: table).then((page) {
          for (final product in KitchenProduct.fromSummary(page)) {
            if (product.name.isNotEmpty) names[product.id] = product.name;
          }
        }).catchError((Object error) {
          if (kDebugMode) print("kitchen names in $table failed: $error");
        })
    ]);

    return names;
  }

  Future<void> search(String text) async {
    final query = text.trim();
    final ticket = ++_ticket;

    if (query.isEmpty) {
      _results = const [];
      _status = KitchenProductSearchStatus.idle;
      _notify();
      return;
    }

    _status = KitchenProductSearchStatus.loading;
    _notify();

    try {
      final tables = _tables ??= await (_inventory ?? Sources.inventory).tables();
      final wanted = tables.where((table) => table.supplies ? supplies : catalog).toList();
      final pages = await Future.wait([
        for (final table in wanted)
          (_stock ?? Sources.stock).summary(page: 1, size: _perTable, match: query, tableId: table.id)
            .then((page) => KitchenProduct.fromSummary(page, supplies: table.supplies, made: table.made))
            .catchError((Object error) {
              if (kDebugMode) print("kitchen search in ${table.id} failed: $error");
              return const <KitchenProduct>[];
            })
      ]);

      if (ticket != _ticket) return;

      // Supplies first, then made products: a recipe is mostly made of them.
      _results = [for (final page in pages) ...page]
        ..sort((a, b) => _rank(a).compareTo(_rank(b)));
      _status = KitchenProductSearchStatus.ready;
    } catch (error) {
      if (kDebugMode) print("kitchen search failed: $error");
      if (ticket != _ticket) return;

      _results = const [];
      _status = KitchenProductSearchStatus.error;
    }

    _notify();
  }

  static int _rank(KitchenProduct product) => product.supplies ? 0 : product.made ? 1 : 2;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
