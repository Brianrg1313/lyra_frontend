import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_api.dart';
import 'package:app/services/kitchen/kitchen_report_model.dart';
import 'package:app/services/kitchen/kitchen_request.dart';
import 'package:app/toolkit/api.dart';

/// The kitchen's three reports (`cocina-frontend.md` §9).
enum KitchenReport {
  /// What the branch spent of each supply according to the recipes, and in which dishes.
  consumption,

  /// What really left against what the recipes explain.
  variance,

  /// What making each dish costs (the whole company's purchases).
  cost
}

enum KitchenReportStatus { idle, loading, ready, empty, error }

/// The reports tab: one report at a time over one window of days (both ends optional).
///
/// Owned by the supply chain section. Changing the report or the window reads again; only the
/// last read counts.
class KitchenReportsService extends ChangeNotifier {
  KitchenReport _report = KitchenReport.consumption;
  DateTime? _from;
  DateTime? _to;
  KitchenReportStatus _status = KitchenReportStatus.idle;
  String _reason = "";
  ConsumptionReport _consumption = const ConsumptionReport();
  List<VarianceRow> _variance = const [];
  List<DishCost> _cost = const [];
  int _ticket = 0;
  bool _disposed = false;

  KitchenReport get report => _report;
  DateTime? get from => _from;
  DateTime? get to => _to;
  KitchenReportStatus get status => _status;

  /// The code the last read was refused with (`invalid_field`: the window ends before it starts).
  String get reason => _reason;
  ConsumptionReport get consumption => _consumption;
  List<VarianceRow> get variance => _variance;
  List<DishCost> get cost => _cost;

  Future<void> show(KitchenReport report) async {
    if (report == _report && _status != KitchenReportStatus.idle) return;

    _report = report;
    await load();
  }

  /// Sets the window, whole days; `null` leaves that end open.
  Future<void> window({DateTime? from, DateTime? to}) async {
    _from = from;
    _to = to;
    await load();
  }

  Future<void> load() async {
    final ticket = ++_ticket;
    final report = _report;
    final window = kitchenWindowRequest(from: _from, to: _to);

    _status = KitchenReportStatus.loading;
    _reason = "";
    _notify();

    try {
      final answer = await api.post(path: "/inventory/recipes/${report.name}", version: "v1", data: window);

      if (ticket != _ticket) return;

      final bool empty;

      switch (report) {
        case KitchenReport.consumption:
          _consumption = ConsumptionReport.read(answer);
          empty = _consumption.isEmpty;
        case KitchenReport.variance:
          _variance = VarianceRow.listFrom(answer);
          empty = _variance.isEmpty;
        case KitchenReport.cost:
          _cost = DishCost.listFrom(answer);
          empty = _cost.isEmpty;
      }

      _status = empty ? KitchenReportStatus.empty : KitchenReportStatus.ready;
    } catch (error) {
      if (kDebugMode) print("kitchen ${report.name} failed: $error");
      if (ticket != _ticket) return;

      if (error is Map && error["action"] != null) throw error["action"];

      _reason = KitchenApi.reason(error);
      _status = KitchenReportStatus.error;
    }

    _notify();
  }

  /// Seeds a report, for tests.
  @visibleForTesting
  void seed({
    KitchenReport report = KitchenReport.consumption,
    ConsumptionReport consumption = const ConsumptionReport(),
    List<VarianceRow> variance = const [],
    List<DishCost> cost = const []
  }) {
    _report = report;
    _consumption = consumption;
    _variance = variance;
    _cost = cost;
    _status = KitchenReportStatus.ready;
    _notify();
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
