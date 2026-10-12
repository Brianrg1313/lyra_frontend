import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/sources/employees_source.dart';
import 'package:app/toolkit/deployment.dart';

/// The viewer's job title in each company, under the company's name in the side bar.
///
/// `/init` does not bring it, so it is the viewer's own row of the staff list (`me`), read
/// once per company per session: every member may read that list, narrowed to their own card
/// without `business.employees.view`. The employees section hands over each list it reads
/// ([remember]), so a title edited there shows here without a second request.
///
/// A singleton: the side bar outlives the section, and a business switch must not reread a
/// company already known.
class OwnJobTitleService extends ChangeNotifier {
  OwnJobTitleService._internal();

  static final OwnJobTitleService _singleton = OwnJobTitleService._internal();

  factory OwnJobTitleService() => _singleton;

  @visibleForTesting
  EmployeesSource? source;

  EmployeesSource get _source => source ?? Sources.employees;

  final Map<String, String> _titles = {};
  final Set<String> _loading = {};

  /// The title in [businessId]; `null` while unknown, empty when the card has none.
  String? of(String businessId) => _titles[businessId];

  /// Reads [businessId]'s, which must be the active company: the request answers for the
  /// company in its header. A failed read leaves it unknown, to retry on the next switch.
  Future<void> load(String businessId) async {
    if (_titles.containsKey(businessId) || !_loading.add(businessId)) return;

    try {
      final (rows, _) = await _source.current();
      remember(businessId, rows);
    } catch (e) {
      if (kDebugMode) print("own job title: $e");
    } finally {
      _loading.remove(businessId);
    }
  }

  /// Takes the viewer's title from a staff list of [businessId].
  void remember(String businessId, List<BusinessEmployeeModel> rows) {
    final title = rows.where((row) => row.me).firstOrNull?.jobTitle.trim();
    if (title == null || _titles[businessId] == title) return;

    _titles[businessId] = title;
    notifyListeners();
  }

  /// For session logout: the next person has titles of their own.
  void clear() {
    _titles.clear();
    _loading.clear();
    notifyListeners();
  }
}
