import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/money/money_summary_model.dart';
import 'package:app/services/money/sources/money_source.dart';
import 'package:app/toolkit/deployment.dart';

enum MoneySummaryStatus { idle, loading, ready, empty, error }

/// The windows the money screen is read over.
///
/// They are ranges and not dates because that is how the question is asked
/// —"hoy", "este mes"— and because the backend answers the same shape for any
/// of them: [MoneyRange.today] is an empty body and the rest are a `FROM` it
/// computes here. A date picker would be a fifth case of this same enum, not a
/// second endpoint.
enum MoneyRange {
  today,
  week,
  month,
  year;

  /// Where the window opens, or null for [today] — which the backend reads as
  /// midnight of its own day, the same day the POS screen reports on. It is
  /// left to the backend on purpose: two screens of one shop must not disagree
  /// about when the day started.
  DateTime? from(DateTime now) => switch (this) {
    today => null,
    week => now.subtract(const Duration(days: 7)),
    month => now.subtract(const Duration(days: 30)),
    year => DateTime(now.year - 1, now.month, now.day)
  };

  /// The same window as the backend's own shorthand (`RANGE`), for the
  /// endpoints that take it — see `MoneyBotService`. It is the better half of
  /// the pair: the period is then resolved against the server's day instead of
  /// against this machine's clock. [from] stays because `/money/summary` only
  /// takes dates.
  String get code => switch (this) {
    today => "today",
    week => "7d",
    month => "30d",
    year => "12m"
  };
}

/// The money screen: what came in, what went out, and what that leaves
/// (`GET /money` for today, `POST /money/summary` for any other window).
///
/// They are one question asked of two periods and not two endpoints: the bare
/// read is today and the body is the same answer over the range the screen's
/// picker is on, which is why the range lives here and the tab only draws it.
///
/// **The figures are two reads added on the other side**: the register's own
/// money comes from the tickets and everything else from the payments recorded
/// by hand. Nothing is added up in this app, and money sold on credit is kept
/// apart — see [MoneySummary].
///
/// It is ephemeral: owned by the finance section and discarded when leaving it.
/// The shell remounts the section when the company changes, so there is nothing
/// to invalidate on its own account.
class MoneyService extends ChangeNotifier {
  MoneyService({MoneySource? source}) : _injected = source;

  final MoneySource? _injected;

  MoneySource get _source => _injected ?? Sources.money;

  MoneySummaryStatus _status = MoneySummaryStatus.idle;
  MoneySummary _summary = const MoneySummary();
  MoneyRange _range = MoneyRange.today;

  /// With which window the read being waited on was made. Whatever comes back
  /// with another generation is discarded: those are the figures of a period
  /// nobody is looking at any more.
  int _generation = 0;

  MoneySummaryStatus get status => _status;
  MoneySummary get summary => _summary;
  MoneyRange get range => _range;

  /// Reads the summary. Without [force] it does not ask again once it is read:
  /// the section can be mounted more than once.
  Future<void> load({bool force = false}) {
    if (!force && _status != MoneySummaryStatus.idle) return Future.value();

    return _read();
  }

  Future<void> retry() => _read();

  /// The accounting export's file for a `moneyExportRequest` body (M-60). It
  /// holds no state: the file is the caller's to save, and the summary on
  /// screen has nothing to do with the period exported.
  Future<Uint8List> exportAccounting(Map<String, dynamic> request) =>
    _source.exportAccounting(request);

  /// Reads the same summary over another window.
  ///
  /// The figures on screen belong to the previous one, so they are dropped and
  /// the wait is shown: leaving them there would be answering "este mes" with
  /// what happened today until the response lands.
  Future<void> select(MoneyRange range) {
    if (range == _range) return Future.value();

    _range = range;

    return _read();
  }

  Future<void> _read() async {
    _generation++;
    final generation = _generation;

    _status = MoneySummaryStatus.loading;
    notifyListeners();

    final from = _range.from(DateTime.now());

    final MoneySummary summary;

    try {
      summary = await _source.summary(from: from);
    } catch (error) {
      if (kDebugMode) print("loadMoneySummary failed: $error");

      // What came back belongs to a window nobody is looking at: there is
      // nowhere to note it, not even the failure.
      if (generation != _generation) return;

      _status = MoneySummaryStatus.error;
      notifyListeners();

      return;
    }

    if (generation != _generation) return;


    // A response that was not understood is an error and not an empty period:
    // drawing it would be a screen of zeros that nobody can tell from a quiet
    // day.
    if (!summary.isLoaded) {
      _status = MoneySummaryStatus.error;
      notifyListeners();

      return;
    }

    _summary = summary;
    _status = summary.isEmpty
      ? MoneySummaryStatus.empty
      : MoneySummaryStatus.ready;

    notifyListeners();
  }
}
