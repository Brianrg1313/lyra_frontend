// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/catalog/catalog_table.dart';
import 'package:app/services/files/file_model.dart';

/// One of the person's jobs, as `GET /profile/employments` answers it (backend model
/// `employees/employments.js`): an invitation waiting, a job held or one that ended, with its
/// company. Their working history, kept after every job.
class EmploymentRecord {
  const EmploymentRecord({
    required this.id,
    required this.businessId,
    required this.businessName,
    this.businessLogo,
    this.branch,
    this.jobTitle = "",
    this.department = "",
    this.contract,
    this.state,
    this.startDate,
    this.endedDate,
    this.tenure
  });

  final String id;
  final String businessId;
  final String businessName;
  final FileModel? businessLogo;
  final String? branch;
  final String jobTitle;
  final String department;
  final EmployeeContract? contract;
  final EmployeeState? state;
  final DateTime? startDate;

  /// The day the job ended; `null` while it is held.
  final DateTime? endedDate;

  /// Time in the job, measured to today or to [endedDate]; `null` on an invitation.
  final EmployeeSpan? tenure;

  static EmploymentRecord? from(Map<String, dynamic> row) {
    final business = row["business"] is Map ? row["business"] as Map : const {};
    final id = row["id"]?.toString() ?? "";

    if (id.isEmpty) return null;

    return EmploymentRecord(
      id: id,
      businessId: business["id"]?.toString() ?? "",
      businessName: business["name"]?.toString() ?? "",
      businessLogo: FileModel.from(business["logo"]),
      branch: row["branch"]?.toString(),
      jobTitle: row["job_title"]?.toString() ?? "",
      department: row["department"]?.toString() ?? "",
      contract: EmployeeContract.from(row["contract"]),
      state: EmployeeState.from(row["state"]),
      startDate: employeeDay(row["start_date"]),
      endedDate: employeeDay(row["ended_date"]),
      tenure: row["tenure"] is Map ? EmployeeSpan.from(row["tenure"]) : null
    );
  }

  /// The compressed `{ keys, values }` table (a plain list is read too).
  static List<EmploymentRecord> listFrom(dynamic data) => [
    for (final row in catalogRows(data)) ?EmploymentRecord.from(row)
  ];
}
