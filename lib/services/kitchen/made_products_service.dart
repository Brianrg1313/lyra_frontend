import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:app/toolkit/toolkit.dart' show S;

// SERVICES
import 'package:app/services/files/image_file.dart';
import 'package:app/services/inventory/product_image.dart';
import 'package:app/services/inventory/table_field_request.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/inventory/table_record_request.dart';
import 'package:app/services/kitchen/kitchen_api.dart';
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/kitchen_product_search.dart';
import 'package:app/services/kitchen/kitchen_report_model.dart';
import 'package:app/services/kitchen/kitchen_request.dart';
import 'package:app/services/kitchen/made_kitchen_api.dart';
import 'package:app/services/kitchen/made_product_model.dart';
import 'package:app/services/kitchen/modifier_model.dart';
import 'package:app/services/kitchen/recipe_model.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/toolkit/deployment.dart';

enum MadeProductsStatus { loading, ready, empty, error }

/// What a save does with a product's photo: nothing, a new one in place of its cover, or none.
@immutable
class MadePhoto {
  const MadePhoto.keep() : bytes = null, remove = false;
  const MadePhoto.remove() : bytes = null, remove = true;
  const MadePhoto.replace(Uint8List this.bytes) : remove = false;

  final Uint8List? bytes;
  final bool remove;

  bool get changes => bytes != null || remove;
}

/// A modifier group as the product's form leaves it: its content ([ModifierGroup.id] empty on a
/// new one) and whether the form changed it. Its `products` are the others offering it: the
/// product itself is added on save, since a new one has no id yet.
typedef MadeGroupChoice = ({ModifierGroup group, bool edited});

/// What the form of a made product saves: its columns' values by FIELD_ID (the name, the price
/// and the description by their own, since their columns may not exist yet), columns to create
/// with their value (title → value), its photo, how it is made, what it consumes and the
/// modifier groups it offers (`null`: as they are).
typedef MadeProductDraft = ({
  String name,
  String price,
  String description,
  Map<String, String> values,
  Map<String, String> added,
  MadePhoto photo,
  RecipeMode mode,
  List<RecipeLineDraft> lines,
  List<MadeGroupChoice>? groups
});

/// The products of one `made` table, as a list of forms and not a sheet: each one is a name, a
/// price and what it consumes (`cocina-frontend.md` §3), written in one `records/manage` call,
/// and around it what the form adds: a photo, a description, the table's other columns and the
/// modifier groups it offers (§6).
///
/// Owned by the made products view, per open table. It reads the structure once, then pages of
/// records (with what each consumes and can be sold now), the supplies' products once, by id, so
/// a line says its unit (`kitchenUnitsFor`): the backend answers lines without one, and the
/// company's modifier groups.
class MadeProductsService extends ChangeNotifier {
  MadeProductsService({
    required this.tableId,
    InventorySource? source,
    KitchenProductSearch? search,
    MadeKitchenApi kitchen = const MadeKitchenApi()
  }) : _source = source,
       _kitchen = kitchen,
       _search = search ?? KitchenProductSearch(inventory: source);

  final String tableId;
  final InventorySource? _source;
  final MadeKitchenApi _kitchen;
  final KitchenProductSearch _search;

  InventorySource get _inventory => _source ?? Sources.inventory;

  static const int _size = 50;

  MadeProductsStatus _status = MadeProductsStatus.loading;
  TableStructureModel _structure = const TableStructureModel();
  MadeFields _fields = const MadeFields();
  List<MadeProduct> _products = const [];
  Map<String, KitchenProduct> _supplies = const {};
  List<ModifierGroup> _groups = const [];
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

  /// Every modifier group of the company, in order (none when the read failed).
  List<ModifierGroup> get groups => _groups;

  /// The groups [productId] offers.
  List<ModifierGroup> groupsOf(String productId) => [
    for (final group in _groups)
      if (group.products.any((product) => product.productId == productId)) group
  ];

  /// What making one with [lines] costs, from what each supply costs, before it is saved: its
  /// form costs the recipe as it is typed. `null` when it can't be told (a line the backend
  /// refuses, a viewer without the kitchen's reports, a failed read).
  Future<DishCost?> costOf({required RecipeMode mode, required List<RecipeLineDraft> lines}) async {
    try {
      return await _kitchen.draftCost(tableId: tableId, mode: mode, lines: lines);
    } catch (error) {
      if (kDebugMode) print("made product cost failed: $error");
      return null;
    }
  }

  /// Reads the structure, the first page, the supplies and the modifier groups.
  Future<void> load({String query = ""}) async {
    _query = query.trim();
    _status = MadeProductsStatus.loading;
    _notify();

    try {
      final reads = await Future.wait([_inventory.structure(tableId), _search.suppliesById(), _readGroups()]);

      _structure = reads[0] as TableStructureModel;
      _supplies = reads[1] as Map<String, KitchenProduct>;
      _groups = reads[2] as List<ModifierGroup>;
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

  /// The groups, none when they can't be read: a product then offers what it offered.
  Future<List<ModifierGroup>> _readGroups() async {
    try {
      return await _kitchen.groups();
    } catch (error) {
      if (kDebugMode) print("made products groups failed: $error");
      return const [];
    }
  }

  Future<List<MadeProduct>> _read(int page) async {
    final answer = await _inventory.records(tableId, page: page, size: _size, match: _query);
    final products = MadeProduct.listFrom(answer.page.alignedTo(_structure.fields), image: _fields.image);

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
  /// first, named [nameTitle] / [priceTitle]: a made product always has both; one without a
  /// description column gets it, named [descriptionTitle], with the first description written,
  /// and the draft's added columns are created the same way. `false` keeps the form open; the
  /// refusal was shown as it came.
  ///
  /// The photo and the groups follow the record, each its own call (a photo is uploaded against
  /// a record that exists; a group is the company's, shared by the products that offer it). One
  /// of them failing is said, and the product stays saved: saving it again would make another.
  Future<bool> save(
    BuildContext context, {
    MadeProduct? product,
    required MadeProductDraft draft,
    required String nameTitle,
    required String priceTitle,
    String descriptionTitle = ""
  }) async {
    final String id;

    try {
      final added = await _ensure(
        nameTitle: nameTitle,
        priceTitle: priceTitle,
        descriptionTitle: draft.description.trim().isEmpty ? "" : descriptionTitle,
        added: draft.added.keys.toSet()
      );

      final values = {
        ...draft.values,
        for (final MapEntry(:key, :value) in draft.added.entries)
          if (added[key] != null) added[key]!: value.trim(),
        if (_fields.description != null) _fields.description!.id: draft.description.trim(),
        _fields.name!.id: draft.name.trim(),
        _fields.price!.id: draft.price.trim()
      };

      if (product == null) {
        id = await _inventory.createRecord(createRecordRequest(
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

        id = product.id;
      }
    } catch (error) {
      if (context.mounted) KitchenApi.report(context, "saveMadeProduct", error);
      return false;
    }

    try {
      await _photo(id, product, draft.photo);
    } catch (error) {
      if (context.mounted) KitchenApi.report(context, "madeProductPhoto", error);
    }

    if (draft.groups != null) {
      try {
        await _offer(id, draft.groups!);
      } catch (error) {
        if (context.mounted) KitchenApi.report(context, "madeProductGroups", error);
      }

      _groups = await _readGroups();
    }

    await _first();
    return true;
  }

  /// The cover replaced or taken off. A new one goes after the photos the product already has
  /// (the gallery appends), its old cover removed: a product with only one photo, which is what
  /// a form shows, gets it as its cover. A photo an import brought is the record's own value,
  /// emptied as one.
  Future<void> _photo(String id, MadeProduct? product, MadePhoto photo) async {
    if (!photo.changes) return;

    final cover = product?.cover;

    if (cover != null && cover.isStored) {
      await _inventory.removeImage(tableId, id, cover.id);
    } else if (cover != null && _fields.image != null) {
      final left = [for (final image in product!.images) if (image != cover) image];

      await _inventory.editRecord(editRecordRequest(
        tableId: tableId,
        id: id,
        values: {_fields.image!.id: ProductImage.valuesOf(left)}
      ));
    }

    final bytes = photo.bytes;
    if (bytes == null) return;

    // The upload travels as multipart, which asks for a file.
    final file = await writeTempImage(bytes, name: "product");

    try {
      await _inventory.addImage(tableId, id, file);
    } finally {
      await discardTempImage(file);
    }
  }

  /// Writes the groups [id] offers: a new or edited one with its content, one it starts offering
  /// with it among its products, and one it stopped offering without it. The others offering a
  /// group keep it.
  Future<void> _offer(String id, List<MadeGroupChoice> choices) async {
    final before = groupsOf(id);
    final kept = {for (final choice in choices) if (choice.group.id.isNotEmpty) choice.group.id};
    final self = (tableId: tableId, productId: id);

    Future<void> write(ModifierGroup group, List<ModifierProduct> products) => _kitchen.saveGroup(saveModifierGroupRequest(
      id: group.id,
      name: group.name,
      min: group.min,
      max: group.max,
      position: group.id.isEmpty ? null : group.position,
      products: products,
      options: group.options
    ));

    for (final (:group, :edited) in choices) {
      final offered = before.any((known) => known.id == group.id);
      if (offered && !edited) continue;

      await write(group, [
        for (final product in group.products) if (product.productId != id) product,
        self
      ]);
    }

    for (final group in before) {
      if (kept.contains(group.id)) continue;

      await write(group, [for (final product in group.products) if (product.productId != id) product]);
    }
  }

  /// Creates the columns a made table lacks — the name and price always, the description when
  /// [descriptionTitle] is given, and [added] by their titles — and reads its structure again.
  /// Answers the [added] titles' FIELD_IDs (a title the table already has is that column).
  Future<Map<String, String>> _ensure({
    required String nameTitle,
    required String priceTitle,
    String descriptionTitle = "",
    Set<String> added = const {}
  }) async {
    String? idOf(String title) => _structure.fields
      .where((field) => field.name.trim().toLowerCase() == title.trim().toLowerCase())
      .firstOrNull?.id;

    final missing = {for (final title in added) if (idOf(title) == null) title.trim()};
    final description = _fields.description == null && descriptionTitle.isNotEmpty;

    if (_fields.name != null && _fields.price != null && !description && missing.isEmpty) {
      return {for (final title in added) title: ?idOf(title)};
    }

    var position = _structure.fields.length;

    Future<void> create(String name, TableFieldType type) => _inventory.createField(createFieldRequest(
      tableId: tableId,
      name: name,
      description: "",
      type: type.value,
      position: position++
    ));

    if (_fields.name == null) await create(nameTitle, TableFieldType.title);
    if (_fields.price == null) await create(priceTitle, TableFieldType.price);
    if (description) await create(descriptionTitle, TableFieldType.description);

    for (final title in missing) {
      await create(title, TableFieldType.text);
    }

    _structure = await _inventory.structure(tableId);
    _fields = MadeFields.of(_structure.fields);

    if (_fields.name == null || _fields.price == null) throw {"message": S.current.made_product_fields_error};

    return {for (final title in added) title: ?idOf(title)};
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
