import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

// SERVICES
import 'package:app/services/knowledge/knowledge_entry_model.dart';
import 'package:app/services/knowledge/knowledge_request.dart';
import 'package:app/toolkit/api.dart';

/// Status of the read of the frequent questions (`GET /knowledge/`).
enum KnowledgeStatus { idle, loading, ready, empty, error }

/// The company's frequent questions: what Lyra already knows the answer to,
/// and what customers asked that nobody has answered yet.
///
/// Owned by the knowledge section (created and provided there, not app-wide):
/// every endpoint answers for the business in the `business_id` header, and a
/// business switch remounts the section, which drops what was read. Cloud
/// only — Lyra answers from the cloud — so it calls [api] itself, like the
/// channels.
///
/// **Every write rereads the list.** What an entry looks like after a write is
/// the backend's to say: its `state` is computed against the company's
/// calendar day, its products are named from their records, and a question
/// answered for the first time stops being pending. Patching the row here
/// would mean guessing all three. The switch is the exception ([toggle]): it
/// changes one thing whose effect is known, so the row flips at once and the
/// reread confirms it.
class KnowledgeService extends ChangeNotifier {
  KnowledgeStatus _status = KnowledgeStatus.idle;
  List<KnowledgeEntry> _entries = const [];
  bool _disposed = false;

  KnowledgeStatus get status => _status;
  List<KnowledgeEntry> get entries => _entries;

  /// Questions waiting for an answer: what the section asks the company to do.
  int get pending => _entries.where((entry) => entry.isPending).length;

  /// Reads the questions. Without [force] they are read once per section.
  Future<void> load({bool force = false}) async {
    if (_status == KnowledgeStatus.loading) return;
    if (!force && _status == KnowledgeStatus.ready) return;

    // A reread after a write keeps the list on screen: only the first read
    // shows the spinner.
    final quiet = _status == KnowledgeStatus.ready || _status == KnowledgeStatus.empty;

    if (!quiet) {
      _status = KnowledgeStatus.loading;
      _notify();
    }

    try {
      final data = await api.get(path: "/knowledge/", version: "v1");

      _entries = KnowledgeEntry.fromResponse(data);
      _status = _entries.isEmpty ? KnowledgeStatus.empty : KnowledgeStatus.ready;
    } catch (error) {
      if (kDebugMode) print("loadKnowledge failed: $error");

      // A failed reread keeps what was there: the list is still the last
      // thing that was true.
      if (!quiet) _status = KnowledgeStatus.error;
    }

    _notify();
  }

  /// Writes a new question, from `createKnowledgeRequest`. A refusal is shown
  /// in the floating flag and answers `false`.
  Future<bool> create(BuildContext context, Map<String, dynamic> body) =>
    _write(context, "createKnowledge", () =>
      api.post(path: "/knowledge/", version: "v1", data: body));

  /// Edits a question, from `editKnowledgeRequest` (it carries the `ID`).
  Future<bool> edit(BuildContext context, Map<String, dynamic> body) =>
    _write(context, "editKnowledge", () =>
      api.put(path: "/knowledge/", version: "v1", data: body));

  /// Turns an answer on or off. Nothing is asked: it is reversible with the
  /// same click and nothing is lost.
  Future<bool> toggle(BuildContext context, KnowledgeEntry entry) async {
    final enabled = !entry.enabled;

    // A pending entry stays pending either way: the switch is not what it is
    // missing. The others are only known to be off, or to be whatever the
    // dates say once the reread arrives.
    _replace(entry.id, (current) => current.copyWith(
      enabled: enabled,
      state: current.isPending
        ? KnowledgeState.pending
        : enabled ? current.state : KnowledgeState.off
    ));

    final done = await _write(context, "toggleKnowledge", () => api.put(
      path: "/knowledge/",
      version: "v1",
      data: toggleKnowledgeRequest(id: entry.id, enabled: enabled)
    ));

    if (!done) _replace(entry.id, (_) => entry);

    return done;
  }

  /// Retires a question for good. Whoever calls it has confirmed it.
  Future<bool> remove(BuildContext context, KnowledgeEntry entry) =>
    _write(context, "deleteKnowledge", () => api.delete(
      path: "/knowledge/",
      version: "v1",
      data: deleteKnowledgeRequest(id: entry.id)
    ));

  Future<bool> _write(
    BuildContext context,
    String name,
    Future<dynamic> Function() send
  ) async {
    try {
      await send();
    } catch (error) {
      if (kDebugMode) print("$name failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    await load(force: true);

    return true;
  }

  void _replace(String id, KnowledgeEntry Function(KnowledgeEntry current) change) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index < 0) return;

    _entries = List<KnowledgeEntry>.from(_entries)..[index] = change(_entries[index]);
    _notify();
  }

  /// Shows a failed write. An `action` is a navigation instruction (an expired
  /// session): it is rethrown for whoever handles it.
  void _report(BuildContext context, Object error) {
    if (error is Map && error["action"] != null) throw error["action"];

    FloatFlag.of(context).fromError(
      error is Map && error.isNotEmpty ? error : {"message": error.toString()}
    );
  }

  /// Seeds the list, for tests.
  @visibleForTesting
  void seed(List<KnowledgeEntry> entries) {
    _entries = entries;
    _status = entries.isEmpty ? KnowledgeStatus.empty : KnowledgeStatus.ready;
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
