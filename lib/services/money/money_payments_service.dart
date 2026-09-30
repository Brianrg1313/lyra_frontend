import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// SERVICES
import 'package:app/services/money/money_concept_model.dart';
import 'package:app/services/money/money_payment_model.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/services/money/sources/money_source.dart';
import 'package:app/toolkit/deployment.dart';

enum MoneyPaymentsStatus { idle, loading, ready, empty, error }

/// The history of what the company received and what it paid
/// (`POST /money/payments/search`), plus the two writes that touch it:
/// recording a movement and voiding one.
///
/// **This is only the money that is not a sale.** A ticket's own payment lives
/// on the ticket, so what is listed here is everything around it: a supplier
/// paid on Friday, a customer settling their tab. The money screen adds both
/// sides; this list shows one of them.
///
/// The filters are the service's and not the table's because the totals are:
/// the response says what the **whole filter** adds up to, not what the rows on
/// screen do. Filtering in memory would answer "cuanto llevo pagado a
/// proveedores este mes" with the page that was read, which is almost always
/// the wrong number.
///
/// **The rows accumulate.** The first page is read when the tab opens and the
/// next one when the list is about to run out ([more]); how many there are in
/// total is said by the response, which is what tells it when to stop asking.
///
/// It is ephemeral: owned by the finance section and discarded when leaving it.
class MoneyPaymentsService extends ChangeNotifier {
  MoneyPaymentsService({MoneySource? source}) : _injected = source;

  final MoneySource? _injected;

  MoneySource get _source => _injected ?? Sources.money;

  /// How many movements are read at a time. The backend caps the page at 200;
  /// fifty fills the table twice over without making the tab wait for rows
  /// nobody scrolled to.
  static const int _pageSize = 50;

  MoneyPaymentsStatus _status = MoneyPaymentsStatus.idle;

  final List<MoneyPayment> _payments = [];
  MoneyPaymentTotals _totals = const MoneyPaymentTotals();

  int _total = 0;

  /// Last page that came in. Zero while none has.
  int _page = 0;

  bool _reading = false;
  bool _moreFailed = false;

  /// With which filter the read being waited on was made. Whatever arrives with
  /// another generation is discarded: those are the rows of a filter nobody is
  /// looking at any more.
  int _generation = 0;

  MoneyDirection? _direction;
  MoneyPaymentStatus? _state = MoneyPaymentStatus.recorded;
  String _concept = "";
  String _method = "";

  MoneyPaymentsStatus get status => _status;
  List<MoneyPayment> get payments => _payments;

  /// What the whole filter adds up to, in each direction. Not what the rows on
  /// screen do.
  MoneyPaymentTotals get totals => _totals;

  /// How many movements match the filter, not how many were read.
  int get total => _total;

  bool get hasMore => _payments.length < _total;
  bool get moreFailed => _moreFailed;

  /// Which half of the history is being looked at, or null for both.
  MoneyDirection? get direction => _direction;

  /// Which movements are shown. Null is the backend's "all"; the tab opens on
  /// [MoneyPaymentStatus.recorded], which is what actually counts.
  MoneyPaymentStatus? get state => _state;

  String get concept => _concept;
  String get method => _method;

  /// Whether anything narrows the list beyond the state it opens on. It is what
  /// tells an empty history from a filter that matched nothing.
  bool get isFiltered =>
    _direction != null ||
    _concept.isNotEmpty ||
    _method.isNotEmpty ||
    _state != MoneyPaymentStatus.recorded;

  /// Reads the first page. Without [force] it does not ask again once it is
  /// read: the section can be mounted more than once.
  Future<void> load({bool force = false}) {
    if (!force && _status != MoneyPaymentsStatus.idle) return Future.value();

    return _read(1, reset: true);
  }

  Future<void> retry() => _read(1, reset: true);

  /// Rereads from the first page. It is what runs after a write: a recorded
  /// payment changes the totals of the filter, which no local insertion can
  /// compute.
  Future<void> refresh() => _read(1, reset: true);

  /// Asks for the next batch. The table calls it when it is about to run out of
  /// rows, so it can be called too much: with nothing to bring, it does
  /// nothing. With the last batch failed it also does nothing —the list would
  /// ask again every frame— and that brake is lifted by hand, with [retryMore].
  Future<void> more() {
    if (_reading || _moreFailed || !hasMore) return Future.value();

    return _read(_page + 1);
  }

  Future<void> retryMore() {
    if (_reading || !hasMore) return Future.value();

    _moreFailed = false;

    return _read(_page + 1);
  }

  /// Shows one half of the history, or both with null.
  Future<void> filterDirection(MoneyDirection? value) {
    if (value == _direction) return Future.value();

    _direction = value;

    // A concept belongs to a direction, so one that is no longer offered stops
    // filtering: keeping it would leave the list empty for a reason the screen
    // no longer shows.
    _concept = "";

    return _read(1, reset: true);
  }

  Future<void> filterState(MoneyPaymentStatus? value) {
    if (value == _state) return Future.value();

    _state = value;

    return _read(1, reset: true);
  }

  Future<void> filterConcept(String value) {
    if (value == _concept) return Future.value();

    _concept = value;

    return _read(1, reset: true);
  }

  Future<void> filterMethod(String value) {
    if (value == _method) return Future.value();

    _method = value;

    return _read(1, reset: true);
  }

  /// Clears every filter but the state the tab opens on.
  Future<void> clearFilters() {
    if (!isFiltered) return Future.value();

    _direction = null;
    _concept = "";
    _method = "";
    _state = MoneyPaymentStatus.recorded;

    return _read(1, reset: true);
  }

  /// Records money that moved.
  ///
  /// The list is reread instead of having the new row inserted into it: the
  /// totals are those of the whole filter, and a payment that does not match
  /// the filter on screen must not appear in it. Both are answers only the
  /// backend has.
  ///
  /// Returns `false` if it did not go in; the reason was already shown in the
  /// floating flag, which is where the backend explains what it refused.
  Future<bool> record(
    BuildContext context, {
    required Map<String, dynamic> request
  }) async {
    try {
      await _source.recordPayment(request);
    } catch (error) {
      if (kDebugMode) print("recordPayment failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    await refresh();

    return true;
  }

  /// Annuls a payment: it stops counting and it stays.
  ///
  /// A payment is never edited, so this is the only way out of a mistake — the
  /// void plus a new payment, which is what really happened. Voiding a
  /// settlement also gives its ticket the debt back, which is why whoever owns
  /// both lists rereads the receivables afterwards.
  Future<bool> annul(
    BuildContext context, {
    required String id,
    String reason = ""
  }) async {
    try {
      await _source.voidPayment(id: id, reason: reason);
    } catch (error) {
      if (kDebugMode) print("voidPayment failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    await refresh();

    return true;
  }

  Future<void> _read(int page, {bool reset = false}) async {
    if (_reading && !reset) return;

    _reading = true;
    _moreFailed = false;

    if (reset) {
      _generation++;
      _payments.clear();
      _page = 0;
      _status = MoneyPaymentsStatus.loading;
      notifyListeners();
    }

    final generation = _generation;

    final MoneyPaymentsPage result;

    try {
      result = await _source.payments(
        page: page,
        size: _pageSize,
        direction: _direction,
        concept: _concept,
        method: _method,
        state: _state
      );
    } catch (error) {
      if (kDebugMode) print("loadPayments failed: $error");

      // What came back belongs to a filter nobody is looking at: there is
      // nowhere to note it, not even the failure. The lock is not released
      // either, which is no longer its own.
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
    _page = page;

    _payments.addAll(result.payments);

    // A batch that comes back empty is the end, whatever the total says:
    // between it being counted and the page being asked for, something could
    // have been voided out of the filter. Without this the list would keep
    // asking for the next page forever.
    if (result.payments.isEmpty) _total = _payments.length;

    _status = _payments.isEmpty
      ? MoneyPaymentsStatus.empty
      : MoneyPaymentsStatus.ready;

    notifyListeners();
  }

  /// What remains when a read left nothing. A batch that did not arrive does
  /// not invalidate what was already being read: it is warned at the end of the
  /// list and retried from there.
  void _nothing() {
    if (_payments.isEmpty) {
      _status = MoneyPaymentsStatus.error;
      return;
    }

    _moreFailed = true;
  }

  /// Leaves the reason where it is being looked at. The caller checks that the
  /// tree is still up before reaching it: a write can come back after the
  /// section was left, and there is nobody to tell then.
  void _report(BuildContext context, Object error) {
    FloatFlag.of(context).fromError(
      error is Map && error.isNotEmpty ? error : {"message": error.toString()}
    );
  }
}
