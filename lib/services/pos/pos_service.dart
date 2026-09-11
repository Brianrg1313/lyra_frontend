import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/toolkit/api.dart';

enum PosSummaryStatus { idle, loading, ready, error }

/// What POS mode shows as soon as it opens: how much the person attending has
/// sold today (`GET /pos/`).
///
/// The backend answers with the session and not with an id (see the endpoint), so
/// [mineSales] is always of whoever is logged in and not of a chosen seller.
///
/// The same call brings [categories], the labels the product picker groups the
/// catalog by. They travel with the summary and not in a request of their own
/// because they are read once, when the register opens, and do not change while
/// somebody is ringing sales up.
///
/// It is ephemeral: the POS page owns it and it is discarded when leaving it.
class PosService extends ChangeNotifier {
  PosSummaryStatus _status = PosSummaryStatus.idle;
  int _mineSales = 0;
  List<String> _categories = const [];

  PosSummaryStatus get status => _status;

  /// How many sales the person attending completed today.
  int get mineSales => _mineSales;

  /// Categories of the company's main table, in the order the backend sends
  /// them. Empty is the ordinary case —most imported price lists have no
  /// category column— and not a failure: the picker just shows no filters.
  List<String> get categories => _categories;

  /// Reads the day's summary. Without [force] it does not ask for it again if it is already read.
  Future<void> load({bool force = false}) async {
    if (_status == PosSummaryStatus.loading) return;
    if (!force && _status == PosSummaryStatus.ready) return;

    _status = PosSummaryStatus.loading;
    notifyListeners();

    final data = await api.get(path: "/pos/", version: "v1").catchError((E) {
      if (kDebugMode) print(E);
      return null;
    });

    if (data is! Map) {
      _status = PosSummaryStatus.error;
      notifyListeners();
      return;
    }

    final mine = data["mine"];
    _mineSales = mine is Map ? ((mine["sales"] as num?)?.toInt() ?? 0) : 0;

    final categories = data["categories"];
    _categories = categories is List
      ? categories.whereType<String>().where((label) => label.isNotEmpty).toList(growable: false)
      : const [];

    _status = PosSummaryStatus.ready;

    notifyListeners();
  }

  /// Retries after an error.
  Future<void> retry() => load(force: true);
}
