import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/authentication/domain/entities/user_session.dart';
import '../constants/app_constants.dart';

abstract class KeyValueStore {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

class SecureKeyValueStore implements KeyValueStore {
  SecureKeyValueStore(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> delete(String key) async => values.remove(key);
}

class TokenManager {
  TokenManager(this._store);

  final KeyValueStore _store;

  Future<void> saveSession(AuthSession session) async {
    await _store.write(StorageKeys.accessToken, session.tokens.accessToken);
    await _store.write(StorageKeys.refreshToken, session.tokens.refreshToken);
    await _store.write(
      StorageKeys.tokenExpiry,
      session.tokens.expiresAt.toIso8601String(),
    );
    await _store.write(StorageKeys.cachedUser, jsonEncode(session.user.toMap()));
  }

  Future<AuthSession?> restoreSession() async {
    final token = await _store.read(StorageKeys.accessToken);
    final refresh = await _store.read(StorageKeys.refreshToken);
    final expiry = await _store.read(StorageKeys.tokenExpiry);
    final userJson = await _store.read(StorageKeys.cachedUser);
    if (token == null || refresh == null || expiry == null || userJson == null) {
      return null;
    }
    final tokens = AuthTokens(
      accessToken: token,
      refreshToken: refresh,
      expiresAt: DateTime.parse(expiry),
    );
    if (tokens.isExpired) {
      await clear();
      return null;
    }
    return AuthSession(
      user: UserProfile.fromMap(jsonDecode(userJson) as Map<String, dynamic>),
      tokens: tokens,
    );
  }

  Future<String?> get accessToken => _store.read(StorageKeys.accessToken);

  Future<void> clear() async {
    await _store.delete(StorageKeys.accessToken);
    await _store.delete(StorageKeys.refreshToken);
    await _store.delete(StorageKeys.tokenExpiry);
    await _store.delete(StorageKeys.cachedUser);
  }
}
