import 'dart:convert';

// SERVICES
import 'package:app/services/database/database_service.dart';
import './lan_device.dart';

/// Where this install keeps its [LanDevice] and its session's refresh token. A seam, so the
/// LAN services' tests run without the OS key store.
abstract interface class LanIdentityStore {
  Future<LanDevice?> device();

  Future<void> saveDevice(LanDevice device);

  /// The refresh token of the signed-in session (`session.md` S-21), rotated on every use.
  Future<String?> refreshToken();

  Future<void> saveRefreshToken(String? token);

  /// Forgets the pairing and the session (a revoked device, leaving LAN mode).
  Future<void> clear();
}

/// [LanIdentityStore] over the OS key store (`flutter_secure_storage`: DPAPI, Keychain,
/// Keystore, libsecret).
class SecureLanIdentityStore implements LanIdentityStore {
  const SecureLanIdentityStore();

  static const _device = "lan.device";
  static const _refresh = "lan.refresh";

  DatabaseService get _db => DatabaseService();

  @override
  Future<LanDevice?> device() async {
    final text = await _db.fromSecure<String>(_device);
    if (text == null) return null;

    try {
      return LanDevice.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } on Object {
      // Written by another version and unreadable: the device pairs again.
      return null;
    }
  }

  @override
  Future<void> saveDevice(LanDevice device) => _db.toSecure(_device, jsonEncode(device.toJson()));

  @override
  Future<String?> refreshToken() => _db.fromSecure<String>(_refresh);

  @override
  Future<void> saveRefreshToken(String? token) =>
    token == null ? _db.deleteSecure(_refresh) : _db.toSecure(_refresh, token);

  @override
  Future<void> clear() async {
    await _db.deleteSecure(_device);
    await _db.deleteSecure(_refresh);
  }
}

/// [LanIdentityStore] in memory, for tests.
class MemoryLanIdentityStore implements LanIdentityStore {
  LanDevice? stored;
  String? refresh;

  @override
  Future<LanDevice?> device() async => stored;

  @override
  Future<void> saveDevice(LanDevice device) async => stored = device;

  @override
  Future<String?> refreshToken() async => refresh;

  @override
  Future<void> saveRefreshToken(String? token) async => refresh = token;

  @override
  Future<void> clear() async {
    stored = null;
    refresh = null;
  }
}
