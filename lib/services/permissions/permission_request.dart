/// Longest `REASON` the backend accepts.
const int kPermissionReasonMax = 200;

/// `POST /permissions/requests/` body. A blank reason does not travel: it is optional.
Map<String, dynamic> requestPermissionRequest({
  required String permission,
  String? reason
}) {
  final text = reason?.trim() ?? "";

  return {
    "PERMISSION": permission,
    if (text.isNotEmpty) "REASON": text
  };
}
