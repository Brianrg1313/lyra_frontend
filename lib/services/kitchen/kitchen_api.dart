import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:app/toolkit/toolkit.dart' show FloatFlag;

/// What the kitchen's services share about a refusal.
///
/// The supply chain is cloud only (`docs/app-areas.json`), so its services call `api`
/// themselves, like the channels and the knowledge.
abstract final class KitchenApi {
  /// The code a refusal names (`recipe_not_found`, `negotiable_short`): the cloud says it in
  /// `message`.
  static String reason(Object error) =>
    error is Map ? (error["code"] ?? error["message"] ?? "").toString() : "";

  /// Shows a failed write in the floating flag. An `action` is a navigation instruction (an
  /// expired session): rethrown for whoever handles it.
  static void report(BuildContext context, String name, Object error) {
    if (kDebugMode) print("$name failed: $error");
    if (error is Map && error["action"] != null) throw error["action"];
    if (!context.mounted) return;

    FloatFlag.of(context).fromError(
      error is Map && error.isNotEmpty ? error : {"message": error.toString()}
    );
  }
}
