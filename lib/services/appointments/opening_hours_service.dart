import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/appointments/opening_hours_model.dart';
import 'package:app/services/appointments/opening_hours_request.dart';
import 'package:app/toolkit/api.dart';

enum OpeningHoursStatus { idle, loading, ready, error }

/// **When one branch attends** (`sedes-frontend.md` §11): its week and the
/// days it is closed. Every week is one branch's — there is no company week —
/// and it is what the bot tells customers, what the appointments follow and
/// what the delivery franjas are cut from. A branch with no rows is closed
/// every day.
///
/// Owned by the panel that edits it, for [branch]. Cloud only, `api` direct.
class OpeningHoursService extends ChangeNotifier {
  OpeningHoursService({required this.branch});

  final String branch;

  OpeningHoursStatus _status = OpeningHoursStatus.idle;
  OpeningHoursStatus get status => _status;

  List<OpeningStretch> _week = const [];

  /// The branch's own stretches (no service), by weekday and hour.
  List<OpeningStretch> get week => _week;

  /// The branch's rows for one service: written back untouched with the week.
  List<OpeningStretch> _services = const [];

  List<ClosedDay> _closures = const [];

  /// The days ahead closed here or everywhere, soonest first.
  List<ClosedDay> get closures => _closures;

  bool _writing = false;
  bool get writing => _writing;

  bool _disposed = false;

  /// The stretches of [weekday].
  List<OpeningStretch> of(int weekday) => [for (final row in _week) if (row.weekday == weekday) row];

  Future<void> load() async {
    _status = OpeningHoursStatus.loading;
    _notify();

    try {
      final answers = await Future.wait([
        api.get(path: "/appointments/hours/", version: "v1"),
        api.get(path: "/appointments/closures/", version: "v1")
      ]);

      _take([for (final row in OpeningStretch.list(answers[0])) if (row.branch == branch) row]);
      _closures = [
        for (final closed in ClosedDay.list(answers[1]))
          if (closed.everywhere || closed.branch == branch) closed
      ]..sort((a, b) => a.day.compareTo(b.day));
      _status = OpeningHoursStatus.ready;
    } catch (error) {
      if (kDebugMode) print("loadOpeningHours failed: $error");
      _status = OpeningHoursStatus.error;
    }

    _notify();
  }

  /// Writes the branch's whole week. Throws the backend's refusal.
  Future<void> saveWeek(List<OpeningStretch> week) => _write(() async {
    await api.put(
      path: "/appointments/hours/",
      version: "v1",
      data: setWeekRequest(branch, week, kept: _services)
    );

    _take([...week, ..._services]);
  });

  /// Closes [day] here, or in every branch. Throws the refusal.
  Future<void> close(String day, {String reason = "", bool everywhere = false}) => _write(() async {
    await api.post(
      path: "/appointments/closures/",
      version: "v1",
      data: closeDayRequest(day, reason: reason, branch: everywhere ? null : branch)
    );

    await _readClosures();
  });

  /// Opens [closed] again. Throws the refusal.
  Future<void> reopen(ClosedDay closed) => _write(() async {
    await api.delete(path: "/appointments/closures/", version: "v1", data: reopenDayRequest(closed));

    _closures = [
      for (final row in _closures)
        if (row.day != closed.day || row.branch != closed.branch) row
    ];
  });

  Future<void> _readClosures() async {
    final rows = ClosedDay.list(await api.get(path: "/appointments/closures/", version: "v1"));

    _closures = [
      for (final closed in rows)
        if (closed.everywhere || closed.branch == branch) closed
    ]..sort((a, b) => a.day.compareTo(b.day));
  }

  Future<void> _write(Future<void> Function() call) async {
    if (_writing) return;

    _writing = true;
    _notify();

    try {
      await call();
    } finally {
      _writing = false;
      _notify();
    }
  }

  /// Takes the branch's rows: its own week apart from its services'.
  void _take(List<OpeningStretch> rows) {
    _week = [for (final row in rows) if (row.service == null) row]
      ..sort((a, b) => a.weekday != b.weekday ? a.weekday.compareTo(b.weekday) : a.opens.compareTo(b.opens));
    _services = [for (final row in rows) if (row.service != null) row];
  }

  /// Seeds the week, for tests.
  @visibleForTesting
  void seed(List<OpeningStretch> rows, {List<ClosedDay> closures = const []}) {
    _take(rows);
    _closures = closures;
    _status = OpeningHoursStatus.ready;
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
