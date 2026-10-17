import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:app/toolkit/toolkit.dart' show S;

// SERVICES
import 'package:app/services/inventory/table_field_request.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/inventory/table_record_request.dart';
import 'package:app/services/kitchen/kitchen_api.dart';
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/kitchen_product_search.dart';
import 'package:app/services/kitchen/kitchen_request.dart';
import 'package:app/services/kitchen/made_product_model.dart';
import 'package:app/services/kitchen/recipe_model.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/toolkit/deployment.dart';

enum MadeProductsStatus { loading, ready, empty, error }

/// What the form of a made product saves: its columns' values by FIELD_ID (the name and the
/// price by their own, since their columns may not exist yet), how it is made and what it
/// consumes.
typedef MadeProductDraft = ({
  String name,
  String price,
  Map<String, String> values,
  RecipeMode mode,
  List<RecipeLineDraft> lines
});

/// The products of one `made` table, as a list of forms and not a sheet: each one is a name, a
/// price and what it consumes (`cocina-frontend.md` §3), written in one `records/manage` call.
///
/// Owned by the made products view, per open table. It reads the structure once, then pages of
/// records (with what each consumes and can be sold now), and the supplies' products once, by
/// id, so a line says its unit (`kitchenUnitsFor`): the backend answers lines without one.
class MadeProductsService extends ChangeNotifier {
  MadeProductsService({required this.tableId, InventorySource? source, KitchenProductSearch? search})
    : _source = source,
      _search = search ?? KitchenProductSearch(inventory: source);

  final String tableId;
  final InventorySource? _source;
  final KitchenProductSearch _search;

  InventorySource get _inventory => _source ?? Sources.inventory;

  static const int _size = 50;

  MadeProductsStatus _status = MadeProductsStatus.loading;
  TableStructureModel _structure = const TableStructureModel();
  MadeFields _fields = const MadeFields();
  List<MadeProduct> _products = const [];
  Map<String, KitchenProduct> _supplies = const {};
  String _query = "";
  int _page = 0;
  int? _total;
  bool _more = false;
  bool _loadingMore = false;
  bool _moreFailed = false;
  int _ticket = 0;
  bool _disposed = false;

  MadeProductsStatus get status => _status;
  MadeFields get fields => _fields;
  List<MadeProduct> get products => _products;
  bool get hasMore => _more;
  bool get loadingMore => _loadingMore;
  bool get moreFailed => _moreFailed;
  bool get isSearching => _query.isNotEmpty;

  /// How many there are (or match), when the backend says it.
  int? get total => _total;

  /// The unit [productId] is counted in, when it is a supply read (empty: in units).
  String unitOf(String productId) => _supplies[productId]?.unit ?? "";

  /// The supplies' units by product id, for the form.
  Map<String, String> get units => {for (final product in _supplies.values) product.id: product.unit};

  /// Reads the structure, the first page and the supplies.
  Future<void> load({String query = ""}) async {
    _query = query.trim();
    _status = MadeProductsStatus.loading;
    _notify();

    try {
      final reads = await Future.wait([_inventory.structure(tableId), _search.suppliesById()]);

      _structure = reads[0] as TableStructureModel;
      _supplies = reads[1] as Map<String, KitchenProduct>;
      _fields = MadeFields.of(_structure.fields);
    } catch (error) {
      if (kDebugMode) print("made products structure failed: $error");
      _status = MadeProductsStatus.error;
      _notify();
      return;
    }

    await _first();
  }

  Future<void> search(String query) {
    if (query.trim() == _query) return Future.value();

    _query = query.trim();
    if (_status == MadeProductsStatus.error && _structure.isEmpty) return load(query: _query);

    _status = MadeProductsStatus.loading;
    _notify();

    return _first();
  }

  /// The first page again, keeping what is shown until it lands (after a write).
  Future<void> _first() async {
    final ticket = ++_ticket;

    try {
      final read = await _read(1);
      if (ticket != _ticket) return;

      _products = read;
      _page = 1;
      _status = read.isEmpty ? MadeProductsStatus.empty : MadeProductsStatus.ready;
    } catch (error) {
      if (kDebugMode) print("made products failed: $error");
      if (ticket != _ticket) return;

      _status = MadeProductsStatus.error;
    }

    _notify();
  }

  Future<List<MadeProduct>> _read(int page) async {
    final answer = await _inventory.records(tableId, page: page, size: _size, match: _query);
    final products = MadeProduct.listFrom(answer.page.alignedTo(_structure.fields));

    _total = answer.total;
    _more = answer.total != null ? page * _size < answer.total! : products.length == _size;

    return products;
  }

  Future<void> more() async {
    if (_loadingMore || !_more) return;

    final ticket = _ticket;
    _loadingMore = true;
    _moreFailed = false;
    _notify();

    try {
      final read = await _read(_page + 1);
      if (ticket != _ticket) return;

      final known = {for (final product in _products) product.id};
      _products = [..._products, for (final product in read) if (!known.contains(product.id)) product];
      _page++;
    } catch (error) {
      if (kDebugMode) print("made products more failed: $error");
      if (ticket == _ticket) _moreFailed = true;
    } finally {
      if (ticket == _ticket) _loadingMore = false;
    }

    _notify();
  }

  /// Creates ([product] `null`) or edits a product: its columns, how it is made and everything
  /// it consumes in one call (all or nothing). A table without a name or a price column gets it
  /// first, named [nameTitle] / [priceTitle]: a made product always has both. `false` keeps the
  /// form open; the refusal was shown as it came.
  Future<bool> save(
    BuildContext context, {
    MadeProduct? product,
    required MadeProductDraft draft,
    required String nameTitle,
    required String priceTitle
  }) async {
    try {
      await _ensure(nameTitle: nameTitle, priceTitle: priceTitle);

      final values = {
        ...draft.values,
        _fields.name!.id: draft.name.trim(),
        _fields.price!.id: draft.price.trim()
      };

      if (product == null) {
        await _inventory.createRecord(createRecordRequest(
          tableId: tableId,
          values: {for (final MapEntry(:key, :value) in values.entries) if (value.isNotEmpty) key: value},
          consumes: draft.lines,
          batch: draft.mode == RecipeMode.batch
        ));
      } else {
        // Only what changed: a column nobody touched is not rewritten.
        final changed = {
          for (final MapEntry(:key, :value) in values.entries)
            if (value != product.values[key] && (value.isNotEmpty || product.values.containsKey(key))) key: value
        };

        await _inventory.editRecord(editRecordRequest(
          tableId: tableId,
          id: product.id,
          values: changed.isEmpty ? null : changed,
          consumes: draft.lines,
          batch: draft.mode == RecipeMode.batch
        ));
      }
    } catch (error) {
      if (context.mounted) KitchenApi.report(context, "saveMadeProduct", error);
      return false;
    }

    await _first();
    return true;
  }

  /// Creates the name and price columns a made table lacks, and reads its structure again.
  Future<void> _ensure({required String nameTitle, required String priceTitle}) async {
    if (_fields.name != null && _fields.price != null) return;

    var position = _structure.fields.length;

    if (_fields.name == null) {
      await _inventory.createField(createFieldRequest(
        tableId: tableId,
        name: nameTitle,
        description: "",
        type: TableFieldType.title.value,
        position: position++
      ));
    }

    if (_fields.price == null) {
      await _inventory.createField(createFieldRequest(
        tableId: tableId,
        name: priceTitle,
        description: "",
        type: TableFieldType.price.value,
        position: position
      ));
    }

    _structure = await _inventory.structure(tableId);
    _fields = MadeFields.of(_structure.fields);

    if (_fields.name == null || _fields.price == null) throw {"message": S.current.made_product_fields_error};
  }

  /// What was written elsewhere (the kitchen's panel: a pause, a batch): the first page again.
  Future<void> refresh() => _first();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _search.dispose();
    super.dispose();
  }
}
