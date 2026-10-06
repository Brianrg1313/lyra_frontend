import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES

// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/employee_activation_model.dart';
import 'package:app/services/permissions/permission_member_model.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/services/permissions/sources/permissions_source.dart';
import 'package:app/services/preferences/preferences_service.dart';
import 'package:app/services/business/sources/employees_source.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/deployment.dart';

enum BusinessEmployeesStatus { idle, loading, ready, error }

enum EmployeeDetailStatus { idle, loading, ready, error }

/// The people of the active company (`/business/employees/`) and the one open
/// in the detail panel.
///
/// Provided by the business page (`BusinessDetailSection`), not app-wide, like
/// the branches: every endpoint answers for the business in the `business_id`
/// header, and a business switch remounts the page, which drops what was read.
///
/// The list is two reads: the current people (active, then invited — the
/// viewer always first) and the former ones. The former are a second list the
/// backend keeps apart; if only that read fails the current list still shows,
/// because it is the one that is worked with.
///
/// Without `business.employees.view` the current list is only the viewer's own
/// card (the backend narrows it) and the former one is not read at all.
///
/// A detail is read once per person per page and kept: switching back and
/// forth between two employees in the list does not reread either.
class BusinessEmployeesService extends ChangeNotifier {
  BusinessEmployeesService({EmployeesSource? source, PermissionsSource? permissions})
    : _injected = source, _injectedPermissions = permissions;

  final EmployeesSource? _injected;
  final PermissionsSource? _injectedPermissions;

  EmployeesSource get _source => _injected ?? Sources.employees;
  PermissionsSource get _permissions => _injectedPermissions ?? Sources.permissions;

  BusinessEmployeesStatus _status = BusinessEmployeesStatus.idle;
  List<BusinessEmployeeModel> _current = const [];
  List<BusinessEmployeeModel> _former = const [];
  int _total = 0;

  String? _selected;

  final Map<String, BusinessEmployeeDetail> _details = {};
  final Map<String, EmployeeDetailStatus> _detailStatus = {};

  bool _disposed = false;

  BusinessEmployeesStatus get status => _status;

  /// Active and invited, the viewer's card first.
  List<BusinessEmployeeModel> get current => _current;

  /// Who used to work here, with the job record the company keeps.
  List<BusinessEmployeeModel> get former => _former;

  /// How many are active — the backend's count, not the length of [current],
  /// which also holds the invitations and possibly the viewer's unfiled card.
  int get total => _total;

  /// Whether the viewer sees everyone, not only their own card.
  static bool get viewsAll => PermissionsService().canOpen("business.employees");

  /// Key ([BusinessEmployeeModel.key]) of the person open in the detail panel.
  String? get selectedKey => _selected;

  BusinessEmployeeModel? get selected {
    for (final employee in [..._current, ..._former]) {
      if (employee.key == _selected) return employee;
    }

    return null;
  }

  BusinessEmployeeDetail? detailOf(String id) => _details[id];

  EmployeeDetailStatus detailStatusOf(String id) =>
    _detailStatus[id] ?? EmployeeDetailStatus.idle;

  /// Reads both lists. Without [force] they are read once per page. The first
  /// read opens the viewer's own card; a reread keeps the selection while that
  /// person is still listed.
  Future<void> load({bool force = false}) async {
    if (_status == BusinessEmployeesStatus.loading) return;
    if (!force && _status == BusinessEmployeesStatus.ready) return;

    _status = BusinessEmployeesStatus.loading;
    notifyListeners();

    final (current, former) = await (_fetch(), _fetchFormer()).wait;

    if (current == null) {
      _status = BusinessEmployeesStatus.error;
      notifyListeners();
      return;
    }

    _apply(current.$1, current.$2, former?.$1 ?? const []);

    if (force) {
      _details.clear();
      _detailStatus.clear();
    }

    notifyListeners();
  }

  /// Opens a person in the detail panel.
  void select(String key) {
    if (_selected == key) return;

    _selected = key;
    PreferencesService().remember(RememberedSelection.employee, key);
    notifyListeners();
  }

  /// The permission templates an invitation may carry: none where the viewer
  /// may not give permissions (`business.employees.permissions`) or only the
  /// cloud changes them (a syncing master, P-12), and only those whose every
  /// key the viewer holds (`all` needs `all`), since the cloud and the master
  /// refuse the rest as an escalation. A failed read answers none: the
  /// invitation goes out without.
  Future<List<PermissionTemplateModel>> inviteTemplates() async {
    if (!PermissionsService().can("business.employees.permissions")) return const [];

    try {
      final (online, mine, templates) = await (_permissions.online(), _permissions.mine(), _permissions.templates()).wait;
      if (online) return const [];

      return [
        for (final template in templates)
          if (template.grant.all
            ? mine.all
            : PermissionCatalog.changes(PermissionCatalog.filled(false), template.grant.sections).every(mine.can))
            template
      ];
    } catch (e) {
      if (kDebugMode) print("invite templates: $e");
      return const [];
    }
  }

  /// Invites a person by email (`POST /business/employees/invite`), whether or
  /// not they have an account: for an email with none the backend opens one
  /// and the invitation waits there until they sign up with it. [template]
  /// (one of [inviteTemplates]) is copied onto them when they accept.
  ///
  /// Rereads the list and opens the new invitation. Answers what was sent,
  /// with the activation code a master made for a new account, which the
  /// form shows once. A refusal (already invited or working here, a title it
  /// does not take) is shown in the floating flag and answers `null`.
  Future<EmployeeInvitationSent?> invite(
    BuildContext context, {
    required String email,
    required String jobTitle,
    String? template
  }) async {
    EmployeeInvitationSent sent;

    try {
      sent = await _source.invite(email: email, jobTitle: jobTitle, template: template);
    } catch (error) {
      if (kDebugMode) print("inviteEmployee failed: $error");

      if (context.mounted) {
        FloatFlag.of(context).fromError(
          error is Map && error.isNotEmpty ? error : {"message": error.toString()}
        );
      }

      return null;
    }

    await load(force: true);

    final id = sent.id;
    if (id != null && id.isNotEmpty) select(id);

    return sent;
  }

  /// Edits one employment (`PUT /business/employees/`): [changes] are the
  /// backend keys (`JOB_TITLE`, `MANAGER_ID`, `FIRST_NAME`...), and a key sent
  /// empty erases it. The person's keys are refused unless the detail says
  /// [BusinessEmployeeDetail.profileEditable].
  ///
  /// Answers once the detail and the rows are read again, so the field that
  /// saved shows what the backend kept, not what was typed. A refusal is shown
  /// in the floating flag and answers `false`.
  Future<bool> edit(BuildContext context, String id, Map<String, dynamic> changes) =>
    _write(context, id, "editEmployee", () => _source.edit(id, changes));

  /// Edits the viewer's own personal data (`PUT /profile/`) shown in their
  /// employment [id]: the person's profile is theirs to write, with no company
  /// permission (the backend reads who from the session, never from the body).
  /// Same keys and answer as [edit]; the job stays [edit]'s.
  Future<bool> editOwn(BuildContext context, String id, Map<String, dynamic> changes) =>
    _write(context, id, "editOwnProfile", () => _source.editOwn(changes));

  /// Sends one write, then rereads the detail and the rows; a refusal goes to
  /// the floating flag.
  Future<bool> _write(
    BuildContext context,
    String id,
    String label,
    Future<dynamic> Function() request
  ) async {
    try {
      await request();
    } catch (error) {
      if (kDebugMode) print("$label failed: $error");

      if (context.mounted) {
        FloatFlag.of(context).fromError(
          error is Map && error.isNotEmpty ? error : {"message": error.toString()}
        );
      }

      return false;
    }

    // The rows too: the list shows the name and the job title.
    await (loadDetail(id, force: true), _refreshRows()).wait;

    return true;
  }

  /// Rereads both lists without passing through `loading`, which would blank
  /// the list under a panel that is only saving one field.
  Future<void> _refreshRows() async {
    final (current, former) = await (_fetch(), _fetchFormer()).wait;

    if (current == null) return;

    _apply(current.$1, current.$2, former?.$1 ?? _former);
    notifyListeners();
  }

  /// Reads the detail of an employment. Without [force], once per page.
  Future<void> loadDetail(String id, {bool force = false}) async {
    final status = detailStatusOf(id);

    if (status == EmployeeDetailStatus.loading) return;
    if (!force && status == EmployeeDetailStatus.ready) return;

    _detailStatus[id] = EmployeeDetailStatus.loading;
    notifyListeners();

    BusinessEmployeeDetail? detail;

    try {
      detail = await _source.detail(id);
    } catch (error) {
      if (kDebugMode) print("loadEmployeeDetail failed: $error");
    }

    if (detail != null) _details[id] = detail;
    _detailStatus[id] = detail == null
      ? EmployeeDetailStatus.error
      : EmployeeDetailStatus.ready;

    notifyListeners();
  }

  void _apply(
    List<BusinessEmployeeModel> current,
    int total,
    List<BusinessEmployeeModel> former
  ) {
    _current = current;
    _former = former;
    _total = total;
    _status = BusinessEmployeesStatus.ready;

    final keys = {for (final employee in [...current, ...former]) employee.key};

    if (!keys.contains(_selected)) {
      // First read: whoever was open when the tab was last left, while they
      // are still listed; otherwise the viewer's own card.
      final last = PreferencesService().recall(RememberedSelection.employee);

      _selected = keys.contains(last)
        ? last
        : current.isNotEmpty ? current.first.key : former.firstOrNull?.key;
    }
  }

  /// The former list, or none for a viewer who may only see their own card:
  /// that endpoint still needs `employees`.
  Future<(List<BusinessEmployeeModel>, int)?> _fetchFormer() async =>
    viewsAll ? _fetch(former: true) : (const <BusinessEmployeeModel>[], 0);

  /// One list, with the active count when it is the current one. `null` when
  /// the read failed.
  Future<(List<BusinessEmployeeModel>, int)?> _fetch({bool former = false}) async {
    try {
      if (former) return (await _source.former(), 0);

      return await _source.current();
    } catch (error) {
      if (kDebugMode) print("loadEmployees${former ? "Former" : ""} failed: $error");

      return null;
    }
  }

  /// Leaves both lists and some details as if they had been read, without
  /// touching the network.
  @visibleForTesting
  void seed({
    List<BusinessEmployeeModel> current = const [],
    List<BusinessEmployeeModel> former = const [],
    int total = 0,
    List<BusinessEmployeeDetail> details = const []
  }) {
    _apply(current, total, former);

    for (final detail in details) {
      _details[detail.id] = detail;
      _detailStatus[detail.id] = EmployeeDetailStatus.ready;
    }

    notifyListeners();
  }

  /// A read can answer after the page that asked for it is gone (a business
  /// switch remounts it), and notifying a disposed notifier throws.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
