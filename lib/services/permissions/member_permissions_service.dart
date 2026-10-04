import 'package:flutter/foundation.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/services/permissions/permission_member_model.dart';
import 'package:app/services/permissions/sources/permissions_source.dart';
import 'package:app/toolkit/deployment.dart';

enum MemberPermissionsStatus { idle, loading, ready, error }

/// What the permissions editor holds for one person: their document, the templates, the viewer's
/// own grant, and a draft of the change, in the catalog's keys (`session.md` session.permissions).
///
/// Without [username] it is the viewer's own permissions, which nobody changes for themselves.
///
/// The draft keeps the backend's rules so what [save] sends is never refused for its shape: an
/// action turns its section on, a section turned off clears the actions the viewer may change, and
/// a key the viewer does not hold is never touched ([canChange], P-6 escalation). The backend
/// still decides; this only spares a 403 the screen could have predicted.
class MemberPermissionsService extends ChangeNotifier {
  MemberPermissionsService({this.username, PermissionsSource? source}) : _injected = source;

  final String? username;
  final PermissionsSource? _injected;

  PermissionsSource get _source => _injected ?? Sources.permissions;

  MemberPermissionsStatus _status = MemberPermissionsStatus.idle;
  MemberPermissionsStatus get status => _status;

  Grant _mine = Grant.none();

  /// The viewer's own grant: what they may give or take.
  Grant get mine => _mine;

  PermissionMemberModel? _member;
  PermissionMemberModel? get member => _member;

  List<PermissionTemplateModel> _templates = const [];
  List<PermissionTemplateModel> get templates => _templates;

  bool _all = false;
  PermissionSections _sections = PermissionCatalog.filled(false);

  /// The template picked in the draft, applied on [save].
  PermissionTemplateModel? _template;
  PermissionTemplateModel? get template => _template;

  bool _saving = false;
  bool get saving => _saving;

  bool _disposed = false;

  /// Whether the draft is `all`: everything, including what the catalog adds later.
  bool get all => _all;

  /// Nothing can be changed: one's own, the owner's, or an `all` member for a viewer without `all`.
  bool get readOnly {
    final member = _member;

    return member == null || member.me || member.owner || (member.grant.all && !_mine.all);
  }

  /// The stored flag of [section] (`access`) or one of its actions in the draft.
  bool flag(String section, String flag) => _all || (_sections[section]?[flag] ?? false);

  /// Whether the viewer may give or take [key] (`<section>` or `<section>.<action>`).
  bool canChange(String key) => !readOnly && _mine.can(key);

  /// Whether [template] may be applied: every key it changes is the viewer's, and `all` on either
  /// side needs `all`.
  bool canApply(PermissionTemplateModel template) {
    final member = _member;
    if (readOnly || member == null) return false;
    if ((template.grant.all || member.grant.all) && !_mine.all) return false;

    return PermissionCatalog.changes(member.grant.sections, template.grant.sections).every(_mine.can);
  }

  /// Something to send: a template picked, a key changed, or a person with no access yet (saving
  /// lets them in).
  bool get dirty {
    final member = _member;
    if (member == null || readOnly) return false;

    return !member.access || _template != null || (_all && !member.grant.all) ||
      PermissionCatalog.changes(member.grant.sections, _sections).isNotEmpty;
  }

  Future<void> load() async {
    _status = MemberPermissionsStatus.loading;
    _notify();

    try {
      final user = username;
      final (mine, member, templates) = await (
        _source.mine(),
        user == null ? Future.value(null) : _source.member(user),
        user == null ? Future.value(const <PermissionTemplateModel>[]) : _source.templates()
      ).wait;

      _mine = mine;
      _member = member;
      _templates = templates;
      _reset();
      _status = MemberPermissionsStatus.ready;
    } catch (e) {
      if (kDebugMode) print("member permissions: $e");
      _status = MemberPermissionsStatus.error;
    }

    _notify();
  }

  /// Flips one flag of the draft: `access` or an action of [section].
  void toggle(String section, String flag) {
    final key = flag == PermissionCatalog.access ? section : "$section.$flag";
    if (!canChange(key)) return;

    // One key changed on an `all` structure makes it a plain one, with everything else still on.
    if (_all) {
      _all = false;
      _sections = PermissionCatalog.filled(true);
    }

    final flags = _sections[section]!;
    final on = !(flags[flag] ?? false);
    flags[flag] = on;

    if (flag == PermissionCatalog.access && !on) {
      for (final action in PermissionCatalog.sections[section]!) {
        if (_mine.can("$section.$action")) flags[action] = false;
      }
    } else if (on) {
      flags[PermissionCatalog.access] = true;
    }

    _notify();
  }

  /// Copies [template] into the draft; the keys can still be changed after it.
  void apply(PermissionTemplateModel template) {
    if (!canApply(template)) return;

    _template = template;
    _all = template.grant.all;
    _sections = PermissionCatalog.normalize(template.grant.sections, all: template.grant.all);
    _notify();
  }

  /// Back to what is stored.
  void discard() {
    _reset();
    _notify();
  }

  /// Sends the draft: the template picked, plus only the flags that differ from it (or from what
  /// the member had). Throws the source's error; the draft stays for another try.
  Future<void> save() async {
    final member = _member;
    if (member == null || !dirty || _saving) return;

    final base = _template?.grant ?? member.grant;
    final partial = <String, Map<String, bool>>{};

    if (!_all) {
      for (final key in PermissionCatalog.changes(base.sections, _sections)) {
        final [section, ...action] = key.split(".");
        final flag = action.isEmpty ? PermissionCatalog.access : action.first;
        (partial[section] ??= {})[flag] = _sections[section]![flag]!;
      }
    }

    await _busy(() async {
      await _source.assign(member.username, template: _template?.id, permissions: partial);
      await _reread();
    });
  }

  /// Takes the member's access away. Throws the source's error.
  Future<void> revoke() async {
    final member = _member;
    if (member == null || readOnly || !member.access || _saving) return;

    await _busy(() async {
      await _source.revoke(member.username);
      await _reread();
    });
  }

  Future<void> _busy(Future<void> Function() body) async {
    _saving = true;
    _notify();

    try {
      await body();
    } finally {
      _saving = false;
      _notify();
    }
  }

  Future<void> _reread() async {
    _member = await _source.member(_member!.username);
    _reset();
  }

  void _reset() {
    final grant = _member?.grant ?? _mine;

    _template = null;
    _all = grant.all;
    _sections = PermissionCatalog.normalize(grant.sections, all: grant.all);
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
