import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/money/money_receivable_model.dart';
import 'package:app/services/money/sources/money_source.dart';
import 'package:app/toolkit/deployment.dart';

enum MoneyReceivablesStatus { idle, loading, ready, empty, error }

/// What the company is still owed (`POST /money/receivables`): the tickets that
/// went out on credit, what has been collected against each one and what is
/// left.
///
/// It is the other half of the money screen's `credit` figure. That number says
/// how much went out unpaid in a window; this list says **who owes it**, which
/// is the question somebody opens this tab to answer.
///
/// It opens showing only the tickets that still owe something ([openOnly]),
/// which is the backend's own default: a list that starts with every credit
/// sale ever made buries the handful that matter. The window filters by when
/// the ticket was **sold**, and what was collected against it counts whenever
/// it happened — a debt does not stop being owed because the window moved.
///
/// Nothing here charges interest, ages a debt into buckets or writes one off:
/// it is a list of who owes what. The money for it arrives as a settlement
/// payment naming the ticket, which is recorded from the payments tab and is
/// what pays the balance down.
///
/// It is ephemeral: owned by the finance section and discarded when leaving it.
class MoneyReceivablesService extends ChangeNotifier {
  MoneyReceivablesService({MoneySource? source}) : _injected = source;

  final MoneySource? _injected;

  MoneySource get _source => _injected ?? Sources.money;

  /// How many tickets are read at a time. The backend caps the page at 200.
  static const int _pageSize = 50;

  MoneyReceivablesStatus _status = MoneyReceivablesStatus.idle;

  final List<MoneyReceivable> _sales = [];
  MoneyReceivableTotals _totals = const MoneyReceivableTotals();

  String _currency = "";
  int _total = 0;
  int _page = 0;

  bool _reading = false;
  bool _moreFailed = false;
  int _generation = 0;

  bool _openOnly = true;

  MoneyReceivablesStatus get status => _status;
  List<MoneyReceivable> get sales => _sales;

  /// How much was sold on credit under the filter, how much of it has been
  /// collected and how much is outstanding. They are the filter's numbers and
  /// not the page's.
  MoneyReceivableTotals get totals => _totals;

  /// The company's currency, answered once for the whole page.
  String get currency => _currency;

  /// How many credit tickets match the filter, not how many were read.
  int get total => _total;

  bool get hasMore => _sales.length < _total;
  bool get moreFailed => _moreFailed;

  /// Whether only the tickets still owing something are listed.
  bool get openOnly => _openOnly;

  Future<void> load({bool force = false}) {
    if (!force && _status != MoneyReceivablesStatus.idle) return Future.value();

    return _read(1, reset: true);
  }

  Future<void> retry() => _read(1, reset: true);

  /// Rereads from the first page. It is what runs after a settlement is
  /// recorded or voided: both move a ticket's balance, and one of them can take
  /// it out of this list entirely.
  Future<void> refresh() => _read(1, reset: true);

  /// Shows every credit sale, settled ones included, or only the open ones.
  Future<void> showOpenOnly(bool value) {
    if (value == _openOnly) return Future.value();

    _openOnly = value;

    return _read(1, reset: true);
  }

  Future<void> more() {
    if (_reading || _moreFailed || !hasMore) return Future.value();

    return _read(_page + 1);
  }

  Future<void> retryMore() {
    if (_reading || !hasMore) return Future.value();

    _moreFailed = false;

    return _read(_page + 1);
  }

  Future<void> _read(int page, {bool reset = false}) async {
    if (_reading && !reset) return;

    _reading = true;
    _moreFailed = false;

    if (reset) {
      _generation++;
      _sales.clear();
      _page = 0;
      _status = MoneyReceivablesStatus.loading;
      notifyListeners();
    }

    final generation = _generation;

    final MoneyReceivablesPage result;

    try {
      result = await _source.receivables(page: page, size: _pageSize, openOnly: _openOnly);
    } catch (error) {
      if (kDebugMode) print("loadReceivables failed: $error");

      if (generation != _generation) return;

      _reading = false;
      _nothing();
      notifyListeners();

      return;
    }

    if (generation != _generation) return;

    _reading = false;

    if (!result.isLoaded) {
      _nothing();
      notifyListeners();

      return;
    }

    _total = result.total;
    _totals = result.totals;
    _currency = result.currency;
    _page = page;

    _sales.addAll(result.sales);

    // A batch that comes back empty is the end, whatever the total says:
    // between the tickets being counted and the page being asked for, one could
    // have been settled out of the filter.
    if (result.sales.isEmpty) _total = _sales.length;

    _status = _sales.isEmpty
      ? MoneyReceivablesStatus.empty
      : MoneyReceivablesStatus.ready;

    notifyListeners();
  }

  void _nothing() {
    if (_sales.isEmpty) {
      _status = MoneyReceivablesStatus.error;
      return;
    }

    _moreFailed = true;
  }
}
