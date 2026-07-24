// PACKAGES
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

  // Cache de referencias a boxes abiertos — evita llamar Hive.box<T>() en
  // boxes ya abiertos, lo que lanza HiveError por mismatch de tipo genérico.
  final Map<String, Box<dynamic>> _boxes = {};

  // ───────────────────────────── lifecycle ─────────────────────────────

  /// Call once at app startup, before accessing any box.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await Hive.initFlutter();
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
  }

  // ─────────────────────────── box access ──────────────────────────────

  Future<Box<dynamic>> _box(String name) async {
    if (_boxes.containsKey(name)) return _boxes[name]!;
    final box = await Hive.openBox<dynamic>(name);
    _boxes[name] = box;
    return box;
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
  Future<void> openBox(String boxName) async => _box(boxName);

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
