import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../core/connectivity/connectivity_cubit.dart';
import '../core/database/app_database.dart';
import '../core/database/local_data_source.dart';
import '../core/network/demo_backend.dart';
import '../core/network/network_info.dart';
import '../core/network/api_client.dart';
import '../core/network/remote_data_source.dart';
import '../core/storage/session_store.dart';
import '../core/sync/sync_engine.dart';
import '../core/utils/id_generator.dart';
import '../features/authentication/data/repositories/auth_repository_impl.dart';
import '../features/authentication/domain/repositories/auth_repository.dart';
import '../features/authentication/presentation/bloc/auth_bloc.dart';
import '../features/inventory/data/repositories/inventory_repository_impl.dart';
import '../features/inventory/domain/repositories/inventory_repository.dart';
import '../features/notifications/presentation/bloc/notification_bloc.dart';
import '../features/operations/data/repositories/operations_repository_impl.dart';
import '../features/operations/domain/repositories/operations_repository.dart';

final sl = GetIt.instance;

Future<void> configureDependencies({
  AppDatabase? database,
  NetworkInfo? networkInfo,
  KeyValueStore? store,
  DemoBackend? backend,
}) async {
  if (sl.isRegistered<AuthBloc>()) {
    return;
  }

  sl.registerLazySingleton<AppDatabase>(() => database ?? AppDatabase());
  sl.registerLazySingleton(() => LocalDataSource(sl()));
  sl.registerLazySingleton<NetworkInfo>(
    () => networkInfo ?? NetworkInfoImpl(Connectivity()),
  );
  sl.registerLazySingleton<KeyValueStore>(
    () => store ?? SecureKeyValueStore(const FlutterSecureStorage()),
  );
  sl.registerLazySingleton(() => TokenManager(sl()));
  sl.registerLazySingleton(() => backend ?? DemoBackend());
  sl.registerLazySingleton(
    () => ApiClient(tokens: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(
    () => RemoteDataSource(backend: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => IdGenerator());
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl(),
      local: sl(),
      tokens: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<InventoryRepository>(
    () => InventoryRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<OperationsRepository>(
    () => OperationsRepositoryImpl(local: sl(), ids: sl()),
  );
  sl.registerLazySingleton(
    () => SyncEngine(
      local: sl(),
      remote: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton(() => AuthBloc(sl())..add(const AuthStarted()));
  sl.registerLazySingleton(
    () => ConnectivityCubit(networkInfo: sl(), syncEngine: sl()),
  );
  sl.registerLazySingleton(() => NotificationBloc(sl()));
}

Future<void> resetDependencies() async {
  await sl.reset();
}
