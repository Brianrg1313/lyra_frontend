import 'dart:io';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/services/inventory/import_file.dart';
import 'package:app/services/inventory/product_image.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/services/stock/tables/table_detail_model.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/table_normalize_model.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_model.dart';
import 'package:app/toolkit/deployment.dart';

/// [InventorySource] over the master (`docs/offline/specs/inventory.md`).
///
/// The services build the cloud's bodies (`*_request.dart`, `TABLE_ID`, `DATA`); [args] turns
/// their keys into the spec's (`tableId`, `data`), and the master answers in the shapes the
/// models already read, so no model or screen changes (plan principle 8). Importing a
/// spreadsheet and re-typing its columns arrive in a later release: `CapabilityService` hides
/// them on a master until then.
class InventoryLanSource implements InventorySource {
  const InventoryLanSource(this._lan);

  final LanService _lan;

  /// A cloud body's keys in the spec's spelling: `TABLE_ID` → `tableId`, `TITLE` → `title`.
  static Map<String, Object?> args(Map<String, dynamic> request) => {
    for (final entry in request.entries) _camel(entry.key): entry.value,
  };

  static String _camel(String key) {
    final parts = key.toLowerCase().split("_");

    return parts.first + parts.skip(1).map((part) => part.isEmpty ? "" : part[0].toUpperCase() + part.substring(1)).join();
  }

  @override
  Future<List<TableLiteModel>> tables() async {
    final answer = await _lan.call(Ops.inventoryTablesList);
    if (answer is! List) throw const UnreadableAnswer("inventory.tables.list");

    return TableLiteModel.fromResponse(answer);
  }

  @override
  Future<String> createTable(Map<String, dynamic> request) async {
    final answer = await _lan.call(Ops.inventoryTablesCreate, args: args(request));
    final id = answer is Map ? answer["id"] : null;
    if (id is! String) throw const UnreadableAnswer("inventory.tables.create");

    return id;
  }

  @override
  Future<void> editTable(Map<String, dynamic> request) => _lan.call(Ops.inventoryTablesEdit, args: args(request));

  @override
  Future<void> deleteTable(String id) => _lan.call(Ops.inventoryTablesDelete, args: {"id": id});

  @override
  Future<TableDetailModel> detail(String tableId) async =>
    TableDetailModel.fromResponse(await _lan.call(Ops.inventoryTablesDetails, args: {"id": tableId}));

  /// The settings screen's partial edit is `inventory.tables.edit` with only what changed.
  @override
  Future<void> editDetail(Map<String, dynamic> request) => _lan.call(Ops.inventoryTablesEdit, args: args(request));

  @override
  Future<TableStructureModel> structure(String tableId) async {
    final answer = await _lan.call(Ops.inventoryTablesStructure, args: {"id": tableId});
    if (answer is! Map) throw const UnreadableAnswer("inventory.tables.structure");

    return TableStructureModel.fromResponse(answer);
  }

  @override
  Future<void> createField(Map<String, dynamic> request) => _lan.call(Ops.inventoryFieldsCreate, args: args(request));

  @override
  Future<void> editField(Map<String, dynamic> request) => _lan.call(Ops.inventoryFieldsEdit, args: args(request));

  @override
  Future<void> deleteField(String id) => _lan.call(Ops.inventoryFieldsDelete, args: {"id": id});

  @override
  Future<({TableViewModel page, int? total})> records(
    String tableId, {
    required int page,
    required int size,
    String match = ""
  }) async {
    final answer = await _lan.call(Ops.inventoryRecordsList, args: {
      "tableId": tableId,
      "page": page,
      "size": size,
      if (match.isNotEmpty) "match": match
    });
    if (answer is! Map) throw const UnreadableAnswer("inventory.records.list");

    final total = answer["total"];

    return (page: TableViewModel.fromResponse(answer), total: total is int ? total : null);
  }

  @override
  Future<void> createRecord(Map<String, dynamic> request) => _lan.call(Ops.inventoryRecordsCreate, args: args(request));

  @override
  Future<void> editRecord(Map<String, dynamic> request) => _lan.call(Ops.inventoryRecordsEdit, args: args(request));

  /// The photo goes up first (`PUT /f`, purpose `product_image`), then the op takes it into the
  /// record's image cell (I-30).
  @override
  Future<List<ProductImage>> addImage(String tableId, String recordId, File file) async {
    final fileId = await _lan.upload("product_image", await file.readAsBytes());

    return ProductImage.fromResponse(await _lan.call(Ops.inventoryImagesAdd, args: {
      "tableId": tableId,
      "productId": recordId,
      "fileId": fileId
    }));
  }

  @override
  Future<void> removeImage(String tableId, String recordId, String fileId) => _lan.call(
    Ops.inventoryImagesRemove,
    args: {"tableId": tableId, "productId": recordId, "fileId": fileId}
  );

  @override
  Future<String> importStructure(
    ImportFormat format,
    File file, {
    required String name,
    required int headerRow
  }) => throw UnsupportedError("Importing on a master arrives in a later release");

  @override
  Future<void> importRecords(
    ImportFormat format,
    File file, {
    required String tableId,
    required int headerRow
  }) => throw UnsupportedError("Importing on a master arrives in a later release");

  @override
  Future<TableNormalizeModel> normalize(String tableId, {required Duration timeout}) =>
    throw UnsupportedError("Re-typing columns on a master arrives with importing");
}
