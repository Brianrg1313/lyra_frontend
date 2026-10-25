import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/money/money_bot_model.dart';
import 'package:app/services/money/money_service.dart';
import 'package:app/toolkit/backend/api.dart';

enum MoneyBotStatus { idle, loading, ready, empty, error }

/// What Lyra —the bot that answers the company's customers— costs
/// (`POST /money/ai`, the backend's name for it).
///
/// **It is a service of its own, and not a field of [MoneyService], because it
/// is read over a window of its own.** `GET /money` already carries the same
/// block for today; the card has a second selector because the money above it
/// is usually being read for today while "how much is the bot costing me" is a
/// question about the month, and one shared window would force somebody to move
/// the whole screen to answer one card.
///
/// The window travels as the backend's own shorthand (`RANGE`) and not as a
/// date: the range is resolved against the server's day, the same way the
/// summary's `today` is, so the two halves of the tab never disagree about when
/// a period started.
///
/// **A failure is not a zero.** The backend refuses (503) when the metrics it
/// measures could not be read, precisely so that nothing claims the company
/// spent nothing, and that refusal arrives here as [MoneyBotStatus.error].
///
/// Like the rest of the section it is ephemeral: it belongs to the company
/// being looked at and is dropped when leaving finance.
class MoneyBotService extends ChangeNotifier {
  MoneyBotStatus _status = MoneyBotStatus.idle;
  MoneyBotSpend _spend = const MoneyBotSpend();

  /// It opens on the month and not on today: what was spent since midnight on
  /// models is cents, and a card that opens on a figure too small to read is a
  /// card nobody looks at twice.
  MoneyRange _range = MoneyRange.month;

  /// Which window the read being waited on belongs to. Anything that comes back
  /// with another generation is dropped: those are the figures of a period
  /// nobody is looking at any more.
  int _generation = 0;

  MoneyBotStatus get status => _status;
  MoneyBotSpend get spend => _spend;
  MoneyRange get range => _range;

  /// Reads the spend. Without [force] it does not ask again once it is read:
  /// the tab can be mounted more than once.
  Future<void> load({bool force = false}) {
    if (!force && _status != MoneyBotStatus.idle) return Future.value();

    return _read();
  }

  Future<void> retry() => _read();

  /// Reads the same spend over another window. The figures on screen belong to
  /// the previous one, so they are dropped and the wait is shown.
  Future<void> select(MoneyRange range) {
    if (range == _range) return Future.value();

    _range = range;

    return _read();
  }

  /// Puts an answer in without asking for one, which is what lets the block be
  /// mounted without a network: [load] only reads while the status is idle, so
  /// a seeded service stays on the figures it was given.
  void seed(MoneyBotSpend spend) {
    _generation++;
    _spend = spend;
    _status = spend.isEmpty ? MoneyBotStatus.empty : MoneyBotStatus.ready;

    notifyListeners();
  }

  Future<void> _read() async {
    _generation++;
    final generation = _generation;

    _status = MoneyBotStatus.loading;
    notifyListeners();

    dynamic data;

    try {
      data = await api.post(
        path: "/money/ai/",
        version: "v1",
        data: {"RANGE": _range.code}
      );
    } catch (error) {
      if (kDebugMode) print("loadMoneyBotSpend failed: $error");

      if (generation != _generation) return;

      _status = MoneyBotStatus.error;
      notifyListeners();

      return;
    }

    if (generation != _generation) return;

    final spend = MoneyBotSpend.fromResponse(data);

    // A response that was not understood is an error and not a quiet month:
    // drawing it would be a zero, which is the one answer this must never give.
    if (!spend.isLoaded) {
      _status = MoneyBotStatus.error;
      notifyListeners();

      return;
    }

    _spend = spend;
    _status = spend.isEmpty ? MoneyBotStatus.empty : MoneyBotStatus.ready;

    notifyListeners();
  }
}
