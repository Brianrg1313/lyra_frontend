import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

// SERVICES
import 'package:app/services/kitchen/kitchen_api.dart';
import 'package:app/services/kitchen/kitchen_request.dart';
import 'package:app/services/kitchen/modifier_model.dart';
import 'package:app/toolkit/api.dart';

/// Status of the modifier groups' read.
enum ModifiersStatus { idle, loading, ready, empty, error }

/// The company's modifier groups (`/inventory/modifiers`): «Extras», «Término de la carne».
///
/// Owned by the supply chain section. Every write rereads the list: the order (`position`) and
/// the ids of new options are the backend's to say.
class ModifiersService extends ChangeNotifier {
  ModifiersStatus _status = ModifiersStatus.idle;
  List<ModifierGroup> _groups = const [];
  bool _disposed = false;

  ModifiersStatus get status => _status;
  List<ModifierGroup> get groups => _groups;

  static const String _path = "/inventory/modifiers";

  Future<void> load({bool force = false}) async {
    if (_status == ModifiersStatus.loading) return;
    if (!force && _status == ModifiersStatus.ready) return;

    final quiet = _status == ModifiersStatus.ready || _status == ModifiersStatus.empty;

    if (!quiet) {
      _status = ModifiersStatus.loading;
      _notify();
    }

    try {
      _groups = ModifierGroup.listFrom(await api.get(path: _path, version: "v1"));
      _status = _groups.isEmpty ? ModifiersStatus.empty : ModifiersStatus.ready;
    } catch (error) {
      if (kDebugMode) print("modifiers read failed: $error");
      if (!quiet) _status = ModifiersStatus.error;
    }

    _notify();
  }

  /// Creates or replaces a group, from `saveModifierGroupRequest`.
  Future<bool> save(BuildContext context, Map<String, dynamic> body) =>
    _write(context, "saveModifiers", () => api.put(path: _path, version: "v1", data: body));

  Future<bool> remove(BuildContext context, ModifierGroup group) =>
    _write(context, "deleteModifiers", () => api.delete(path: _path, version: "v1", data: deleteModifierGroupRequest(id: group.id)));

  Future<bool> _write(BuildContext context, String name, Future<dynamic> Function() send) async {
    try {
      await send();
    } catch (error) {
      if (context.mounted) KitchenApi.report(context, name, error);
      return false;
    }

    await load(force: true);

    return true;
  }

  /// Seeds the list, for tests.
  @visibleForTesting
  void seed(List<ModifierGroup> groups) {
    _groups = groups;
    _status = groups.isEmpty ? ModifiersStatus.empty : ModifiersStatus.ready;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
