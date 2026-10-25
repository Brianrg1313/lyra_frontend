// SERVICES
import 'package:app/toolkit/backend/api.dart';
import 'package:app/toolkit/backend/deployment.dart' show UnreadableAnswer;

/// The backend's side of enrolling a master (`docs/task-edge-sync-backend.md` §1) and of its grants (§9),
/// with the person's session. Cloud only: a master has nothing to enrol with while offline.
class SyncCloudSource {
  const SyncCloudSource();

  /// `POST /edge/v1/devices` with what `sync.prepare` answered. Answers the enrolment in the
  /// contract's keys, which the engine takes as is (`sync.enroll`). [replace] revokes the
  /// branch's live master first: only after the owner chose this one over it.
  Future<Map<String, Object?>> enrol(Map<String, Object?> key, {bool replace = false}) async {
    final answer = await edge.post(path: "/devices/", version: "v1", data: {
      "INSTANCE": key["instance"],
      "NAME": key["name"],
      "PUBLIC_KEY": key["publicKey"],
      "ENGINE_VERSION": key["engine"],
      if (replace) "REPLACE": true
    });
    if (answer is! Map) throw const UnreadableAnswer("edge/devices");

    return Map<String, Object?>.from(answer);
  }

  /// `POST /edge/v1/grants` (§9): the backend's signed statement that this person may open their
  /// session on the master [instance] names, good for two minutes and once (`auth.grant`). Any
  /// member of the master's company gets one, whatever company the session is on online.
  Future<String> grant(String instance) async {
    final answer = await edge.post(path: "/grants/", version: "v1", data: {"INSTANCE": instance});
    final grant = answer is Map ? answer["grant"] : null;
    if (grant is! String) throw const UnreadableAnswer("edge/grants");

    return grant;
  }
}
