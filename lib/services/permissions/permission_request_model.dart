// SERVICES
import 'package:app/services/catalog/catalog_table.dart';

/// Where a permission request stands. `granted` is measured by the backend at read time
/// (the person holds the permission now), so one answered by assigning it by hand reads as
/// answered too.
enum PermissionRequestState {
  pending,
  granted;

  /// Unknown values read as `pending`: a request that exists is at least that.
  static PermissionRequestState from(dynamic value) =>
    value == "granted" ? granted : pending;
}

/// One row of `GET /permissions/requests/`: a permission (`<area>.<action>`) the person
/// asked for in the active company.
class PermissionRequestModel {
  const PermissionRequestModel({
    required this.id,
    required this.permission,
    required this.state,
    this.reason,
    this.createdAt
  });

  final String id;
  final String permission;
  final PermissionRequestState state;
  final String? reason;
  final DateTime? createdAt;

  bool get isPending => state == PermissionRequestState.pending;

  factory PermissionRequestModel.fromJson(Map<String, dynamic> json) {
    final reason = json["reason"]?.toString().trim();

    return PermissionRequestModel(
      id: json["id"]?.toString() ?? "",
      permission: json["permission"]?.toString() ?? "",
      state: PermissionRequestState.from(json["state"]),
      reason: reason == null || reason.isEmpty ? null : reason,
      createdAt: DateTime.tryParse(json["created_at"]?.toString() ?? "")
    );
  }

  /// The compressed table (`{keys, values}`) or a plain list; rows with no permission are dropped.
  static List<PermissionRequestModel> listFromTable(dynamic data) => [
    for (final row in catalogRows(data))
      if (PermissionRequestModel.fromJson(row).permission.isNotEmpty)
        PermissionRequestModel.fromJson(row)
  ];
}
