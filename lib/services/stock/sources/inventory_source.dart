import 'dart:io';

// SERVICES
import 'package:app/services/inventory/import_file.dart';
import 'package:app/services/inventory/table_template_model.dart';
import 'package:app/services/inventory/product_image.dart';
import 'package:app/services/stock/tables/table_detail_model.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/table_normalize_model.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_model.dart';

/// Product tables: structure, fields, records, images, import
/// (`docs/offline/specs/inventory.md`).
///
/// Throws the normalised error (`{message, action}`), or `UnreadableAnswer` for an
/// answer its model can't read. A model that reads a broken answer as empty
/// (`TableDetailModel.isEmpty`) is answered as is: its service already tells
/// that apart. Write bodies are the `*_request.dart` maps the services build; a
/// delete takes ids.
abstract interface class InventorySource {
  Future<List<TableLiteModel>> tables();

  /// The starting tables offered to the company's activity. Cloud only: a master has no
  /// catalogue and answers none.
  Future<List<TableTemplateModel>> templates();

  /// Creates a table's structure; answers its id.
  Future<String> createTable(Map<String, dynamic> request);

  Future<void> editTable(Map<String, dynamic> request);

  Future<void> deleteTable(String id);

  /// Creates a table from a spreadsheet's header row; answers its id. The rows
  /// follow with [importRecords] once the table is ready.
  Future<String> importStructure(
    ImportFormat format,
    File file, {
    required String name,
    required int headerRow
  });

  Future<void> importRecords(
    ImportFormat format,
    File file, {
    required String tableId,
    required int headerRow
  });

  Future<TableDetailModel> detail(String tableId);

  Future<void> editDetail(Map<String, dynamic> request);

  Future<TableStructureModel> structure(String tableId);

  Future<void> createField(Map<String, dynamic> request);

  Future<void> editField(Map<String, dynamic> request);

  Future<void> deleteField(String id);

  /// One page of records, and how many match when searching (null when the
  /// answer doesn't say).
  Future<({TableViewModel page, int? total})> records(
    String tableId, {
    required int page,
    required int size,
    String match = ""
  });

  /// Creates a record and returns its id (empty when the answer does not say it).
  Future<String> createRecord(Map<String, dynamic> request);

  Future<void> editRecord(Map<String, dynamic> request);

  Future<void> deleteRecord(String tableId, String id);

  /// Sets what [productId]'s stock is counted in (`cocina-frontend.md` §8); empty takes it
  /// back to its stock column's. With [convert] its figures follow, between units of one
  /// magnitude. Cloud only: a master keeps no unit per product.
  Future<void> setUnit({required String tableId, required String productId, required String unit, bool convert = false});

  /// Adds a photo to a record; answers its whole gallery as stored.
  Future<List<ProductImage>> addImage(String tableId, String recordId, File file);

  Future<void> removeImage(String tableId, String recordId, String fileId);

  /// Cloud only (AI normalisation).
  Future<TableNormalizeModel> normalize(String tableId, {required Duration timeout});
}
