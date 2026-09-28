import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ofsc/core/constants/app_constants.dart';
import 'package:ofsc/core/security/user_role.dart';
import 'package:ofsc/features/authentication/presentation/bloc/auth_bloc.dart';

import '../../helpers/test_harness.dart';

void main() {
  late TestHarness harness;

  setUp(() async {
    harness = TestHarness();
    await harness.setUp();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  blocTest<AuthBloc, AuthState>(
    'emits unauthenticated when no session exists',
    build: () => AuthBloc(harness.auth),
    act: (bloc) => bloc.add(const AuthStarted()),
    wait: const Duration(milliseconds: 20),
    expect: () => [
      isA<AuthState>().having(
        (s) => s.status,
        'status',
        AuthStatus.restoring,
      ),
      isA<AuthState>().having(
        (s) => s.status,
        'status',
        AuthStatus.unauthenticated,
      ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'authenticates a store manager and exposes role permissions',
    build: () => AuthBloc(harness.auth),
    act: (bloc) => bloc.add(
      const AuthLoginRequested(
        username: AppConstants.demoStoreUsername,
        password: AppConstants.demoStorePassword,
      ),
    ),
    wait: const Duration(milliseconds: 400),
    expect: () => [
      isA<AuthState>().having(
        (s) => s.status,
        'status',
        AuthStatus.authenticating,
      ),
      isA<AuthState>()
          .having((s) => s.isAuthenticated, 'authenticated', true)
          .having((s) => s.user!.role, 'role', UserRole.storeManager)
          .having((s) => s.user!.can(AppPermission.processDispatch), 'can dispatch', true)
          .having(
            (s) => s.user!.can(AppPermission.recordConsumption),
            'cannot consume',
            false,
          ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'fails login with a human-readable error',
    build: () => AuthBloc(harness.auth),
    act: (bloc) => bloc.add(
      const AuthLoginRequested(username: 'unknown', password: 'bad'),
    ),
    wait: const Duration(milliseconds: 50),
    expect: () => [
      isA<AuthState>().having(
        (s) => s.status,
        'status',
        AuthStatus.authenticating,
      ),
      isA<AuthState>()
          .having((s) => s.status, 'status', AuthStatus.unauthenticated)
          .having((s) => s.errorMessage, 'message', isNotNull),
    ],
  );
}
