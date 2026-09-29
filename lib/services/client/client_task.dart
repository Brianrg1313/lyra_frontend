// SERVICES
import 'package:app/services/client/employment_invitation_model.dart';

/// What `/init` says is pending before the dashboard (`tasks`, backend model
/// `user/tasks.js`). The backend orders them; the app works the first one it
/// has a screen for.
enum ClientTaskKey {
  twoFactor("security.two_factor"),
  /// Same page as [businessNone]: the backend sends one or the other (an
  /// invitation means no `business.none`), and both are "no company yet".
  invitation("employment.invitation", route: "/welcome"),
  businessNone("business.none", route: "/welcome");

  const ClientTaskKey(this.key, {this.route});

  final String key;

  /// Where the task is done. `null` while it has no screen yet: it is skipped
  /// and the person lands where they did before the backend listed it.
  final String? route;

  static ClientTaskKey? fromKey(String? key) {
    for (final value in values) {
      if (value.key == key) return value;
    }
    return null;
  }
}

class ClientTask {
  final ClientTaskKey key;

  /// What that task's screen needs to draw, as the backend sent it.
  final Map<String, dynamic> data;

  const ClientTask({required this.key, this.data = const {}});

  /// Only on [ClientTaskKey.invitation]; empty on any other task.
  List<EmploymentInvitation> get invitations =>
    EmploymentInvitation.listFromJson(data["invitations"]);

  /// `null` for a key this version does not know: a newer backend may list
  /// tasks an older app has nothing to show for.
  static ClientTask? fromJson(Map json) {
    final key = ClientTaskKey.fromKey(json["key"] as String?);
    if (key == null) return null;

    final data = json["data"];
    return ClientTask(
      key: key,
      data: data is Map ? Map<String, dynamic>.from(data) : const {}
    );
  }

  /// The `tasks` block of `/init`; the key is absent when nothing is pending.
  static List<ClientTask> listFromJson(dynamic json) => json is List
    ? json.whereType<Map>().map(ClientTask.fromJson).whereType<ClientTask>().toList()
    : const [];
}
