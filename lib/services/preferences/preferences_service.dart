import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/database/database_service.dart';

/// What is open inside a section without being in the URL: the section keeps
/// it as state (see the messages desk and the employees tab), so the route
/// alone cannot bring it back.
enum RememberedSelection {
  /// The open conversation of the messages desk (`ChatsService.selected`).
  chat,

  /// The person open in the employees tab (`BusinessEmployeesService.selectedKey`).
  employee
}

/// The user's preferences, persisted on the device (Hive box `preferences`),
/// so the app opens as it was left.
///
/// Two kinds, stored under different keys on purpose:
/// - **Device-wide**: theme and language. They are about the machine, not the
///   account, and are applied before `runApp` (see [preload]) so the first
///   frame is already painted with them — at the login too.
/// - **Per account**: the last home page, the active business and what was
///   open inside a section. Keyed by username, because two people signing in
///   on the same desktop must each land where *they* left; a selection is also
///   keyed by business, since a chat or an employee id means nothing in
///   another company.
///
/// A singleton and not a provider: it is read before the tree exists
/// (`preCall`, `initialValidator`, `ClientService.resolve`) and by services
/// scoped to one section that have no app-wide context to read it from.
///
/// Every write is a no-op until [preload] opened the box, so tests and any code
/// running without Hive only lose the memory, never throw.
class PreferencesService {
  //SINGLETON
  static final PreferencesService _singleton = PreferencesService._internal();
  factory PreferencesService() => _singleton;
  PreferencesService._internal();

  static const String _box = "preferences";
  static const String _themeKey = "theme";
  static const String _localeKey = "locale";

  final DatabaseService _database = DatabaseService();

  bool _ready = false;

  /// Username of the signed-in account, or null without a session: nothing
  /// per-account is read or written then.
  String? _user;

  /// The active business, as [BusinessService] last set it.
  String? _business;

  // ───────────────────────────── lifecycle ─────────────────────────────

  /// Opens the box, applies the stored theme and language to [AppController]
  /// and starts persisting their changes. Called in `preCall`, after
  /// `AppController.instance` and before `runApp`.
  static Future<void> preload() async {
    await DatabaseService().openBox(_box);
    _singleton._restore();
  }

  void _restore() {
    _ready = true;

    final app = AppController();

    final theme = _read<String>(_themeKey);
    app.theme.value = ThemeMode.values.asNameMap()[theme] ?? ThemeMode.system;

    final locale = _read<String>(_localeKey);
    if (locale != null && locale.isNotEmpty) app.locale.value = Locale(locale);

    // Listening instead of offering setters: whoever changes the theme or the
    // language keeps talking to `AppController`, the one that repaints, and
    // the choice is remembered without knowing this service exists.
    app.theme.addListener(() => _write(_themeKey, app.theme.value?.name));
    app.locale.addListener(() => _write(_localeKey, app.locale.value?.languageCode));

    Navis.currentKey.addListener(_screenChanged);
  }

  /// Binds the per-account preferences to [username]; null on sign out.
  /// Called by `ClientService` as soon as `/init` names the account, before
  /// the businesses are seeded (they read [lastBusiness]).
  void bindUser(String? username) {
    _user = (username == null || username.isEmpty) ? null : username;
    if (_user == null) _business = null;
  }

  // ───────────────────────────── theme and language ─────────────────────

  ThemeMode get theme => AppController().theme.value ?? ThemeMode.system;

  set theme(ThemeMode value) => AppController().theme.value = value;

  /// Null follows the system.
  Locale? get locale => AppController().locale.value;

  set locale(Locale? value) => AppController().locale.value = value;

  // ───────────────────────────── last page ─────────────────────────────

  /// The home page the account was on when the app closed, URL args
  /// included (`/home/business/:id/employees`), or null if none was recorded.
  String? get lastPath => _read<String>(_userKey("path"));

  /// Where to land after the session resolves when no deep link asks for
  /// something else.
  String get homePath => lastPath ?? "/home";

  /// Only home pages are recorded: the login, the pre-start pages and the POS
  /// are not places to come back to on their own. A page that no longer
  /// exists (a deleted table) is handled by the page itself, as a deep link
  /// would be.
  void _screenChanged() {
    if (_user == null) return;

    final path = Navis.currentPath;
    if (path != "/home" && !path.startsWith("/home/")) return;

    _write(_userKey("path"), path);
  }

  // ───────────────────────────── active business ─────────────────────

  /// The business the account last worked in, to activate it again instead
  /// of the first one `/init` lists.
  String? get lastBusiness => _read<String>(_userKey("business"));

  /// Called by `BusinessService` whenever the active business changes (seed,
  /// switch, create, clear). Scopes [recall]/[remember] to it.
  void useBusiness(String? id) {
    _business = id;
    if (id != null) _write(_userKey("business"), id);
  }

  /// Whether the person answered "not now" to joining the active business's server with its
  /// company online (`HybridService.shouldAskLink`): it is asked once, then only offered from
  /// the server section.
  bool get linkDeclined => _business != null && _read<String>(_userKey("${_business!}/link")) == "declined";

  void declineLink() {
    if (_business != null) _write(_userKey("${_business!}/link"), "declined");
  }

  // ───────────────────────────── selections ─────────────────────────────

  /// What was open for [selection] in the active business, or null.
  String? recall(RememberedSelection selection) {
    final key = _selectionKey(selection);
    return key == null ? null : _read<String>(key);
  }

  /// Stores (or, with null, forgets) what is open for [selection].
  void remember(RememberedSelection selection, String? id) {
    final key = _selectionKey(selection);
    if (key != null) _write(key, id);
  }

  String? _selectionKey(RememberedSelection selection) {
    if (_business == null) return null;
    return _userKey("${_business!}/${selection.name}");
  }

  // ───────────────────────────── storage ─────────────────────────────

  /// `user/<username>/<name>`: the per-account namespace. Null without a
  /// session, which turns reads and writes into no-ops.
  String? _userKey(String name) => _user == null ? null : "user/${_user!}/$name";

  T? _read<T>(String? key) {
    if (!_ready || key == null) return null;
    final value = _database.get<dynamic>(_box, key);
    return value is T ? value : null;
  }

  void _write(String? key, String? value) {
    if (!_ready || key == null) return;
    if (value == null) {
      _database.delete(_box, key);
    } else {
      _database.put<String>(_box, key, value);
    }
  }
}
