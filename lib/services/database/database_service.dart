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

  // Cache de referencias a boxes abiertos — evita llamar Hive.box<T>() en
  // boxes ya abiertos, lo que lanza HiveError por mismatch de tipo genérico.
  final Map<String, Box<dynamic>> _boxes = {};

  // ───────────────────────────── lifecycle ─────────────────────────────

  /// Call once at app startup, before accessing any box.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    // Subcarpeta propia: `initFlutter()` sin nombre deja los `.hive` sueltos en
    // la carpeta de documentos del usuario, donde chocan con los de cualquier
    // otra app que abra un box con el mismo nombre.
    await Hive.initFlutter('lyra');
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
  }

  // ─────────────────────────── box access ──────────────────────────────

  // Aperturas en vuelo. Dos llamadas seguidas al mismo box —el side bar y una
  // seccion pidiendolo a la vez, por ejemplo— tienen que esperar la misma
  // apertura en vez de lanzar dos contra el mismo archivo.
  final Map<String, Future<Box<dynamic>>> _opening = {};

  Future<Box<dynamic>> _box(String name) {
    final opened = _boxes[name];
    if (opened != null) return Future<Box<dynamic>>.value(opened);
    // El callback tiene cuerpo de bloque a proposito: con `=>` devolveria lo
    // que saca `remove`, que es este mismo future, y `whenComplete` esperaria
    // a que termine el future que esta completando —la apertura no volveria
    // nunca aunque el box ya estuviera abierto.
    return _opening[name] ??= _open(name).whenComplete(() {
      _opening.remove(name);
    });
  }

  /// Abre [name] reintentando mientras el lock siga tomado.
  ///
  /// En escritorio Hive bloquea un `.lock` por box, asi que dos instancias de
  /// la app no pueden tener el mismo box abierto. El caso normal es relanzar
  /// encima de la corrida anterior: la que se esta cerrando suelta el lock unos
  /// milisegundos despues, y sin reintento la nueva se cae en el arranque.
  ///
  /// Si el lock no se libera es porque hay otra instancia viva de verdad; ahi
  /// no hay nada que hacer desde el codigo y el error se propaga.
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
  /// No propaga el error a proposito: esto corre en `preCall`, antes de
  /// `runApp`, y una excepcion ahi deja la app sin arrancar. Un box que no se
  /// pudo abrir degrada lo que dependa de el —los lectores sincronos ven su
  /// default— pero la app levanta igual.
  Future<void> openBox(String boxName) async {
    try {
      await _box(boxName);
    } catch (error) {
      debugPrint('DatabaseService: no se pudo abrir el box "$boxName" ($error)');
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
