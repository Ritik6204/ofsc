import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/consumption/presentation/bloc/consumption_bloc.dart';
import '../../features/consumption/presentation/pages/consumption_pages.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dispatch/presentation/bloc/dispatch_bloc.dart';
import '../../features/dispatch/presentation/pages/dispatch_pages.dart';
import '../../features/inventory/presentation/bloc/inventory_bloc.dart';
import '../../features/inventory/presentation/pages/inventory_page.dart';
import '../../features/inventory/presentation/pages/material_detail_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/receiving/presentation/bloc/receiving_bloc.dart';
import '../../features/receiving/presentation/pages/receiving_pages.dart';
import '../../features/shell/presentation/pages/app_shell.dart';
import '../../features/sync/presentation/pages/sync_page.dart';
import '../utils/id_generator.dart';
import '../../app/di.dart';

GoRouter createRouter() {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(),
    redirect: (context, state) {
      final auth = sl<AuthBloc>().state;
      final loggingIn = state.matchedLocation == '/login';
      final splashing = state.matchedLocation == '/splash';
      if (auth.status == AuthStatus.unknown ||
          auth.status == AuthStatus.restoring) {
        return splashing ? null : '/splash';
      }
      if (!auth.isAuthenticated) {
        return loggingIn ? null : '/login';
      }
      if (loggingIn || splashing) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/sync', builder: (_, _) => const SyncPage()),
      GoRoute(
        path: '/inventory/:id',
        builder: (context, state) {
          final user = sl<AuthBloc>().state.user!;
          return BlocProvider(
            create: (_) => MaterialDetailCubit(
              user: user,
              repository: sl(),
              materialId: int.parse(state.pathParameters['id']!),
            )..load(),
            child: const MaterialDetailPage(),
          );
        },
      ),
      GoRoute(
        path: '/dispatches/:id',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => DispatchWorkflowCubit(
              repository: sl(),
              ids: sl(),
              requestId: state.pathParameters['id']!,
            )..load(),
            child: const DispatchDetailPage(),
          );
        },
        routes: [
          GoRoute(
            path: 'verify',
            builder: (context, state) {
              return BlocProvider(
                create: (_) => DispatchWorkflowCubit(
                  repository: sl(),
                  ids: sl(),
                  requestId: state.pathParameters['id']!,
                )..load(),
                child: const DispatchDetailPage(verify: true),
              );
            },
          ),
          GoRoute(
            path: 'confirm',
            builder: (context, state) {
              return BlocProvider(
                create: (_) => DispatchWorkflowCubit(
                  repository: sl(),
                  ids: sl(),
                  requestId: state.pathParameters['id']!,
                )..load(),
                child: const DispatchConfirmPage(),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/incoming/:id',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => ReceivingWorkflowCubit(
              repository: sl(),
              ids: sl(),
              requestId: state.pathParameters['id']!,
            )..load(),
            child: const ReceivingPage(),
          );
        },
      ),
      GoRoute(
        path: '/consumption/history',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => ConsumptionBloc(sl())..load(),
            child: const ConsumptionHistoryPage(),
          );
        },
      ),
      GoRoute(
        path: '/consumption/new',
        builder: (context, state) {
          final user = sl<AuthBloc>().state.user!;
          return BlocProvider(
            create: (_) => ConsumptionFormCubit(
              user: user,
              inventoryRepository: sl(),
              operationsRepository: sl(),
              ids: sl<IdGenerator>(),
            )..load(),
            child: const ConsumptionFormPage(),
          );
        },
      ),
      GoRoute(
        path: '/requirements/new',
        builder: (context, state) {
          final user = sl<AuthBloc>().state.user!;
          final materialId = int.tryParse(
            state.uri.queryParameters['materialId'] ?? '',
          );
          return BlocProvider(
            create: (_) => RequirementFormCubit(
              user: user,
              inventoryRepository: sl(),
              operationsRepository: sl(),
              ids: sl<IdGenerator>(),
            )..load(materialId: materialId),
            child: const RequirementFormPage(),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final user = sl<AuthBloc>().state.user!;
          return AppShell(user: user, navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) {
                  final user = sl<AuthBloc>().state.user!;
                  return BlocProvider(
                    create: (_) => DashboardBloc(
                      user: user,
                      inventoryRepository: sl(),
                      operationsRepository: sl(),
                    )..load(),
                    child: DashboardPage(user: user),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tab-two',
                builder: (context, state) {
                  final user = sl<AuthBloc>().state.user!;
                  if (user.isStoreManager) {
                    return BlocProvider(
                      create: (_) =>
                          InventoryBloc(user: user, repository: sl())..load(),
                      child: const InventoryPage(),
                    );
                  }
                  return BlocProvider(
                    create: (_) => DispatchBloc(sl())..load(),
                    child: const IncomingListPage(),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tab-three',
                builder: (context, state) {
                  final user = sl<AuthBloc>().state.user!;
                  if (user.isStoreManager) {
                    return BlocProvider(
                      create: (_) => DispatchBloc(sl())..load(),
                      child: const DispatchListPage(),
                    );
                  }
                  return BlocProvider(
                    create: (_) => InventoryBloc(
                      user: user,
                      repository: sl(),
                      scopeType: 'site',
                    )..load(),
                    child: const InventoryPage(title: 'Site Inventory'),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tab-four',
                builder: (_, _) => const NotificationsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tab-five',
                builder: (context, state) {
                  final user = sl<AuthBloc>().state.user!;
                  return ProfilePage(user: user);
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream() {
    sl<AuthBloc>().stream.listen((_) => notifyListeners());
  }
}
