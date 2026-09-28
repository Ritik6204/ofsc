import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/authentication/presentation/bloc/auth_bloc.dart';
import '../features/notifications/presentation/bloc/notification_bloc.dart';
import '../features/operations/domain/repositories/operations_repository.dart';
import '../core/connectivity/connectivity_cubit.dart';
import 'di.dart';

class OfscApp extends StatefulWidget {
  const OfscApp({super.key});

  @override
  State<OfscApp> createState() => _OfscAppState();
}

class _OfscAppState extends State<OfscApp> {
  late final _router = createRouter();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<AuthBloc>()),
        BlocProvider.value(value: sl<ConnectivityCubit>()),
        BlocProvider.value(value: sl<NotificationBloc>()),
        RepositoryProvider<OperationsRepository>.value(value: sl()),
      ],
      child: MaterialApp.router(
        title: 'OFSC Inventory',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
