import '../../../../core/database/local_data_source.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/remote_data_source.dart';
import '../../../../core/storage/session_store.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required RemoteDataSource remote,
    required LocalDataSource local,
    required TokenManager tokens,
    required NetworkInfo networkInfo,
  }) : _remote = remote,
       _local = local,
       _tokens = tokens,
       _networkInfo = networkInfo;

  final RemoteDataSource _remote;
  final LocalDataSource _local;
  final TokenManager _tokens;
  final NetworkInfo _networkInfo;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw const ApiException(
        'Internet is required for the first sign-in.',
        code: 'offline',
      );
    }
    final session = await _remote.login(username, password);
    await _tokens.saveSession(session);
    await _hydrate(session);
    return session;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final cached = await _tokens.restoreSession();
    if (cached == null) return null;
    if (await _networkInfo.isConnected) {
      try {
        await _hydrate(cached);
      } catch (_) {
        // Keep the cached session so field users can continue offline.
      }
    }
    return cached;
  }

  @override
  Future<void> logout() async {
    await _tokens.clear();
    await _local.clearAll();
  }

  @override
  Future<UserProfile?> currentUser() => _local.getCachedUser();

  Future<void> _hydrate(AuthSession session) async {
    final token = session.tokens.accessToken;
    final payload = await _remote.bootstrap(token);
    await _local.replaceBootstrap(
      user: payload.user,
      materials: payload.materials,
      inventory: payload.inventory,
      dispatches: payload.dispatches,
      movements: payload.movements,
      activities: payload.activities,
      consumptions: payload.consumptions,
      requirements: payload.requirements,
      notifications: payload.notifications,
    );
    await _local.setMetadata('last_synced_at', DateTime.now().toIso8601String());
  }
}
