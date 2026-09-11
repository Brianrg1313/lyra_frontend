// PACKAGES
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Singleton that centralises every Hive interaction.
///
/// Usage:
///   await DatabaseService.instance.initialize();
///   await DatabaseService.instance.put('subscriptions_card', 'key', value);
///   final value = DatabaseService.instance.get<Map>('subscriptions_card', 'key');
///   await DatabaseService.instance.delete('subscriptions_card', 'key');
class DatabaseService {
  //SINGLETON
  static final DatabaseService _singleton = DatabaseService._internal();
  factory DatabaseService() => _singleton;
  DatabaseService._internal();

  bool _initialized = false;

  late final FlutterSecureStorage _secureStorage;

  // Cache of references to open boxes — avoids calling Hive.box<T>() on
  // already-open boxes, which throws HiveError due to a generic type mismatch.
  final Map<String, Box<dynamic>> _boxes = {};

  // ───────────────────────────── lifecycle ─────────────────────────────

  /// Call once at app startup, before accessing any box.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    // Own subfolder: `initFlutter()` without a name leaves the `.hive` files loose in
    // the user's documents folder, where they clash with those of any
    // other app that opens a box with the same name.
    await Hive.initFlutter('lyra');
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
  }

  // ─────────────────────────── box access ──────────────────────────────

  // In-flight openings. Two consecutive calls to the same box —the side bar and a
  // section asking for it at the same time, for example— have to wait for the same
  // opening instead of launching two against the same file.
  final Map<String, Future<Box<dynamic>>> _opening = {};

  Future<Box<dynamic>> _box(String name) {
    final opened = _boxes[name];
    if (opened != null) return Future<Box<dynamic>>.value(opened);
    // The callback has a block body on purpose: with `=>` it would return what
    // `remove` returns, which is this same future, and `whenComplete` would wait
    // for the future that it is completing to finish —the opening would never
    // return even if the box was already open.
    return _opening[name] ??= _open(name).whenComplete(() {
      _opening.remove(name);
    });
  }

  /// Opens [name] retrying while the lock remains held.
  ///
  /// On desktop Hive locks a `.lock` per box, so two instances of
  /// the app cannot have the same box open. The normal case is relaunching
  /// over the previous run: the one that is closing releases the lock a few
  /// milliseconds later, and without a retry the new one crashes on startup.
  ///
  /// If the lock is not released it is because there is really another live instance; there
  /// is nothing to do from the code there and the error propagates.
  Future<Box<dynamic>> _open(String name) async {
    const maxAttempts = 5;
    for (var attempt = 1;; attempt++) {
      try {
        final box = await Hive.openBox<dynamic>(name);
        _boxes[name] = box;
        return box;
      } catch (_) {
        if (attempt == maxAttempts) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 150 * attempt));
      }
    }
  }

  // ──────────────────────────────── CRUD ───────────────────────────────

  /// Insert or replace [value] under [key] in [boxName].
  Future<void> put<T>(String boxName, String key, T value) async {
    final box = await _box(boxName);
    await box.put(key, value);
  }

  /// Insert or replace several entries at once.
  Future<void> putAll<T>(String boxName, Map<String, T> entries) async {
    final box = await _box(boxName);
    await box.putAll(entries);
  }

  /// Read a single entry. Returns null when not found.
  T? get<T>(String boxName, String key) {
    return _boxes[boxName]?.get(key) as T?;
  }

  /// Read all values stored in [boxName].
  List<T> getAll<T>(String boxName) {
    final box = _boxes[boxName];
    if (box == null) return [];
    return box.values.cast<T>().toList();
  }

  /// Read all entries as a key→value map.
  Map<String, T> getMap<T>(String boxName) {
    final box = _boxes[boxName];
    if (box == null) return {};
    return {for (final k in box.keys.cast<String>()) k: box.get(k) as T};
  }

  /// Like [getMap] but opens the box first if it isn't cached yet.
  Future<Map<String, T>> getMapAsync<T>(String boxName) async {
    final box = await _box(boxName);
    return {for (final k in box.keys.cast<String>()) k: box.get(k) as T};
  }

  /// Delete a single entry by [key].
  Future<void> delete(String boxName, String key) async {
    await _boxes[boxName]?.delete(key);
  }

  /// Delete all entries in [boxName].
  Future<void> clear(String boxName) async {
    await _boxes[boxName]?.clear();
  }

  // ─────────────────────────── box lifecycle ───────────────────────────

  /// Open [boxName] explicitly (optional — put/get open it automatically).
  ///
  /// It does not propagate the error on purpose: this runs in `preCall`, before
  /// `runApp`, and an exception there leaves the app unable to start. A box that could not
  /// be opened degrades whatever depends on it —the synchronous readers see their
  /// default— but the app still comes up.
  Future<void> openBox(String boxName) async {
    try {
      await _box(boxName);
    } catch (error) {
      debugPrint('DatabaseService: could not open the box "$boxName" ($error)');
    }
  }

  /// Close [boxName] to free memory when it is no longer needed.
  Future<void> closeBox(String boxName) async {
    final box = _boxes.remove(boxName);
    await box?.close();
  }

  Future<T?> fromSecure<T>(String key) async {
    final value = await _secureStorage.read(key: key);
    if (value == null) return null;
    if (T == String) return value as T;
    if (T == int) return int.tryParse(value) as T?;
    if (T == double) return double.tryParse(value) as T?;
    if (T == bool) return (value == 'true') as T;
    return value as T?;
  }

  Future<void> toSecure(String key, dynamic value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// Whether [key] exists in the secure storage.
  Future<bool> hasInSecure(String key) async {
    return _secureStorage.containsKey(key: key);
  }

  /// Deletes [key] from the secure storage.
  Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  /// Whether [key] exists in [boxName]. Opens the box first if needed.
  Future<bool> hasInBox(String boxName, String key) async {
    final box = await _box(boxName);
    return box.containsKey(key);
  }

  /// Close all open boxes and release Hive resources.
  Future<void> dispose() async {
    _boxes.clear();
    await Hive.close();
  }
}
