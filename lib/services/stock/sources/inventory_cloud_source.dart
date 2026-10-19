import 'dart:io';

// SERVICES
import 'package:app/services/inventory/import_file.dart';
import 'package:app/services/inventory/product_image.dart';
import 'package:app/services/inventory/table_record_request.dart' show createdRecordId;
import 'package:app/services/inventory/table_field_request.dart';
import 'package:app/services/inventory/table_request.dart';
import 'package:app/services/inventory/table_template_model.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/services/stock/tables/table_detail_model.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/table_normalize_model.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_model.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/deployment.dart';

/// Name of the form field a file travels under (a spreadsheet to import, a
/// product photo). The backend decides it: it's the one its multipart reads,
/// and with any other name the request arrives without a file.
const String _kFileField = "FILE";

/// [InventorySource] over the backend's REST api.
class InventoryCloudSource implements InventorySource {
  const InventoryCloudSource();

  /// An empty answer is a failed read, not a company without tables.
  @override
  Future<List<TableLiteModel>> tables() async {
    final data = await api.get(path: "/inventory/products/builder/list/", version: "v1");
    if (data == null) throw const UnreadableAnswer("builder/list");

    return TableLiteModel.fromResponse(data);
  }

  @override
  Future<List<TableTemplateModel>> templates() async {
    final data = await api.get(path: "/inventory/products/builder/templates/", version: "v1");
    if (data is! Map) throw const UnreadableAnswer("builder/templates");

    return TableTemplateModel.listFrom(data["templates"]);
  }

  @override
  Future<String> createTable(Map<String, dynamic> request) async => _readId(
    await api.post(path: "/inventory/products/builder/structure/", version: "v1", data: request)
  );

  @override
  Future<void> editTable(Map<String, dynamic> request) =>
    api.put(path: "/inventory/products/builder/structure/", version: "v1", data: request);

  @override
  Future<void> deleteTable(String id) => api.delete(
    path: "/inventory/products/builder/structure/",
    version: "v1",
    data: deleteTableRequest(id: id)
  );

  @override
  Future<String> importStructure(
    ImportFormat format,
    File file, {
    required String name,
    required int headerRow
  }) async => _readId(await api.file(
    path: "/inventory/products/import/structure/${format.segment}/",
    version: "v1",
    file: file,
    field: _kFileField,
    // An empty name isn't sent: sending it would cover up the one the
    // backend pulls from the file, and the table would be born called
    // "table".
    data: {if (name.isNotEmpty) "NAME": name, "ROW": "$headerRow"}
  ));

  @override
  Future<void> importRecords(
    ImportFormat format,
    File file, {
    required String tableId,
    required int headerRow
  }) => api.file(
    path: "/inventory/products/import/records/${format.segment}/",
    version: "v1",
    file: file,
    field: _kFileField,
    data: {"TABLE_ID": tableId, "ROW": "$headerRow"}
  );

  /// No trailing slash: the table id is a route segment (`params:
  /// ["TABLE_ID"]`), and an extra slash would leave it empty on the other side.
  @override
  Future<TableDetailModel> detail(String tableId) async {
    final data = await api.get(path: "/inventory/products/builder/details/$tableId", version: "v1");
    if (data == null) throw const UnreadableAnswer("builder/details");

    return TableDetailModel.fromResponse(data);
  }

  @override
  Future<void> editDetail(Map<String, dynamic> request) =>
    api.put(path: "/inventory/products/builder/details/", version: "v1", data: request);

  @override
  Future<TableStructureModel> structure(String tableId) async {
    final data = await api.get(path: "/inventory/products/builder/structure/$tableId", version: "v1");
    if (data == null) throw const UnreadableAnswer("builder/structure");

    return TableStructureModel.fromResponse(data);
  }

  @override
  Future<void> createField(Map<String, dynamic> request) =>
    api.post(path: "/inventory/products/builder/fields/", version: "v1", data: request);

  @override
  Future<void> editField(Map<String, dynamic> request) =>
    api.put(path: "/inventory/products/builder/fields/", version: "v1", data: request);

  @override
  Future<void> deleteField(String id) => api.delete(
    path: "/inventory/products/builder/fields/",
    version: "v1",
    data: deleteFieldRequest(id: id)
  );

  @override
  Future<({TableViewModel page, int? total})> records(
    String tableId, {
    required int page,
    required int size,
    String match = ""
  }) async {
    final data = await api.post(
      path: "/inventory/products/records/list/",
      version: "v1",
      data: {
        "TABLE_ID": tableId,
        "PAGE": page,
        "SIZE": size,
        if (match.isNotEmpty) "MATCH": match
      }
    );

    if (data == null) throw const UnreadableAnswer("records/list");

    return (page: TableViewModel.fromResponse(data, tableId: tableId), total: _totalOf(data));
  }

  @override
  Future<String> createRecord(Map<String, dynamic> request) async =>
    createdRecordId(await api.post(path: "/inventory/products/records/manage/", version: "v1", data: request));

  @override
  Future<void> editRecord(Map<String, dynamic> request) =>
    api.put(path: "/inventory/products/records/manage/", version: "v1", data: request);

  @override
  Future<void> setUnit({required String tableId, required String productId, required String unit}) =>
    api.put(
      path: "/inventory/units/",
      version: "v1",
      data: {"TABLE_ID": tableId, "PRODUCT_ID": productId, "UNIT": unit}
    );

  @override
  Future<List<ProductImage>> addImage(String tableId, String recordId, File file) async =>
    ProductImage.fromResponse(await api.file(
      path: "/inventory/products/records/images/",
      version: "v1",
      file: file,
      field: _kFileField,
      data: {"TABLE_ID": tableId, "PRODUCT_ID": recordId}
    ));

  @override
  Future<void> removeImage(String tableId, String recordId, String fileId) => api.delete(
    path: "/inventory/products/records/images/$tableId/$recordId/$fileId",
    version: "v1"
  );

  @override
  Future<TableNormalizeModel> normalize(String tableId, {required Duration timeout}) async =>
    TableNormalizeModel.fromResponse(await api.post(
      path: "/inventory/products/builder/normalize/",
      version: "v1",
      data: {"TABLE_ID": tableId},
      timeout: timeout
    ));

  /// The created table's id. The backend can return it bare (`5`, `"5"`) or
  /// wrapped in an object (`{"id": 5}`), so both forms are checked before
  /// giving up.
  static String _readId(dynamic response) {
    if (response is Map) {
      final id = response["id"] ?? response["table_id"] ?? response["ID"];
      if (id != null) return id.toString();

      throw {"message": "The table was created but no id came back"};
    }

    if (response == null) {
      throw {"message": "The table was not created (empty response)"};
    }

    return response.toString();
  }

  /// How many records match a search, when the answer says.
  static int? _totalOf(dynamic data) {
    if (data is! Map) return null;

    final total = data["total"] ?? data["TOTAL"];

    if (total is num) return total.toInt();
    return int.tryParse(total?.toString() ?? "");
  }
}
