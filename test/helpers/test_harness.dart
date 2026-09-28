import 'package:ofsc/core/database/app_database.dart';
import 'package:ofsc/core/database/local_data_source.dart';
import 'package:ofsc/core/network/demo_backend.dart';
import 'package:ofsc/core/network/network_info.dart';
import 'package:ofsc/core/network/remote_data_source.dart';
import 'package:ofsc/core/storage/session_store.dart';
import 'package:ofsc/core/sync/sync_engine.dart';
import 'package:ofsc/core/utils/id_generator.dart';
import 'package:ofsc/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:ofsc/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:ofsc/features/operations/data/repositories/operations_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TestHarness {
  TestHarness() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  late final AppDatabase database;
  late final LocalDataSource local;
  late final ControllableNetworkInfo network;
  late final DemoBackend backend;
  late final RemoteDataSource remote;
  late final TokenManager tokens;
  late final AuthRepositoryImpl auth;
  late final InventoryRepositoryImpl inventory;
  late final OperationsRepositoryImpl operations;
  late final SyncEngine sync;
  late final IdGenerator ids;

  Future<void> setUp() async {
    database = AppDatabase(path: inMemoryDatabasePath);
    local = LocalDataSource(database);
    network = ControllableNetworkInfo();
    backend = DemoBackend();
    remote = RemoteDataSource(
      backend: backend,
      networkInfo: network,
      simulateLatency: Duration.zero,
    );
    tokens = TokenManager(MemoryKeyValueStore());
    ids = IdGenerator();
    auth = AuthRepositoryImpl(
      remote: remote,
      local: local,
      tokens: tokens,
      networkInfo: network,
    );
    inventory = InventoryRepositoryImpl(local);
    operations = OperationsRepositoryImpl(local: local, ids: ids);
    sync = SyncEngine(
      local: local,
      remote: remote,
      networkInfo: network,
    );
  }

  Future<void> tearDown() async {
    await database.close();
    await network.dispose();
    await sync.dispose();
  }
}
