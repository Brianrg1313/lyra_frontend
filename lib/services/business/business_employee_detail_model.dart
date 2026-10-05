// SERVICES
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/files/file_model.dart';

/// How the hours of a job are arranged.
enum EmployeeWorkday {
  fullTime("full_time"),
  partTime("part_time"),
  hourly("hourly"),
  shifts("shifts");

  const EmployeeWorkday(this.value);

  final String value;

  static EmployeeWorkday? from(dynamic raw) => employeePick(values, raw, (item) => item.value);
}

/// What a salary amount is per.
enum EmployeePayPeriod {
  hour("hour"),
  day("day"),
  week("week"),
  fortnight("fortnight"),
  month("month"),
  year("year");

  const EmployeePayPeriod(this.value);

  final String value;

  static EmployeePayPeriod? from(dynamic raw) => employeePick(values, raw, (item) => item.value);
}

/// Where a contract stands on the company's calendar day. `expiring` is a
/// fixed end within the backend's warning window (30 days); `expired` is an end
/// that passed with nobody ending or renewing the job. The closed states are
/// the employment's own.
enum EmployeeContractStatus {
  pending("pending"),
  current("current"),
  expiring("expiring"),
  expired("expired"),
  ended("ended"),
  declined("declined"),
  cancelled("cancelled");

  const EmployeeContractStatus(this.value);

  final String value;

  static EmployeeContractStatus? from(dynamic raw) => employeePick(values, raw, (item) => item.value);
}

/// Why a job ended.
enum EmployeeEndReason {
  resignation("resignation"),
  dismissal("dismissal"),
  contractEnd("contract_end"),
  mutual("mutual"),
  other("other");

  const EmployeeEndReason(this.value);

  final String value;

  static EmployeeEndReason? from(dynamic raw) => employeePick(values, raw, (item) => item.value);
}

enum EmployeeDocument {
  nationalId("national_id"),
  passport("passport"),
  foreignId("foreign_id"),
  taxId("tax_id");

  const EmployeeDocument(this.value);

  final String value;

  static EmployeeDocument? from(dynamic raw) => employeePick(values, raw, (item) => item.value);
}

enum EmployeeSex {
  female("female"),
  male("male"),
  other("other");

  const EmployeeSex(this.value);

  final String value;

  static EmployeeSex? from(dynamic raw) => employeePick(values, raw, (item) => item.value);
}

/// Everything the company may know about one employee, as
/// `GET /business/employees/detail/:ID` answers it.
///
/// The person is the employee's own profile, not the company's: it comes
/// whole only while the job is active ([fullProfile]); an invitation or a
/// former employee shows only their public card, and every private field of
/// [person] is then empty — not unknown, withheld.
class BusinessEmployeeDetail {
  const BusinessEmployeeDetail({
    required this.id,
    this.state,
    this.contractStatus,
    this.workStatus,
    this.fullProfile = false,
    this.sealedLocked = false,
    this.profileEditable = false,
    this.person = const EmployeePerson(),
    this.job = const EmployeeJob(),
    this.tenure = const EmployeeSpan(),
    this.companySince,
    this.companyDays = 0,
    this.leave,
    this.upcomingLeaves = const [],
    this.ending,
    this.invitedAt,
    this.respondedAt
  });

  final String id;
  final EmployeeState? state;
  final EmployeeContractStatus? contractStatus;
  final EmployeeWorkStatus? workStatus;

  /// `visibility: full` — the private profile came with it.
  final bool fullProfile;

  /// A master's session the cloud's grant opened: the profile would come whole, but its sealed
  /// details wait for the person's password there (`session.md` S-13). Never set online.
  final bool sealedLocked;

  /// The company may write the personal data: while the job is active. It
  /// writes the person's own profile, not a copy.
  final bool profileEditable;

  final EmployeePerson person;
  final EmployeeJob job;

  /// Time in this job, up to today or to the day it ended.
  final EmployeeSpan tenure;

  /// First day of the first stint in the company; a rehire counts what came
  /// before, so this can be older than [EmployeeJob.startDate].
  final DateTime? companySince;

  /// Days worked for the company over every stint.
  final int companyDays;

  /// The absence running today.
  final EmployeeLeave? leave;

  /// The next ones, soonest first (the backend sends at most five).
  final List<EmployeeLeave> upcomingLeaves;

  /// Only once the job is over.
  final EmployeeEnding? ending;

  /// When the job was filed: the invitation, or the hire itself.
  final DateTime? invitedAt;

  /// When the person accepted or declined; the hire itself when nobody had to.
  final DateTime? respondedAt;

  static BusinessEmployeeDetail? from(dynamic json) {
    if (json is! Map) return null;

    final id = employeeText(json["id"]);

    if (id.isEmpty) return null;

    final company = json["company_tenure"];
    final upcoming = json["upcoming_leaves"];

    return BusinessEmployeeDetail(
      id: id,
      state: EmployeeState.from(json["state"]),
      contractStatus: EmployeeContractStatus.from(json["contract_status"]),
      workStatus: EmployeeWorkStatus.from(json["work_status"]),
      fullProfile: employeeText(json["visibility"]).toLowerCase() == "full",
      sealedLocked: employeeFlag(json["sealed_locked"]),
      profileEditable: employeeFlag(json["profile_editable"]),
      person: EmployeePerson.from(json["person"]),
      job: EmployeeJob.from(json["job"]),
      tenure: EmployeeSpan.from(json["tenure"]),
      companySince: company is Map ? employeeDay(company["since"]) : null,
      companyDays: company is Map ? _int(company["total_days"]) ?? 0 : 0,
      leave: EmployeeLeave.from(json["leave"]),
      upcomingLeaves: upcoming is List
        ? [for (final leave in upcoming) ?EmployeeLeave.from(leave)]
        : const [],
      ending: EmployeeEnding.from(json["ended"]),
      invitedAt: _moment(json["invited_date"]),
      respondedAt: _moment(json["responded"])
    );
  }
}

/// The person behind an employment. Their card — names, username, picture,
/// headline — always; the rest only with a full profile.
class EmployeePerson {
  const EmployeePerson({
    this.username = "",
    this.name = "",
    this.lastName = "",
    this.picture,
    this.headline = "",
    this.email = "",
    this.phone = "",
    this.sex,
    this.birthday,
    this.about = "",
    this.documentType,
    this.documentNumber = "",
    this.nationality = "",
    this.address = "",
    this.city = "",
    this.region = "",
    this.country = "",
    this.postalCode = "",
    this.emergencyName = "",
    this.emergencyPhone = "",
    this.emergencyRelation = ""
  });

  final String username;
  final String name;
  final String lastName;
  final FileModel? picture;

  /// What they do, as they describe it themselves.
  final String headline;

  final String email;
  final String phone;
  final EmployeeSex? sex;
  final DateTime? birthday;
  final String about;
  final EmployeeDocument? documentType;
  final String documentNumber;

  /// Country codes; the catalog names them.
  final String nationality;
  final String country;

  final String address;
  final String city;
  final String region;
  final String postalCode;

  final String emergencyName;
  final String emergencyPhone;
  final String emergencyRelation;

  String get fullName {
    final full = [name, lastName].where((part) => part.isNotEmpty).join(" ");

    return full.isEmpty ? username : full;
  }

  /// The written address in one line, empty when there is none.
  String get place => [address, city, region, postalCode]
    .where((part) => part.isNotEmpty)
    .join(", ");

  static EmployeePerson from(dynamic json) {
    if (json is! Map) return const EmployeePerson();

    final emergency = json["emergency_contact"];

    return EmployeePerson(
      username: employeeText(json["username"]),
      name: employeeText(json["name"]),
      lastName: employeeText(json["last_name"]),
      picture: FileModel.from(json["picture"]),
      headline: employeeText(json["headline"]),
      email: employeeText(json["email"]),
      phone: employeeText(json["phone"]),
      sex: EmployeeSex.from(json["sex"]),
      birthday: employeeDay(json["birthday"]),
      about: employeeText(json["about"]),
      documentType: EmployeeDocument.from(json["document_type"]),
      documentNumber: employeeText(json["document_number"]),
      nationality: employeeText(json["nationality"]),
      address: employeeText(json["address"]),
      city: employeeText(json["city"]),
      region: employeeText(json["region"]),
      country: employeeText(json["country"]),
      postalCode: employeeText(json["postal_code"]),
      emergencyName: emergency is Map ? employeeText(emergency["name"]) : "",
      emergencyPhone: emergency is Map ? employeeText(emergency["phone"]) : "",
      emergencyRelation: emergency is Map ? employeeText(emergency["relation"]) : ""
    );
  }
}

/// The job: the company's own record, kept after it ends.
class EmployeeJob {
  const EmployeeJob({
    this.title = "",
    this.department = "",
    this.code = "",
    this.branchId = "",
    this.branchName = "",
    this.manager,
    this.contract,
    this.workday,
    this.startDate,
    this.endDate,
    this.salary,
    this.salaryCurrency = "",
    this.payPeriod,
    this.workEmail = "",
    this.workPhone = "",
    this.notes = ""
  });

  final String title;
  final String department;

  /// The company's internal employee code.
  final String code;

  final String branchId;
  final String branchName;
  final EmployeeManager? manager;
  final EmployeeContract? contract;
  final EmployeeWorkday? workday;
  final DateTime? startDate;

  /// The contract's fixed end, if it has one. Not the day the job ended: that
  /// is [EmployeeEnding.date].
  final DateTime? endDate;

  /// `null` when none was filed, which is not a salary of zero.
  final double? salary;
  final String salaryCurrency;
  final EmployeePayPeriod? payPeriod;

  final String workEmail;
  final String workPhone;

  /// The company's notes about the job, never shown to the person.
  final String notes;

  static EmployeeJob from(dynamic json) {
    if (json is! Map) return const EmployeeJob();

    final branch = json["branch"];
    final salary = json["salary"];

    return EmployeeJob(
      title: employeeText(json["job_title"]),
      department: employeeText(json["department"]),
      code: employeeText(json["code"]),
      branchId: branch is Map ? employeeText(branch["id"]) : "",
      branchName: branch is Map ? employeeText(branch["name"]) : "",
      manager: EmployeeManager.from(json["manager"]),
      contract: EmployeeContract.from(json["contract"]),
      workday: EmployeeWorkday.from(json["workday"]),
      startDate: employeeDay(json["start_date"]),
      endDate: employeeDay(json["end_date"]),
      salary: salary is num ? salary.toDouble() : double.tryParse(employeeText(salary)),
      salaryCurrency: employeeText(json["salary_currency"]).toUpperCase(),
      payPeriod: EmployeePayPeriod.from(json["pay_period"]),
      workEmail: employeeText(json["work_email"]),
      workPhone: employeeText(json["work_phone"]),
      notes: employeeText(json["notes"])
    );
  }
}

/// Who a job reports to: another employment of the company, as a card.
class EmployeeManager {
  const EmployeeManager({
    required this.id,
    this.username = "",
    this.name = "",
    this.lastName = "",
    this.jobTitle = ""
  });

  final String id;
  final String username;
  final String name;
  final String lastName;
  final String jobTitle;

  String get fullName {
    final full = [name, lastName].where((part) => part.isNotEmpty).join(" ");

    return full.isEmpty ? username : full;
  }

  static EmployeeManager? from(dynamic json) {
    if (json is! Map) return null;

    final id = employeeText(json["id"]);

    if (id.isEmpty) return null;

    return EmployeeManager(
      id: id,
      username: employeeText(json["username"]),
      name: employeeText(json["name"]),
      lastName: employeeText(json["last_name"]),
      jobTitle: employeeText(json["job_title"])
    );
  }
}

/// An absence: its type and the days it covers, both ends inclusive.
class EmployeeLeave {
  const EmployeeLeave({
    required this.id,
    this.type,
    this.startDate,
    this.endDate,
    this.days = 0,
    this.note = ""
  });

  final String id;
  final EmployeeLeaveType? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final int days;
  final String note;

  static EmployeeLeave? from(dynamic json) {
    if (json is! Map) return null;

    final id = employeeText(json["id"]);

    if (id.isEmpty) return null;

    return EmployeeLeave(
      id: id,
      type: EmployeeLeaveType.from(json["type"]),
      startDate: employeeDay(json["start_date"]),
      endDate: employeeDay(json["end_date"]),
      days: _int(json["days"]) ?? 0,
      note: employeeText(json["note"])
    );
  }
}

/// A length of time as a person says it. The backend computes it on the
/// company's calendar; nothing here adds dates up.
class EmployeeSpan {
  const EmployeeSpan({
    this.years = 0,
    this.months = 0,
    this.days = 0,
    this.totalDays = 0
  });

  final int years;
  final int months;
  final int days;
  final int totalDays;

  static EmployeeSpan from(dynamic json) {
    if (json is! Map) return const EmployeeSpan();

    return EmployeeSpan(
      years: _int(json["years"]) ?? 0,
      months: _int(json["months"]) ?? 0,
      days: _int(json["days"]) ?? 0,
      totalDays: _int(json["total_days"]) ?? 0
    );
  }
}

/// How a job ended.
class EmployeeEnding {
  const EmployeeEnding({this.date, this.reason, this.note = ""});

  final DateTime? date;
  final EmployeeEndReason? reason;
  final String note;

  static EmployeeEnding? from(dynamic json) {
    if (json is! Map) return null;

    return EmployeeEnding(
      date: employeeDay(json["date"]),
      reason: EmployeeEndReason.from(json["reason"]),
      note: employeeText(json["note"])
    );
  }
}

int? _int(dynamic value) => value is num
  ? value.toInt()
  : int.tryParse(employeeText(value));

/// A timestamp column (not a calendar day): it travels in UTC and is shown in
/// local time.
DateTime? _moment(dynamic value) {
  final text = employeeText(value);

  return text.isEmpty ? null : DateTime.tryParse(text)?.toLocal();
}
