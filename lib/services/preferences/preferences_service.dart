import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/database/database_service.dart';

/// What is open inside a section without being in the URL: the section keeps
/// it as state (see the messages desk), so the route
/// alone cannot bring it back.
enum RememberedSelection {
  /// The open conversation of the messages desk (`ChatsService.selected`).
  chat,

  /// The product table open in the inventory section (its header's selector).
  table,

  /// The made products' table open in the menu section.
  menu,

  /// The branch the person works in (`BranchService`, the header's branch selector).
  branch
}

/// How the inventory section shows the open table: the stock summary (photo, the
/// columns chosen for it and the stock numbers) or every cell of it as a sheet.
enum InventoryView { summary, sheet }

/// The user's preferences, persisted on the device (Hive box `preferences`),
/// so the app opens as it was left.
///
/// Two kinds, stored under different keys on purpose:
/// - **Device-wide**: theme and language. They are about the machine, not the
///   account, and are applied before `runApp` (see [preload]) so the first
///   frame is already painted with them — at the login too.
/// - **Per account**: the last home page (and of each section), the active business and what was
///   open inside a section. Keyed by username, because two people signing in
///   on the same desktop must each land where *they* left; a selection is also
///   keyed by business, since a chat or a table id means nothing in
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

    // The delegate and not `Navis.currentKey`: the key changes before the
    // history does (reading `currentPath` there gives the page being left),
    // and it stays the same between two ids of one route (`/home/business/:id`).
    Navis.delegate.addListener(_screenChanged);
  }

  /// Binds the per-account preferences to [username]; null on sign out.
  /// Called by `ClientService` as soon as `/init` names the account, before
  /// the businesses are seeded (they read [lastBusiness]).
  void bindUser(String? username) {
    _user = (username == null || username.isEmpty) ? null : username;
    if (_user == null) _business = null;
    _recorded = null;

    _inventoryView.value = _storedInventoryView;
  }

  // ───────────────────────────── theme and language ─────────────────────

  ThemeMode get theme => AppController().theme.value ?? ThemeMode.system;

  set theme(ThemeMode value) => AppController().theme.value = value;

  /// Null follows the system.
  Locale? get locale => AppController().locale.value;

  set locale(Locale? value) => AppController().locale.value = value;

  // ───────────────────────────── last page ─────────────────────────────

  /// The home page the account was on when the app closed, URL args
  /// included (`/home/business/:id/clients`), or null if none was recorded.
  String? get lastPath => _read<String>(_userKey("path"));

  /// Where to land after the session resolves when no deep link asks for
  /// something else.
  String get homePath => lastPath ?? "/home";

  /// Only home pages are recorded: the login, the pre-start pages and the POS
  /// are not places to come back to on their own. A page that no longer
  /// exists (a deleted table) is handled by the page itself, as a deep link
  /// would be.
  ///
  /// Each page is also recorded as the last one of its section ([lastPathIn]).
  void _screenChanged() {
    if (_user == null) return;

    final path = Navis.currentPath;
    if (path == _recorded) return;
    if (path != "/home" && !path.startsWith("/home/")) return;

    _recorded = path;
    _write(_userKey("path"), path);

    final route = Navis().match(path)?.route;
    if (route != null) _write(_sectionKey(route.parents.isEmpty ? route.key : route.parents.first), path);
  }

  /// The last path written, so the delegate's notifications that change no
  /// page (a pop over a modal route) do not write again.
  String? _recorded;

  /// The page of the home section [section] (its route key) that was open
  /// last in the active business, tab or sub-page included
  /// (`/home/finance/payments`), or null if none was or its route no longer
  /// exists. Per business: the path may carry its ids (a table, a person).
  String? lastPathIn(String section) {
    final path = _read<String>(_sectionKey(section));
    return path != null && Navis().match(path) != null ? path : null;
  }

  String? _sectionKey(String section) =>
    _business == null ? null : _userKey("${_business!}/section/$section");

  // ───────────────────────────── active business ─────────────────────

  /// The business the account last worked in, to activate it again instead
  /// of the first one `/init` lists.
  String? get lastBusiness => _read<String>(_userKey("business"));

  /// Called by `BusinessService` whenever the active business changes (seed,
  /// switch, create, clear). Scopes [recall]/[remember] to it.
  void useBusiness(String? id) {
    _business = id;
    _recorded = null;
    if (id != null) _write(_userKey("business"), id);
  }

  /// Whether the person answered "not now" to joining the active business's server with its
  /// company online (`HybridService.shouldAskLink`): it is asked once, then only offered from
  /// the server section.
  bool get linkDeclined => _business != null && _read<String>(_userKey("${_business!}/link")) == "declined";

  void declineLink() {
    if (_business != null) _write(_userKey("${_business!}/link"), "declined");
  }

  // ───────────────────────────── inventory view ─────────────────────

  final _inventoryView = ValueNotifier<InventoryView>(InventoryView.summary);

  /// Whether the account reads its tables as the stock summary or as the sheet. Per account
  /// and not per business: it is how this person likes to work, whatever the company. A
  /// listenable because it is switched from two places (the inventory header and one's own
  /// preferences) and both draw it.
  ValueListenable<InventoryView> get inventoryView => _inventoryView;

  void useInventoryView(InventoryView view) {
    _inventoryView.value = view;
    _write(_userKey("inventory_view"), view.name);
  }

  InventoryView get _storedInventoryView =>
    InventoryView.values.asNameMap()[_read<String>(_userKey("inventory_view"))] ?? InventoryView.summary;

  // ───────────────────────────── master passwords ─────────────────────

  /// Whether [login] signed in to the master [instance] with a password from this device. A
  /// computer with a master is shared by accounts of other companies, and by its own people who
  /// never made a password there: asking them for one after an online sign in reads as a password
  /// they never created (`HybridService.join`). Device-wide: the master is this device's, not an
  /// account's; keyed by instance so a master set up again starts empty.
  bool hasMasterPassword(String instance, String login) => _read<String>(_masterKey(instance, login)) != null;

  void rememberMasterPassword(String instance, String login) => _write(_masterKey(instance, login), "password");

  String _masterKey(String instance, String login) => "master/$instance/${login.trim().toLowerCase()}";

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
