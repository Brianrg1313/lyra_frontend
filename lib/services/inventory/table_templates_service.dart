import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/inventory/table_template_model.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/toolkit/backend/deployment.dart';

enum TableTemplatesStatus { idle, loading, ready, empty, error }

/// The starting tables offered to a company with no table yet
/// (`GET /inventory/products/builder/templates/`, by the company's activity).
///
/// Owned by the inventory section's empty state and created only there: a company that
/// already has tables never asks for them. [empty] is a master's company (no catalogue)
/// or one the backend offered nothing: the blank table and the import still are.
class TableTemplatesService extends ChangeNotifier {
  TableTemplatesService({InventorySource? source}) : _injected = source;

  final InventorySource? _injected;

  InventorySource get _source => _injected ?? Sources.inventory;

  TableTemplatesStatus _status = TableTemplatesStatus.idle;
  List<TableTemplateModel> _templates = const [];

  bool _disposed = false;

  TableTemplatesStatus get status => _status;
  List<TableTemplateModel> get templates => _templates;

  Future<void> load() async {
    if (_status == TableTemplatesStatus.loading) return;

    _status = TableTemplatesStatus.loading;
    notifyListeners();

    try {
      _templates = await _source.templates();
      _status = _templates.isEmpty ? TableTemplatesStatus.empty : TableTemplatesStatus.ready;
    } catch (error) {
      if (kDebugMode) print("loadTableTemplates failed: $error");
      _templates = const [];
      _status = TableTemplatesStatus.error;
    }

    if (!_disposed) notifyListeners();
  }

  /// Seam for tests.
  @visibleForTesting
  void seed(List<TableTemplateModel> templates) {
    _templates = templates;
    _status = templates.isEmpty ? TableTemplatesStatus.empty : TableTemplatesStatus.ready;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
