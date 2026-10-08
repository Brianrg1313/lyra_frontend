import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/toolkit/api.dart';

import './employment_record_model.dart';

enum AccountHistoryStatus { idle, loading, ready, empty, error }

/// The companies the signed-in person has worked for (`GET /profile/employments`): theirs, not
/// the active company's, so every company they ever joined is listed whichever one is open.
/// Cloud only. Owned by the employees section (`EmployeesSection`), read on the first own page.
class AccountHistoryService extends ChangeNotifier {
  AccountHistoryStatus _status = AccountHistoryStatus.idle;
  AccountHistoryStatus get status => _status;

  List<EmploymentRecord> _jobs = const [];

  /// Invitations first, then the jobs held, then the ended ones; newest start first in each.
  List<EmploymentRecord> get jobs => _jobs;

  bool _disposed = false;

  Future<void> load() async {
    _status = AccountHistoryStatus.loading;
    _notify();

    try {
      _jobs = EmploymentRecord.listFrom(await api.get(path: "/profile/employments/", version: "v1"));
      _status = _jobs.isEmpty ? AccountHistoryStatus.empty : AccountHistoryStatus.ready;
    } catch (_) {
      _status = AccountHistoryStatus.error;
    }

    _notify();
  }

  @visibleForTesting
  void seed(dynamic data) {
    _jobs = EmploymentRecord.listFrom(data);
    _status = _jobs.isEmpty ? AccountHistoryStatus.empty : AccountHistoryStatus.ready;
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
