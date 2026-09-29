// SERVICES
import 'package:app/services/files/file_model.dart';

/// A company's invitation waiting for the person's answer: one entry of the
/// `employment.invitation` task's `invitations` (the `/profile/employments`
/// card, backend model `employees/employments.js`).
class EmploymentInvitation {
  /// The employment id: what `PUT /profile/employments/` answers by.
  final String id;
  final String businessId;
  final String businessName;
  final FileModel? businessLogo;
  final String? branch;
  final String jobTitle;
  final String department;
  final DateTime? invitedDate;

  const EmploymentInvitation({
    required this.id,
    required this.businessId,
    required this.businessName,
    this.businessLogo,
    this.branch,
    this.jobTitle = "",
    this.department = "",
    this.invitedDate
  });

  factory EmploymentInvitation.fromJson(Map json) {
    final business = json["business"] is Map ? json["business"] as Map : const {};

    return EmploymentInvitation(
      id: json["id"]?.toString() ?? "",
      businessId: business["id"]?.toString() ?? "",
      businessName: business["name"]?.toString() ?? "",
      businessLogo: FileModel.from(business["logo"]),
      branch: json["branch"]?.toString(),
      jobTitle: json["job_title"]?.toString() ?? "",
      department: json["department"]?.toString() ?? "",
      invitedDate: DateTime.tryParse(json["invited_date"]?.toString() ?? "")?.toLocal()
    );
  }

  static List<EmploymentInvitation> listFromJson(dynamic json) => json is List
    ? json.whereType<Map>().map(EmploymentInvitation.fromJson).toList()
    : const [];
}
