import '../entities/user_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login({
    required String username,
    required String password,
  });

  Future<AuthSession?> restoreSession();

  Future<void> logout();

  Future<UserProfile?> currentUser();
}
