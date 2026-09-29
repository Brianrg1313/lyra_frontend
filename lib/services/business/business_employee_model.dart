// SERVICES
import 'package:app/services/catalog/catalog_table.dart';
import 'package:app/services/files/file_model.dart';

/// Lifecycle of an employment, the only state the backend stores. The closed
/// ones (`declined`, `cancelled`) never reach a list; they can still come back
/// in a detail read by id.
enum EmployeeState {
  invited("invited"),
  active("active"),
  ended("ended"),
  declined("declined"),
  cancelled("cancelled");

  const EmployeeState(this.value);

  final String value;

  static EmployeeState? from(dynamic raw) => employeePick(values, raw, (item) => item.value);
}

/// Kind of contract a job is on.
enum EmployeeContract {
  permanent("permanent"),
  fixedTerm("fixed_term"),
  probation("probation"),
  internship("internship"),
  freelance("freelance"),
  temporary("temporary");

  const EmployeeContract(this.value);

  final String value;

  static EmployeeContract? from(dynamic raw) => employeePick(values, raw, (item) => item.value);
}

/// Why an employee is away. The type running today is also their work status.
enum EmployeeLeaveType {
  vacation("vacation"),
  sick("sick"),
  maternity("maternity"),
  paternity("paternity"),
  personal("personal"),
  unpaid("unpaid"),
  suspension("suspension"),
  other("other");

  const EmployeeLeaveType(this.value);

  final String value;

  static EmployeeLeaveType? from(dynamic raw) => employeePick(values, raw, (item) => item.value);
}

/// Where an active employee is today, measured by the backend on the company's
/// calendar day — never stored, so it is read on every request.
///
/// The backend sends a single word (`working`, `not_started` or the type of
/// the absence running); here it is split into the kind and, when away, which
/// absence, so the list can color by kind without knowing every leave type.
class EmployeeWorkStatus {
  const EmployeeWorkStatus._(this.kind, [this.leave]);

  static const working = EmployeeWorkStatus._(EmployeeWorkKind.working);
  static const notStarted = EmployeeWorkStatus._(EmployeeWorkKind.notStarted);

  final EmployeeWorkKind kind;

  /// The absence running, only when [kind] is `away`.
  final EmployeeLeaveType? leave;

  /// `null` for anyone not active (the backend sends none) and for a word this
  /// app does not know yet.
  static EmployeeWorkStatus? from(dynamic raw) {
    final value = raw?.toString().trim().toLowerCase() ?? "";

    if (value == "working") return working;
    if (value == "not_started") return notStarted;

    final leave = EmployeeLeaveType.from(value);

    return leave == null ? null : EmployeeWorkStatus._(EmployeeWorkKind.away, leave);
  }
}

enum EmployeeWorkKind { working, notStarted, away }

/// One person of `GET /business/employees/` (and of `.../former`), as the list
/// draws them: their public card and the headline of their job.
class BusinessEmployeeModel {
  const BusinessEmployeeModel({
    this.id,
    this.me = false,
    this.username = "",
    this.name = "",
    this.lastName = "",
    this.email = "",
    this.picture,
    this.jobTitle = "",
    this.department = "",
    this.branchId = "",
    this.contract,
    this.state,
    this.workStatus,
    this.startDate,
    this.endedDate
  });

  /// Employment id, what the detail is read by. `null` only on the viewer's
  /// own card when they have no job filed in this company.
  final String? id;

  /// It is the person looking. The backend always sends it first.
  final bool me;

  final String username;
  final String name;
  final String lastName;

  /// Only on an invitation to an email with no account yet — the backend
  /// opened a nameless one for it, and its username is random. Empty on every
  /// other row: the backend never shows a company anyone else's email.
  final String email;

  final FileModel? picture;

  final String jobTitle;
  final String department;
  final String branchId;

  final EmployeeContract? contract;

  /// `null` on the viewer's unfiled card. Former rows carry none either: being
  /// in that list is their state ([ended]).
  final EmployeeState? state;

  final EmployeeWorkStatus? workStatus;

  final DateTime? startDate;

  /// Only on former rows.
  final DateTime? endedDate;

  /// What the selection is kept by: the employment id, or a fixed key for the
  /// viewer's unfiled card, which has none.
  String get key => id ?? meKey;

  static const String meKey = "me";

  /// `Name Last`; before the account has a name, the email it was invited
  /// with, or else the username.
  String get fullName {
    final full = [name, lastName].where((part) => part.isNotEmpty).join(" ");

    if (full.isNotEmpty) return full;

    return email.isEmpty ? username : email;
  }

  /// The rows of the answer, compressed (`{keys, values}`) or not.
  ///
  /// The viewer's card goes first whatever order they came in: the backend
  /// promises it, and the panel opens on it, so it is not left to a promise.
  /// A row with neither id nor `me` is dropped — nothing could open it.
  static List<BusinessEmployeeModel> listFrom(dynamic data, {bool former = false}) {
    final rows = [
      for (final row in catalogRows(data)) ?BusinessEmployeeModel.from(row, former: former)
    ];

    final mine = rows.indexWhere((row) => row.me);

    if (mine > 0) rows.insert(0, rows.removeAt(mine));

    return rows;
  }

  static BusinessEmployeeModel? from(Map<String, dynamic> row, {bool former = false}) {
    final id = employeeText(row["id"]);
    final me = !former && employeeFlag(row["me"]);

    if (id.isEmpty && !me) return null;

    return BusinessEmployeeModel(
      id: id.isEmpty ? null : id,
      me: me,
      username: employeeText(row["username"]),
      name: employeeText(row["name"]),
      lastName: employeeText(row["last_name"]),
      email: employeeText(row["email"]),
      picture: FileModel.from(row["picture"]),
      jobTitle: employeeText(row["job_title"]),
      department: employeeText(row["department"]),
      branchId: employeeText(row["branch_id"]),
      contract: EmployeeContract.from(row["contract"]),
      state: former ? EmployeeState.ended : EmployeeState.from(row["state"]),
      workStatus: EmployeeWorkStatus.from(row["work_status"]),
      startDate: employeeDay(row["start_date"]),
      endedDate: employeeDay(row["ended_date"])
    );
  }
}

String employeeText(dynamic value) => value?.toString().trim() ?? "";

bool employeeFlag(dynamic value) =>
  switch (value?.toString().trim().toLowerCase()) {
    "1" || "true" => true,
    _ => false
  };

/// A `YYYY-MM-DD` calendar day, read as a date with no time zone: it is the
/// company's day, and moving it to local time could shift it by one.
DateTime? employeeDay(dynamic value) {
  final text = employeeText(value);

  if (text.length < 10) return null;

  final parsed = DateTime.tryParse(text.substring(0, 10));

  return parsed == null ? null : DateTime(parsed.year, parsed.month, parsed.day);
}

/// The member of a closed set of backend words that [raw] names, or `null`.
/// The backend stores them lowercase but reads any case, so this does too.
T? employeePick<T>(List<T> values, dynamic raw, String Function(T) value) {
  final text = raw?.toString().trim().toLowerCase() ?? "";

  for (final item in values) {
    if (value(item) == text) return item;
  }

  return null;
}
